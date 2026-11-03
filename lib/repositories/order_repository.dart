import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../data/firestore_db.dart';
import '../models/loyalty.dart';
import '../models/order.dart';

// Đọc/ghi collection orders. Mỗi đơn là 1 document, các món nằm trong mảng items.
class OrderRepository {
  OrderRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  // Lấy instance khi dùng: kiểm tra dữ liệu sai thì báo lỗi luôn, không cần Firebase
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(Collections.orders);

  // Lưu đơn hàng + các món trong đơn.
  // Dùng transaction: cấp mã đơn và lưu đơn cùng lúc, lỗi giữa chừng thì không lưu gì.
  Future<int> createOrder(Order order, List<OrderItem> items) async {
    if (items.isEmpty ||
        items.any((item) => item.quantity <= 0 || item.unitPrice < 0)) {
      throw StateError('Danh sách món trong đơn không hợp lệ.');
    }
    final calculatedTotal = items.fold<int>(
      0,
      (total, item) => total + item.totalPrice,
    );
    if (calculatedTotal <= 0 || calculatedTotal != order.subtotal) {
      throw StateError('Tổng tiền và chi tiết đơn hàng không khớp.');
    }
    final expectedDiscount = order.pointsUsed * LoyaltyPolicy.pointValueVnd;
    if (order.pointsUsed < 0 ||
        order.discountAmount != expectedDiscount ||
        order.totalPrice != order.subtotal - order.discountAmount ||
        order.pointsUsed >
            LoyaltyPolicy.maxRedeemablePoints(
              subtotal: order.subtotal,
              balance: order.pointsUsed,
            )) {
      throw StateError('Thông tin đổi điểm không hợp lệ.');
    }
    return _db.runTransaction((txn) async {
      final loyaltyRef = _db
          .collection(Collections.loyaltyAccounts)
          .doc(order.userId);
      DocumentSnapshot<Map<String, dynamic>>? loyaltySnap;
      if (order.pointsUsed > 0) {
        loyaltySnap = await txn.get(loyaltyRef);
        final balance = (loyaltySnap.data()?['balance'] as num?)?.toInt() ?? 0;
        final max = LoyaltyPolicy.maxRedeemablePoints(
          subtotal: order.subtotal,
          balance: balance,
        );
        if (order.pointsUsed > max) {
          throw StateError('Số dư điểm không đủ hoặc vượt mức giảm cho phép.');
        }
      }
      final orderId = await nextId(txn, _db, Collections.orders);
      txn.set(_orders.doc('$orderId'), {
        ...order.toMap(),
        'id': orderId,
        'items': items.map((item) => item.toMap()).toList(),
      });
      if (order.pointsUsed > 0) {
        final old = loyaltySnap!.data();
        final balance = (old?['balance'] as num?)?.toInt() ?? 0;
        txn.set(loyaltyRef, {
          'balance': balance - order.pointsUsed,
          'lifetimeEarned': (old?['lifetimeEarned'] as num?)?.toInt() ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMutationKey': '${orderId}_redeem',
          'lastOrderId': orderId,
          'lastMutationType': 'redeem',
        });
        txn.set(
          loyaltyRef
              .collection(Collections.loyaltyTransactions)
              .doc('${orderId}_redeem'),
          {
            'orderId': orderId,
            'type': LoyaltyTransactionType.redeem.name,
            'points': order.pointsUsed,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      return orderId;
    });
  }

  static List<Order> _toOrders(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => Order.fromMap(d.data())).toList()
        ..sort((a, b) => b.id!.compareTo(a.id!)); // mới nhất lên đầu

  // Đơn hàng của 1 khách. Stream: quán đổi trạng thái thì danh sách tự cập nhật.
  // Sắp xếp ở máy để không phải tạo composite index (userId + id) trên Firestore.
  Stream<List<Order>> watchOrdersByUser(String userId) =>
      _orders.where('userId', isEqualTo: userId).snapshots().map(_toOrders);

  // Tất cả đơn hàng (cho chủ quán): khách đặt đơn mới là hiện ngay
  Stream<List<Order>> watchAllOrders() => _orders.snapshots().map(_toOrders);

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final doc = await _orders.doc('$orderId').get();
    final items = (doc.data()?['items'] as List?) ?? const [];
    return items
        .map((m) => OrderItem.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<Order?> getOrderById(int orderId) async {
    final data = (await _orders.doc('$orderId').get()).data();
    return data == null ? null : Order.fromMap(data);
  }

  // Transaction đọc lại trạng thái hiện tại trước khi ghi: máy khác vừa đổi
  // trạng thái thì báo lỗi thay vì ghi đè (optimistic concurrency control).
  Future<void> updateStatus(
    int orderId,
    OrderStatus newStatus, {
    required OrderStatus expectedStatus,
  }) async {
    if (!expectedStatus.canTransitionTo(newStatus)) {
      throw StateError(
        'Không thể chuyển đơn từ ${expectedStatus.label} sang ${newStatus.label}.',
      );
    }
    await _db.runTransaction((txn) async {
      final ref = _orders.doc('$orderId');
      final snap = await txn.get(ref);
      final data = snap.data();
      if (data?['status'] != expectedStatus.name) {
        throw StateError(
          'Đơn hàng đã thay đổi hoặc không còn tồn tại. Vui lòng tải lại.',
        );
      }
      final userId = data!['userId'] as String;
      final loyaltyRef = _db
          .collection(Collections.loyaltyAccounts)
          .doc(userId);
      final shouldEarn =
          newStatus == OrderStatus.completed && data['loyaltyAwarded'] != true;
      final pointsUsed = (data['pointsUsed'] as num?)?.toInt() ?? 0;
      final shouldRefund =
          newStatus == OrderStatus.cancelled &&
          pointsUsed > 0 &&
          data['pointsRefunded'] != true;
      DocumentSnapshot<Map<String, dynamic>>? accountSnap;
      if (shouldEarn || shouldRefund) accountSnap = await txn.get(loyaltyRef);

      final updates = <String, Object?>{'status': newStatus.name};
      if (shouldEarn) {
        final points = LoyaltyPolicy.pointsEarned(
          (data['totalPrice'] as num).toInt(),
        );
        updates['loyaltyAwarded'] = true;
        if (points > 0) {
          final account = accountSnap!.data();
          final balance = (account?['balance'] as num?)?.toInt() ?? 0;
          final lifetime = (account?['lifetimeEarned'] as num?)?.toInt() ?? 0;
          txn.set(loyaltyRef, {
            'balance': balance + points,
            'lifetimeEarned': lifetime + points,
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMutationKey': '${orderId}_earn',
            'lastOrderId': orderId,
            'lastMutationType': 'earn',
          });
          txn.set(
            loyaltyRef
                .collection(Collections.loyaltyTransactions)
                .doc('${orderId}_earn'),
            {
              'orderId': orderId,
              'type': LoyaltyTransactionType.earn.name,
              'points': points,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      if (shouldRefund) {
        final account = accountSnap!.data();
        final balance = (account?['balance'] as num?)?.toInt() ?? 0;
        updates['pointsRefunded'] = true;
        txn.set(loyaltyRef, {
          'balance': balance + pointsUsed,
          'lifetimeEarned': (account?['lifetimeEarned'] as num?)?.toInt() ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMutationKey': '${orderId}_refund',
          'lastOrderId': orderId,
          'lastMutationType': 'refund',
        });
        txn.set(
          loyaltyRef
              .collection(Collections.loyaltyTransactions)
              .doc('${orderId}_refund'),
          {
            'orderId': orderId,
            'type': LoyaltyTransactionType.refund.name,
            'points': pointsUsed,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
      txn.update(ref, updates);
    });
  }
}

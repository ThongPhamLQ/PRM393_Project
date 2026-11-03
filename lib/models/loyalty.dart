import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';

class LoyaltyPolicy {
  static const earnUnitVnd = 10000;
  static const pointValueVnd = 1000;
  static const maxDiscountPercent = 20;

  static int pointsEarned(int totalPrice) =>
      totalPrice <= 0 ? 0 : totalPrice ~/ earnUnitVnd;

  static int maxRedeemablePoints({
    required int subtotal,
    required int balance,
  }) {
    if (subtotal <= 0 || balance <= 0) return 0;
    final cap = (subtotal * maxDiscountPercent ~/ 100) ~/ pointValueVnd;
    return balance < cap ? balance : cap;
  }

  static LoyaltyQuote quote({
    required int subtotal,
    required int balance,
    required int requestedPoints,
  }) {
    if (subtotal <= 0 || balance < 0 || requestedPoints < 0) {
      throw StateError('Dữ liệu đổi điểm không hợp lệ.');
    }
    final max = maxRedeemablePoints(subtotal: subtotal, balance: balance);
    if (requestedPoints > max) {
      throw StateError('Số điểm sử dụng vượt quá giới hạn.');
    }
    final discount = requestedPoints * pointValueVnd;
    return LoyaltyQuote(
      subtotal: subtotal,
      pointsUsed: requestedPoints,
      discountAmount: discount,
      totalPrice: subtotal - discount,
    );
  }
}

class LoyaltyQuote {
  const LoyaltyQuote({
    required this.subtotal,
    required this.pointsUsed,
    required this.discountAmount,
    required this.totalPrice,
  });

  final int subtotal;
  final int pointsUsed;
  final int discountAmount;
  final int totalPrice;
}

class LoyaltyAccount {
  const LoyaltyAccount({
    required this.balance,
    required this.lifetimeEarned,
    this.updatedAt,
  });

  const LoyaltyAccount.empty()
    : balance = 0,
      lifetimeEarned = 0,
      updatedAt = null;

  final int balance;
  final int lifetimeEarned;
  final DateTime? updatedAt;

  factory LoyaltyAccount.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const LoyaltyAccount.empty();
    return LoyaltyAccount(
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (map['lifetimeEarned'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] == null ? null : readDate(map['updatedAt']),
    );
  }
}

enum LoyaltyTransactionType { earn, redeem, refund }

class LoyaltyTransactionEntry {
  const LoyaltyTransactionEntry({
    required this.id,
    required this.orderId,
    required this.type,
    required this.points,
    required this.createdAt,
  });

  final String id;
  final int orderId;
  final LoyaltyTransactionType type;
  final int points;
  final DateTime createdAt;

  factory LoyaltyTransactionEntry.fromMap(
    String id,
    Map<String, dynamic> map,
  ) => LoyaltyTransactionEntry(
    id: id,
    orderId: (map['orderId'] as num).toInt(),
    type: LoyaltyTransactionType.values.byName(map['type'] as String),
    points: (map['points'] as num).toInt(),
    createdAt: readDate(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'type': type.name,
    'points': points,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

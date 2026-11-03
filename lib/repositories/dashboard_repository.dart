import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firestore_db.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  DashboardRepository({FirebaseFirestore? db}) : _dbOverride = db;
  final FirebaseFirestore? _dbOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  // Lọc đơn theo createdAt trong khoảng nửa mở [from, to), giờ địa phương.
  // shortcut: tải mọi đơn trong khoảng rồi cộng ở máy (DashboardStats.fromOrderMaps);
  // khi quán có hàng nghìn đơn thì chuyển sang aggregate query (count/sum) của Firestore.
  Future<DashboardStats> load({DateTime? from, DateTime? to}) async {
    Query<Map<String, dynamic>> query = _db.collection(Collections.orders);
    if (from != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where('createdAt', isLessThan: Timestamp.fromDate(to));
    }
    final snap = await query.get();
    return DashboardStats.fromOrderMaps(snap.docs.map((d) => d.data()));
  }
}

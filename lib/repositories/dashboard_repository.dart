import '../data/database_helper.dart';
import '../models/dashboard_stats.dart';

class DashboardRepository {
  final DatabaseHelper _helper;
  DashboardRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;

  // ISO-8601 datetime text is used by the existing orders.createdAt column.
  // Dates are filtered by a half-open interval [from, to), in local time.
  Future<DashboardStats> load({DateTime? from, DateTime? to}) async {
    final db = await _helper.database;
    final whereParts = <String>[];
    final args = <Object?>[];
    if (from != null) {
      whereParts.add('createdAt >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('createdAt < ?');
      args.add(to.toIso8601String());
    }
    final where = whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS allOrders,
        COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END),0) AS pendingOrders,
        COALESCE(SUM(CASE WHEN status IN ('confirmed','preparing','delivering') THEN 1 ELSE 0 END),0) AS processingOrders,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END),0) AS completedOrders,
        COALESCE(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END),0) AS cancelledOrders,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN totalPrice ELSE 0 END),0) AS revenue,
        COALESCE(SUM(CASE WHEN isPaid = 1 AND status IN ('pending','confirmed','preparing','delivering') THEN totalPrice ELSE 0 END),0) AS paidNotCompleted
      FROM orders $where
    ''', args);
    final r = rows.single;
    int number(String key) => (r[key] as num?)?.toInt() ?? 0;

    final itemsWhere = whereParts.isEmpty
        ? ''
        : 'AND ${whereParts.map((s) => 'o.$s').join(' AND ')}';
    final topRows = await db.rawQuery('''
      SELECT oi.productName AS name, COALESCE(SUM(oi.quantity),0) AS quantity
      FROM order_items oi JOIN orders o ON o.id = oi.orderId
      WHERE o.status = 'completed' $itemsWhere
      GROUP BY oi.productName ORDER BY quantity DESC, oi.productName ASC LIMIT 5
    ''', args);
    return DashboardStats(
      allOrders: number('allOrders'),
      pendingOrders: number('pendingOrders'),
      processingOrders: number('processingOrders'),
      completedOrders: number('completedOrders'),
      cancelledOrders: number('cancelledOrders'),
      revenue: number('revenue'),
      paidNotCompleted: number('paidNotCompleted'),
      topDrinks: topRows
          .map(
            (r) =>
                TopDrink(r['name'] as String, (r['quantity'] as num).toInt()),
          )
          .toList(),
    );
  }
}

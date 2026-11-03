import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/dashboard_stats.dart';

void main() {
  test('Only completed orders recognized as revenue', () {
    for (final status in DashboardKpiRules.recognizedStatuses) {
      expect(DashboardKpiRules.isRevenue(status), status == 'completed');
    }
  });
  test('Paid but not completed is tracked separately', () {
    expect(DashboardKpiRules.isPaidAwaitingCompletion('pending', true), true);
    expect(
      DashboardKpiRules.isPaidAwaitingCompletion('completed', true),
      false,
    );
    expect(
      DashboardKpiRules.isPaidAwaitingCompletion('cancelled', true),
      false,
    );
    expect(
      DashboardKpiRules.isPaidAwaitingCompletion('confirmed', false),
      false,
    );
  });
  test('KPIs are summed from Firestore order documents', () {
    Map<String, dynamic> order(String status, int total, {bool paid = false}) =>
        {
          'status': status,
          'totalPrice': total,
          'isPaid': paid,
          'items': [
            {'productName': 'Bạc xỉu', 'quantity': 2},
            {'productName': 'Trà vải', 'quantity': 1},
          ],
        };
    final s = DashboardStats.fromOrderMaps([
      order('completed', 100000),
      order('completed', 50000),
      order('pending', 30000, paid: true),
      order('preparing', 20000),
      order('cancelled', 10000),
    ]);
    expect(s.allOrders, 5);
    expect(s.pendingOrders, 1);
    expect(s.processingOrders, 1);
    expect(s.completedOrders, 2);
    expect(s.cancelledOrders, 1);
    expect(s.revenue, 150000);
    expect(s.paidNotCompleted, 30000);
    // Chỉ đếm món của đơn đã hoàn thành: 2 đơn x 2 ly bạc xỉu
    expect(s.topDrinks.first.name, 'Bạc xỉu');
    expect(s.topDrinks.first.quantity, 4);
  });
  test('No divide-by-zero on empty dataset', () {
    const s = DashboardStats(
      allOrders: 0,
      pendingOrders: 0,
      processingOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      revenue: 0,
      paidNotCompleted: 0,
      topDrinks: [],
    );
    expect(s.averageOrderValue, 0);
    expect(s.cancellationRate, 0);
  });
}

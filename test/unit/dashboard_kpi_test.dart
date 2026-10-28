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

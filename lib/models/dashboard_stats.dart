class TopDrink {
  final String name;
  final int quantity;
  const TopDrink(this.name, this.quantity);
}

class DashboardStats {
  final int allOrders;
  final int pendingOrders;
  final int processingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int revenue;
  final int paidNotCompleted;
  final int loyaltyDiscounts;
  final List<TopDrink> topDrinks;

  const DashboardStats({
    required this.allOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.paidNotCompleted,
    this.loyaltyDiscounts = 0,
    required this.topDrinks,
  });

  // Firestore không có SUM / GROUP BY như SQL: đọc các document đơn hàng rồi
  // cộng dồn ở đây. Đồ uống bán chạy lấy từ mảng items của đơn đã hoàn thành.
  factory DashboardStats.fromOrderMaps(Iterable<Map<String, dynamic>> orders) {
    var all = 0, pending = 0, processing = 0, completed = 0, cancelled = 0;
    var revenue = 0, paidNotCompleted = 0, loyaltyDiscounts = 0;
    final drinks = <String, int>{};
    for (final order in orders) {
      final status = order['status'] as String;
      final total = (order['totalPrice'] as num).toInt();
      all++;
      if (status == 'pending') pending++;
      if (status == 'cancelled') cancelled++;
      if (DashboardKpiRules.isProcessing(status)) processing++;
      if (DashboardKpiRules.isPaidAwaitingCompletion(
        status,
        order['isPaid'] == true,
      )) {
        paidNotCompleted += total;
      }
      if (DashboardKpiRules.isRevenue(status)) {
        completed++;
        revenue += total;
        loyaltyDiscounts += (order['discountAmount'] as num?)?.toInt() ?? 0;
        for (final item in (order['items'] as List?) ?? const []) {
          final name = item['productName'] as String;
          drinks[name] =
              (drinks[name] ?? 0) + (item['quantity'] as num).toInt();
        }
      }
    }
    // Bán nhiều xếp trước; bằng nhau thì theo tên A-Z (giống ORDER BY cũ)
    final ranked = drinks.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    return DashboardStats(
      allOrders: all,
      pendingOrders: pending,
      processingOrders: processing,
      completedOrders: completed,
      cancelledOrders: cancelled,
      revenue: revenue,
      paidNotCompleted: paidNotCompleted,
      loyaltyDiscounts: loyaltyDiscounts,
      topDrinks: [for (final e in ranked.take(5)) TopDrink(e.key, e.value)],
    );
  }

  double get averageOrderValue =>
      completedOrders == 0 ? 0 : revenue / completedOrders;
  double get cancellationRate =>
      allOrders == 0 ? 0 : cancelledOrders * 100 / allOrders;
}

class DashboardKpiRules {
  static const recognizedStatuses = {
    'pending',
    'confirmed',
    'preparing',
    'delivering',
    'completed',
    'cancelled',
  };
  static bool isRevenue(String status) => status == 'completed';
  static bool isProcessing(String status) =>
      {'confirmed', 'preparing', 'delivering'}.contains(status);
  static bool isPaidAwaitingCompletion(String status, bool paid) =>
      paid && status != 'completed' && status != 'cancelled';
}

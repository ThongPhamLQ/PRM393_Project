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
  final List<TopDrink> topDrinks;

  const DashboardStats({
    required this.allOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.paidNotCompleted,
    required this.topDrinks,
  });

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

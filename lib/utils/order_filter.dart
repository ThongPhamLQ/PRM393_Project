import '../models/order.dart';
import 'text_search.dart';

enum CustomerOrderGroup { all, processing, completed, cancelled }

List<Order> filterOrders(
  Iterable<Order> orders, {
  String query = '',
  CustomerOrderGroup customerGroup = CustomerOrderGroup.all,
  OrderStatus? status,
  bool includeCustomerDetails = false,
}) {
  final normalizedQuery = query.trim();
  final orderIdQuery = normalizedQuery.startsWith('#')
      ? normalizedQuery.substring(1).trim()
      : normalizedQuery;

  return orders
      .where((order) {
        if (status != null && order.status != status) return false;
        if (!_matchesCustomerGroup(order.status, customerGroup)) return false;
        if (normalizedQuery.isEmpty) return true;

        final matchesId = order.id?.toString() == orderIdQuery;
        if (matchesId) return true;
        if (!includeCustomerDetails) return false;
        return matchesSearch(order.customerName, normalizedQuery) ||
            order.phone.contains(normalizedQuery);
      })
      .toList(growable: false);
}

bool _matchesCustomerGroup(OrderStatus status, CustomerOrderGroup group) =>
    switch (group) {
      CustomerOrderGroup.all => true,
      CustomerOrderGroup.processing => status.isActive,
      CustomerOrderGroup.completed => status == OrderStatus.completed,
      CustomerOrderGroup.cancelled => status == OrderStatus.cancelled,
    };

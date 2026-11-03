import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/utils/order_filter.dart';

void main() {
  final orders = [
    _order(12, OrderStatus.pending, 'Nguyễn Văn An', '0905123456'),
    _order(23, OrderStatus.preparing, 'Trần Bình', '0911222333'),
    _order(34, OrderStatus.completed, 'Lê Minh', '0988777666'),
    _order(45, OrderStatus.cancelled, 'Phạm Hoa', '0909000111'),
  ];

  test('finds an order id with or without a hash prefix', () {
    expect(filterOrders(orders, query: '23').single.id, 23);
    expect(filterOrders(orders, query: '#23').single.id, 23);
  });

  test('admin search matches customer name without Vietnamese accents', () {
    final result = filterOrders(
      orders,
      query: 'nguyen van an',
      includeCustomerDetails: true,
    );
    expect(result.map((o) => o.id), [12]);
  });

  test('admin search matches a customer phone number', () {
    final result = filterOrders(
      orders,
      query: '0911222',
      includeCustomerDetails: true,
    );
    expect(result.map((o) => o.id), [23]);
  });

  test('processing group contains every non-terminal status', () {
    final result = filterOrders(
      orders,
      customerGroup: CustomerOrderGroup.processing,
    );
    expect(result.map((o) => o.id), [12, 23]);
  });

  test('status and query filters are applied together', () {
    final result = filterOrders(
      orders,
      query: '34',
      status: OrderStatus.completed,
    );
    expect(result.map((o) => o.id), [34]);
    expect(
      filterOrders(orders, query: '12', status: OrderStatus.completed),
      isEmpty,
    );
  });

  test('empty query keeps all orders in the selected group', () {
    final result = filterOrders(
      orders,
      query: '  ',
      customerGroup: CustomerOrderGroup.completed,
    );
    expect(result.map((o) => o.id), [34]);
  });
}

Order _order(int id, OrderStatus status, String name, String phone) => Order(
  id: id,
  userId: 'u$id',
  customerName: name,
  phone: phone,
  address: 'Đà Nẵng',
  paymentMethod: PaymentMethod.cash,
  isPaid: false,
  totalPrice: 50000,
  status: status,
  createdAt: DateTime(2026, 1, id),
);

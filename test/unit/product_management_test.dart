import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/repositories/product_management_repository.dart';

void main() {
  group('Product sale status', () {
    test('unknown old metadata defaults to available', () {
      expect(ProductSaleStatus.parse(null), ProductSaleStatus.available);
      expect(ProductSaleStatus.parse('legacy'), ProductSaleStatus.available);
    });
    test('all three persistent names can roundtrip', () {
      for (final s in ProductSaleStatus.values) {
        expect(ProductSaleStatus.parse(s.name), s);
      }
    });
  });
  group('Product validation', () {
    test('cannot create blank or very long product names', () {
      expect(ProductInputRules.validateName('  '), isNotNull);
      expect(
        ProductInputRules.validateName(List.filled(101, 'x').join()),
        isNotNull,
      );
      expect(ProductInputRules.validateName('Trà sữa'), isNull);
    });
    test('product price must be positive', () {
      expect(ProductInputRules.validatePrice(-10), isNotNull);
      expect(ProductInputRules.validatePrice(0), isNotNull);
      expect(ProductInputRules.validatePrice(35000), isNull);
    });
    test('topping price may equal zero', () {
      expect(ProductInputRules.validatePrice(0, allowZero: true), isNull);
      expect(ProductInputRules.validatePrice(-1, allowZero: true), isNotNull);
    });
    test('only HTTP and HTTPS image links are allowed', () {
      expect(ProductInputRules.validateImageUrl(''), isNull);
      expect(
        ProductInputRules.validateImageUrl('https://example.org/a.png'),
        isNull,
      );
      expect(
        ProductInputRules.validateImageUrl('file:///private/photo.jpg'),
        isNotNull,
      );
    });
  });
}

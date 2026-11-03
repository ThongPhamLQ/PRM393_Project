import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/repositories/product_management_repository.dart';

void main() {
  group('ProductDeletionRules', () {
    test('deduplicates ids while keeping selection order', () {
      expect(ProductDeletionRules.validIds([2, 1, 2]), [2, 1]);
      expect(ProductDeletionRules.selectedVisibleIds([2, 1, 3], [1, 3]), [
        1,
        3,
      ]);
    });

    test('rejects invalid ids before database mutation', () {
      expect(() => ProductDeletionRules.validIds([0, 1]), throwsStateError);
      expect(() => ProductDeletionRules.validIds([-7]), throwsStateError);
    });
  });

  // FakeFirebaseFirestore: Firestore giả lập trong bộ nhớ (có transaction),
  // test chạy không cần mạng hay project Firebase thật
  group('Soft delete with in-memory Firestore', () {
    late FakeFirebaseFirestore db;
    late ProductManagementRepository repository;

    setUp(() async {
      db = FakeFirebaseFirestore();
      for (final id in [1, 2, 3]) {
        await db.collection('products').doc('$id').set({
          'id': id,
          'categoryId': 1,
          'name': 'Món $id',
          'description': '',
          'price': 30000 + id,
          'imageUrl': '',
          'status': 'available',
          'deleted': false,
        });
      }
      // Đơn cũ có món 1: xóa món không được làm đổi lịch sử đơn
      await db.collection('orders').doc('1').set({
        'id': 1,
        'items': [
          {'productName': 'Món 1', 'unitPrice': 30001, 'quantity': 1},
        ],
      });
      repository = ProductManagementRepository(db: db);
    });

    test(
      'deletes many products atomically without altering order history',
      () async {
        expect(await repository.softDeleteProducts([1, 2, 1]), 2);
        final active = await repository.getProducts();
        expect(active.map((p) => p.id), [3]);
        expect(
          (await repository.getDeletedProducts()).map((p) => p.id),
          containsAll([1, 2]),
        );
        expect(await repository.getUnavailableIds(), containsAll([1, 2]));
        final order = await db.collection('orders').doc('1').get();
        final item = (order['items'] as List).single as Map;
        expect(item['productName'], 'Món 1');
        expect(item['unitPrice'], 30001);
        expect((await db.collection('products').get()).docs.length, 3);
      },
    );

    test('rolls back entire selection if one product does not exist', () async {
      await expectLater(
        repository.softDeleteProducts([1, 999]),
        throwsStateError,
      );
      expect((await repository.getProducts()).length, 3);
      expect(await repository.getDeletedProducts(), isEmpty);
    });

    test(
      'restores the previous soldOut status, not blindly available',
      () async {
        await repository.changeProductStatus(2, ProductSaleStatus.soldOut);
        await repository.softDeleteProducts([1, 2]);
        await repository.restoreProduct(1);
        await repository.restoreProduct(2);
        final visible = await repository.getProducts();
        expect(visible.length, 3);
        expect(
          visible.firstWhere((p) => p.id == 1).status,
          ProductSaleStatus.available,
        );
        expect(
          visible.firstWhere((p) => p.id == 2).status,
          ProductSaleStatus.soldOut,
        );
        expect(await repository.getUnavailableIds(), contains(2));
        expect(await repository.getUnavailableIds(), isNot(contains(1)));
      },
    );

    test('cannot delete already deleted items again', () async {
      await repository.softDeleteProducts([1]);
      await expectLater(repository.softDeleteProducts([1]), throwsStateError);
      expect((await repository.getDeletedProducts()).length, 1);
    });

    test('new product gets the next id and rejects a missing category', () async {
      await db.collection('categories').doc('1').set({'id': 1, 'name': 'Cà phê'});
      await db.collection('counters').doc('products').set({'value': 3});
      final id = await repository.saveProduct(
        categoryId: 1,
        name: 'Món mới',
        description: '',
        price: 30000,
        imageUrl: '',
        status: ProductSaleStatus.available,
      );
      expect(id, 4);
      await expectLater(
        repository.saveProduct(
          categoryId: 99,
          name: 'Món lạc',
          description: '',
          price: 30000,
          imageUrl: '',
          status: ProductSaleStatus.available,
        ),
        throwsStateError,
      );
    });
  });
}

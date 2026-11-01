import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
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

  group('Soft delete with real in-memory SQLite', () {
    late Database db;
    late ProductManagementRepository repository;

    setUp(() async {
      ffi.sqfliteFfiInit();
      db = await ffi.databaseFactoryFfi.openDatabase(':memory:');
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY,
          categoryId INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          price INTEGER NOT NULL,
          imageUrl TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY,
          productName TEXT NOT NULL,
          unitPrice INTEGER NOT NULL
        )
      ''');
      for (final id in [1, 2, 3]) {
        await db.insert('products', {
          'id': id,
          'categoryId': 1,
          'name': 'Món $id',
          'description': '',
          'price': 30000 + id,
          'imageUrl': '',
        });
      }
      await db.insert('order_items', {
        'id': 1,
        'productName': 'Món 1',
        'unitPrice': 30001,
      });
      repository = ProductManagementRepository(databaseOpener: () async => db);
    });

    tearDown(() async => db.close());

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
        final order = await db.query('order_items');
        expect(order.single['productName'], 'Món 1');
        expect(order.single['unitPrice'], 30001);
        expect((await db.query('products')).length, 3);
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
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/data/datasources/local/product_local_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/product_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/product.dart';

void main() {
 late ProductRepositoryImpl repository;

 setUp(() {
 repository = ProductRepositoryImpl(ProductLocalDataSourceImpl());
 });

 Product buildProduct(String id, String name) => Product(
 id: id,
 name: name,
 purchasePriceCents: 500,
 salePriceCents: 990,
 );

 test('getAll retorna lista vazia inicialmente', () async {
 final products = await repository.getAll(storeId: 'st1');

 expect(products, isEmpty);
 });

 test('add persiste o produto e getAll o retorna', () async {
 await repository.add(buildProduct('1', 'Caneta'));

 final products = await repository.getAll(storeId: 'st1');

 expect(products, hasLength(1));
 expect(products.first.id, '1');
 expect(products.first.name, 'Caneta');
 });

 test('getAll retorna lista imutável (proteção contra mutação externa)',
 () async {
 await repository.add(buildProduct('1', 'Caneta'));

 final products = await repository.getAll(storeId: 'st1');

 // A lista retornada é uma cópia imutável: mutações externas falham
 // e não conseguem corromper o estado do repositório.
 expect(() => products.clear(), throwsUnsupportedError);
 expect(await repository.getAll(storeId: 'st1'), hasLength(1));
 });

 test('getById retorna o produto existente ou null (escopado pela loja)',
 () async {
 await repository.add(buildProduct('1', 'Caneta'));

 expect((await repository.getById('1', storeId: 'st1'))?.name, 'Caneta');
 expect(await repository.getById('inexistente', storeId: 'st1'), isNull);
 // Guarda por loja: mesmo id em outra loja não é visível.
 expect(await repository.getById('1', storeId: 'st2'), isNull);
 });

 test('updateStock substitui a quantidade em estoque (escopado pela loja)',
 () async {
 await repository.add(buildProduct('1', 'Caneta'));

 await repository.updateStock('1', 7, storeId: 'st1');

 expect((await repository.getById('1', storeId: 'st1'))?.stockQuantity, 7);
 });

 test('update persiste os campos editáveis (escopado pela loja)', () async {
 await repository.add(buildProduct('1', 'Caneta'));

 await repository.update(
 (await repository.getById('1', storeId: 'st1'))!.copyWith(
 name: 'Caneta Azul',
 salePriceCents: 250,
 isActive: false,
 ),
 );

 final updated = await repository.getById('1', storeId: 'st1');
 expect(updated?.name, 'Caneta Azul');
 expect(updated?.salePriceCents, 250);
 expect(updated?.isActive, isFalse);
 // Estoque preservado (a mutação de quantidade passa pelo FIFO).
 expect(updated?.stockQuantity, 0);
 });

 test('update lança StateError para produto de outra loja', () async {
 await repository.add(buildProduct('1', 'Caneta'));

 expect(
 () => repository.update(
 buildProduct('1', 'Caneta').copyWith(storeId: 'st2'),
 ),
 throwsStateError,
 );
 });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/cash_closing_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/cash_closing.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
 late Database db;
 late CashClosingSqliteDataSourceImpl dataSource;

 setUp(() {
 db = openTestDatabase();
 dataSource = CashClosingSqliteDataSourceImpl(db);
 });

 tearDown(() => db.close());

 CashClosing closing({
 required String id,
 required String storeId,
 required DateTime day,
 int counted = 1000,
 }) =>
 CashClosing(
 id: id,
 storeId: storeId,
 day: day,
 totalSalesCents: 3500,
 expectedCashCents: 1000,
 countedCashCents: counted,
 salesByMethodCents: const {'cash': 1000, 'mPesa': 2500},
 closedAt: DateTime(day.year, day.month, day.day, 19),
 );

 test('salva e lê o fecho do dia (persistência completa)', () async {
 await dataSource.save(
 closing(id: 'cc1', storeId: 'st1', day: DateTime(2026, 8, 10)),
 );

 final loaded = await dataSource.getByDay(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 );

 expect(loaded, isNotNull);
 expect(loaded!.id, 'cc1');
 expect(loaded.storeId, 'st1');
 expect(loaded.day, DateTime(2026, 8, 10));
 expect(loaded.totalSalesCents, 3500);
 expect(loaded.expectedCashCents, 1000);
 expect(loaded.countedCashCents, 1000);
 expect(loaded.salesByMethodCents, {'cash': 1000, 'mPesa': 2500});
 expect(loaded.closedAt, DateTime(2026, 8, 10, 19));
 });

 test('UPSERT: refazer o fecho do mesmo dia atualiza sem duplicar', () async {
 await dataSource.save(
 closing(id: 'cc1', storeId: 'st1', day: DateTime(2026, 8, 10)),
 );
 // Contagem corrigida (sobra detectada depois) — mesmo dia e loja.
 await dataSource.save(
 closing(
 id: 'cc1-updated',
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 counted: 1250,
 ),
 );

 final loaded = await dataSource.getByDay(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 );
 final all = await dataSource.getAll(storeId: 'st1');

 expect(loaded!.countedCashCents, 1250); // contagem atualizada
 expect(all, hasLength(1)); // nunca duplica
 });

 test('lojas independentes: o fecho de uma não vaza na outra', () async {
 await dataSource.save(
 closing(id: 'cc1', storeId: 'st1', day: DateTime(2026, 8, 10)),
 );
 await dataSource.save(
 closing(id: 'cc2', storeId: 'st2', day: DateTime(2026, 8, 10)),
 );

 expect(
 await dataSource.getByDay(storeId: 'st1', day: DateTime(2026, 8, 10)),
 isNotNull,
 );
 expect(
 await dataSource.getByDay(storeId: 'st2', day: DateTime(2026, 8, 10)),
 isNotNull,
 );
 expect(
 await dataSource.getByDay(storeId: 'st1', day: DateTime(2026, 8, 11)),
 isNull,
 );
 expect(await dataSource.getAll(storeId: 'st1'), hasLength(1));
 });

 test('histórico: mais recentes primeiro', () async {
 await dataSource.save(
 closing(id: 'cc1', storeId: 'st1', day: DateTime(2026, 8, 8)),
 );
 await dataSource.save(
 closing(id: 'cc2', storeId: 'st1', day: DateTime(2026, 8, 10)),
 );
 await dataSource.save(
 closing(id: 'cc3', storeId: 'st1', day: DateTime(2026, 8, 9)),
 );

 final all = await dataSource.getAll(storeId: 'st1');

 expect(all.map((c) => c.day).toList(), [
 DateTime(2026, 8, 10),
 DateTime(2026, 8, 9),
 DateTime(2026, 8, 8),
 ]);
 });
}

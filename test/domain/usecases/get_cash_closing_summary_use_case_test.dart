import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';

class _FakeSaleRepository implements ISaleRepository {
 _FakeSaleRepository(this._sales);

 final List<Sale> _sales;

 /// Quantas vezes `getAll` foi chamado (verifica o caminho server-side).
 int getAllCalls = 0;

 @override
 Future<void> registerSale(Sale sale) async {}

 @override
 Future<Sale?> getById(String id, {required String storeId}) async => null;

 @override
 Future<void> markCancelled(String id, {required String storeId}) async {}

 @override
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 }) async => const [];

 @override
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> consumption,
 ) async {}

 @override
 Future<List<Sale>> getAll({required String storeId}) async {
 getAllCalls++;
 return List.unmodifiable(_sales);
 }
}

class _FakeClosingRepository implements ICashClosingRepository {
 _FakeClosingRepository({this.existing});

 CashClosing? existing;

 /// Quantas vezes `getByDay` foi chamado (verifica o caminho server-side).
 int getByDayCalls = 0;

 @override
 Future<CashClosing?> getByDay({
 required String storeId,
 required DateTime day,
 }) async {
 getByDayCalls++;
 return existing;
 }

 @override
 Future<void> save(CashClosing closing) async {}

 @override
 Future<List<CashClosing>> getAll({required String storeId}) async => const [];
}

/// Agregação server-side fake — registra os argumentos recebidos e devolve
/// um [CashClosingSummary] fixo (como a RPC `get_cash_closing_summary`).
class _FakeServerSummaryRepository implements ICashClosingSummaryRepository {
 int fetchCalls = 0;
 String? lastStoreId;
 DateTime? lastDay;

 @override
 Future<CashClosingSummary> fetchSummary({
 required String storeId,
 required DateTime day,
 }) async {
 fetchCalls++;
 lastStoreId = storeId;
 lastDay = day;
 return CashClosingSummary(
 day: DateTime(day.year, day.month, day.day),
 totalSalesCents: 4050,
 expectedCashCents: 1100,
 salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
 );
 }
}

void main() {
 Sale sale({
 required String id,
 required int totalAmountCents,
 required PaymentMethod method,
 required DateTime dateTime,
 SaleStatus status = SaleStatus.active,
 }) =>
 Sale(
 id: id,
 items: const [],
 totalAmountCents: totalAmountCents,
 paymentMethod: method,
 dateTime: dateTime,
 status: status,
 );

 test('calcula total, esperado na gaveta (só dinheiro) e abertura por forma',
 () async {
 final useCase = GetCashClosingSummaryUseCase(
 _FakeSaleRepository([
 sale(
 id: 's1',
 totalAmountCents: 1000,
 method: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 10, 9),
 ),
 sale(
 id: 's2',
 totalAmountCents: 2500,
 method: PaymentMethod.mPesa,
 dateTime: DateTime(2026, 8, 10, 14),
 ),
 // Fora do dia — ignorada.
 sale(
 id: 's3',
 totalAmountCents: 99999,
 method: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 11),
 ),
 ]),
 _FakeClosingRepository(),
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 expect(summary.totalSalesCents, 3500); // 10.0 + 25.0 (todas as formas)
 expect(summary.expectedCashCents, 1000); // só dinheiro (10.0)
 expect(summary.salesByMethodCents, {'cash': 1000, 'mPesa': 2500});
 expect(summary.isClosed, isFalse);
 });

 test('venda ANULADA sai do fecho (mesmo critério da RPC)', () async {
 final useCase = GetCashClosingSummaryUseCase(
 _FakeSaleRepository([
 sale(
 id: 's1',
 totalAmountCents: 1000,
 method: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 10, 9),
 ),
 sale(
 id: 's2',
 totalAmountCents: 500,
 method: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 10, 10),
 status: SaleStatus.cancelled,
 ),
 ]),
 _FakeClosingRepository(),
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 expect(summary.totalSalesCents, 1000);
 expect(summary.expectedCashCents, 1000);
 expect(summary.salesByMethodCents, {'cash': 1000});
 });

 test('sem vendas em dinheiro → esperado zero (cartão não passa na gaveta)',
 () async {
 final useCase = GetCashClosingSummaryUseCase(
 _FakeSaleRepository([
 sale(
 id: 's1',
 totalAmountCents: 800,
 method: PaymentMethod.debitCard,
 dateTime: DateTime(2026, 8, 10, 9),
 ),
 ]),
 _FakeClosingRepository(),
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 expect(summary.totalSalesCents, 800);
 expect(summary.expectedCashCents, 0);
 });

 test('dia já fechado → existingClosing presente (isClosed true)', () async {
 final closing = CashClosing(
 id: 'cc-st1-20260810',
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 totalSalesCents: 3500,
 expectedCashCents: 1000,
 countedCashCents: 1000,
 salesByMethodCents: const {'cash': 1000, 'mPesa': 2500},
 closedAt: DateTime(2026, 8, 10, 19),
 );
 final useCase = GetCashClosingSummaryUseCase(
 _FakeSaleRepository(const []),
 _FakeClosingRepository(existing: closing),
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 expect(summary.isClosed, isTrue);
 expect(summary.existingClosing!.countedCashCents, 1000);
 // Diferença via extension: contado − esperado.
 expect(summary.existingClosing!.differenceCents, 0);
 });

 test('dia sem vendas → tudo zero e aberto', () async {
 final useCase = GetCashClosingSummaryUseCase(
 _FakeSaleRepository(const []),
 _FakeClosingRepository(),
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 expect(summary.totalSalesCents, 0);
 expect(summary.expectedCashCents, 0);
 expect(summary.salesByMethodCents, isEmpty);
 expect(summary.isClosed, isFalse);
 });

 test('com repositório server-side injetado, a agregação NÃO consulta as '
 'vendas nem o fecho local (H2 — UMA chamada RPC)', () async {
 final salesRepo = _FakeSaleRepository(const []);
 final closingRepo = _FakeClosingRepository();
 final server = _FakeServerSummaryRepository();
 final useCase = GetCashClosingSummaryUseCase(
 salesRepo,
 closingRepo,
 serverRepository: server,
 );

 final summary = await useCase(storeId: 'st1', day: DateTime(2026, 8, 10));

 // Resultado VEM do servidor, como está (sem recálculo local).
 expect(summary.totalSalesCents, 4050);
 expect(summary.expectedCashCents, 1100);
 expect(summary.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
 // A prévia server-side não toca o histórico local de vendas nem o fecho.
 expect(salesRepo.getAllCalls, 0);
 expect(closingRepo.getByDayCalls, 0);
 // Os argumentos chegam como esperado à RPC.
 expect(server.fetchCalls, 1);
 expect(server.lastStoreId, 'st1');
 expect(server.lastDay, DateTime(2026, 8, 10));
 });
}

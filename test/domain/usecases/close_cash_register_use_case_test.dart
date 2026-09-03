import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_processor.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/close_cash_register_use_case.dart';

class _FakeSaleRepository implements ISaleRepository {
 _FakeSaleRepository(this._sales);

 final List<Sale> _sales;

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
 Future<List<Sale>> getAll({required String storeId}) async =>
 List.unmodifiable(_sales);
}

class _FakeClosingRepository implements ICashClosingRepository {
 final List<CashClosing> saved = [];

 @override
 Future<CashClosing?> getByDay({
 required String storeId,
 required DateTime day,
 }) async =>
 null;

 @override
 Future<void> save(CashClosing closing) async => saved.add(closing);

 @override
 Future<List<CashClosing>> getAll({required String storeId}) async =>
 List.unmodifiable(saved);
}

/// Fake do processador atômico (Supabase) — registra as chamadas e devolve
/// um fecho como a RPC faria.
class _FakeProcessor implements ICashClosingProcessor {
 _FakeProcessor(this.closings);

 final List<CashClosing> closings;
 int calls = 0;

 @override
 Future<CashClosing> close({
 required String storeId,
 required DateTime day,
 required int countedCashCents,
 }) async {
 calls++;
 final closing = CashClosing(
 id: 'cc-$storeId-20260810',
 storeId: storeId,
 day: DateTime(day.year, day.month, day.day),
 totalSalesCents: 4050,
 expectedCashCents: 1100,
 countedCashCents: countedCashCents,
 salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
 closedAt: DateTime(2026, 8, 10, 19),
 );
 closings.add(closing);
 return closing;
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

 test('fecha o caixa no modo local: calcula esperado (só dinheiro) e salva',
 () async {
 final sales = [
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
 // Anulada — NÃO entra no fecho.
 sale(
 id: 's3',
 totalAmountCents: 500,
 method: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 10, 10),
 status: SaleStatus.cancelled,
 ),
 ];
 final repository = _FakeClosingRepository();
 final useCase = CloseCashRegisterUseCase(
 _FakeSaleRepository(sales),
 repository,
 );

 final closing = await useCase(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: 1000, // conferiu com o esperado
 );

 expect(closing.totalSalesCents, 3500);
 expect(closing.expectedCashCents, 1000); // só dinheiro ATIVO
 expect(closing.countedCashCents, 1000);
 expect(closing.salesByMethodCents, {'cash': 1000, 'mPesa': 2500});
 expect(closing.differenceCents, 0); // confere
 expect(repository.saved, hasLength(1));
 expect(repository.saved.first.id, closing.id);
 });

 test('contagem NEGATIVA é rejeitada (InvalidCashCountException)', () async {
 final useCase = CloseCashRegisterUseCase(
 _FakeSaleRepository(const []),
 _FakeClosingRepository(),
 );

 expect(
 () => useCase(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: -1,
 ),
 throwsA(isA<InvalidCashCountException>()),
 );
 });

 test('sem vendas em dinheiro → esperado 0 e fecho com total das outras formas',
 () async {
 final repository = _FakeClosingRepository();
 final useCase = CloseCashRegisterUseCase(
 _FakeSaleRepository([
 sale(
 id: 's1',
 totalAmountCents: 800,
 method: PaymentMethod.debitCard,
 dateTime: DateTime(2026, 8, 10, 9),
 ),
 ]),
 repository,
 );

 final closing = await useCase(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: 0, // gaveta zerada (dono pode fechar assim)
 );

 expect(closing.totalSalesCents, 800);
 expect(closing.expectedCashCents, 0);
 expect(closing.differenceCents, 0);
 });

 test('delega para o processador atômico quando fornecido (Supabase)',
 () async {
 final closings = <CashClosing>[];
 final processor = _FakeProcessor(closings);
 final useCase = CloseCashRegisterUseCase(
 _FakeSaleRepository(const []), // NÃO deve ser consultado no modo SaaS
 _FakeClosingRepository(),
 processor: processor,
 );

 final closing = await useCase(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: 1100,
 );

 // Uma única chamada à RPC; o servidor é a autoridade.
 expect(processor.calls, 1);
 expect(closing.expectedCashCents, 1100);
 expect(closing.totalSalesCents, 4050);
 expect(closings, hasLength(1));
 });

 test('validação de negativa acontece ANTES da delegação (mesmo com RPC)',
 () async {
 final processor = _FakeProcessor([]);
 final useCase = CloseCashRegisterUseCase(
 _FakeSaleRepository(const []),
 _FakeClosingRepository(),
 processor: processor,
 );

 expect(
 () => useCase(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: -5,
 ),
 throwsA(isA<InvalidCashCountException>()),
 );
 expect(processor.calls, 0);
 });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/quotation_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/quotation.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Quotation buildQuotation({
    required String id,
    String storeId = 'st1',
    String customerName = 'Cliente A',
    QuotationStatus status = QuotationStatus.draft,
  }) => Quotation(
    id: id,
    storeId: storeId,
    customerId: 'c1',
    customerName: customerName,
    customerPhone: '84 123 4567',
    items: const [
      QuotationItem(
        productId: 'p1',
        productName: 'Caneta',
        quantity: 2000,
        unitPriceCents: 200,
      ),
      QuotationItem(
        productId: 'p2',
        productName: 'Caderno',
        quantity: 1000,
        unitPriceCents: 990,
      ),
    ],
    totalAmountCents: 1390,
    status: status,
    validUntil: DateTime(2026, 8, 10),
    createdAt: DateTime(2026, 8, 3, 14, 30),
  );

  test('add persiste e reconstrói a cotação completa com items', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    await dataSource.add(buildQuotation(id: 'qt1'));

    final quotations = await dataSource.getAll(storeId: 'st1');
    expect(quotations, hasLength(1));
    final quotation = quotations.first;
    expect(quotation.id, 'qt1');
    expect(quotation.customerName, 'Cliente A');
    expect(quotation.totalAmountCents, 1390);
    expect(quotation.items, hasLength(2));
    expect(quotation.items.first.productName, 'Caneta');
    expect(quotation.items.first.quantity, 2000);
    expect(quotation.status, QuotationStatus.draft);
    expect(quotation.createdAt, DateTime(2026, 8, 3, 14, 30));
  });

  test('número sequencial por loja (MAX+1) — segunda cotação = 2', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    final first = await dataSource.add(buildQuotation(id: 'qt1'));
    final second = await dataSource.add(buildQuotation(id: 'qt2'));

    expect(first.number, 1);
    expect(second.number, 2);
  });

  test('número reinicia por loja (isolamento de loja)', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    await dataSource.add(buildQuotation(id: 'qt1', storeId: 'st1'));
    await dataSource.add(buildQuotation(id: 'qt2', storeId: 'st2'));

    final store1 = await dataSource.getAll(storeId: 'st1');
    final store2 = await dataSource.getAll(storeId: 'st2');
    expect(store1.single.number, 1);
    expect(store2.single.number, 1);
  });

  test('getAll só devolve cotações da loja pedida', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    await dataSource.add(buildQuotation(id: 'qt1', storeId: 'st1'));
    await dataSource.add(buildQuotation(id: 'qt2', storeId: 'st2'));

    final other = await dataSource.getAll(storeId: 'st9');
    expect(other, isEmpty);
  });

  test('add com id duplicado lança (espelha a PK do banco)', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);
    await dataSource.add(buildQuotation(id: 'qt1'));

    await expectLater(
      dataSource.add(buildQuotation(id: 'qt1')),
      throwsA(isA<StateError>()),
    );
  });

  test('update persiste a transição de estado preservando o número', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    final saved = await dataSource.add(buildQuotation(id: 'qt1'));
    expect(saved.status, QuotationStatus.draft);

    // Transição rascunho → enviada → aceite (estado real, persistido).
    final sent = await dataSource.update(
      saved.copyWith(status: QuotationStatus.sent),
    );
    expect(sent.status, QuotationStatus.sent);
    expect(sent.number, saved.number);

    final accepted = await dataSource.update(
      sent.copyWith(
        status: QuotationStatus.accepted,
        acceptedAt: DateTime(2026, 8, 4, 9),
      ),
    );
    expect(accepted.status, QuotationStatus.accepted);
    expect(accepted.number, saved.number);

    final reloaded = await dataSource.getAll(storeId: 'st1');
    expect(reloaded.single.status, QuotationStatus.accepted);
    expect(reloaded.single.acceptedAt, DateTime(2026, 8, 4, 9));
  });

  test('update de cotação inexistente lança StateError', () async {
    final dataSource = QuotationSqliteDataSourceImpl(db);

    await expectLater(
      dataSource.update(buildQuotation(id: 'qt9')),
      throwsA(isA<StateError>()),
    );
  });
}

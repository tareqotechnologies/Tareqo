import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/custom_invoice_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/custom_invoice.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  CustomInvoice buildInvoice({
    required String id,
    String storeId = 'st1',
    String clientName = 'Cliente A',
  }) => CustomInvoice(
    id: id,
    storeId: storeId,
    clientName: clientName,
    clientPhone: '84 123 4567',
    clientTaxId: '123456789',
    items: const [
      CustomInvoiceItem(
        productName: 'Caneta',
        quantity: 2,
        unitPriceCents: 200,
        subtotalCents: 400,
      ),
      CustomInvoiceItem(
        productName: 'Caderno',
        quantity: 1,
        unitPriceCents: 990,
        subtotalCents: 990,
      ),
    ],
    totalAmountCents: 1390,
    discountCents: 0,
    taxCents: 0,
    createdAt: DateTime(2026, 8, 3, 14, 30),
  );

  test('add persiste e reconstrói a factura completa com items', () async {
    final dataSource = CustomInvoiceSqliteDataSourceImpl(db);

    await dataSource.add(buildInvoice(id: 'ci1'));

    final invoices = await dataSource.getAll(storeId: 'st1');
    expect(invoices, hasLength(1));
    final invoice = invoices.first;
    expect(invoice.id, 'ci1');
    expect(invoice.clientName, 'Cliente A');
    expect(invoice.clientTaxId, '123456789');
    expect(invoice.totalAmountCents, 1390);
    expect(invoice.items, hasLength(2));
    expect(invoice.items.first.productName, 'Caneta');
    expect(invoice.items.last.subtotalCents, 990);
    expect(invoice.createdAt, DateTime(2026, 8, 3, 14, 30));
  });

  test('número sequencial por loja (MAX+1) — segunda factura = 2', () async {
    final dataSource = CustomInvoiceSqliteDataSourceImpl(db);

    final first = await dataSource.add(buildInvoice(id: 'ci1'));
    final second = await dataSource.add(buildInvoice(id: 'ci2'));

    expect(first.number, 1);
    expect(second.number, 2);
  });

  test('número reinicia por loja (isolamento de loja)', () async {
    final dataSource = CustomInvoiceSqliteDataSourceImpl(db);

    await dataSource.add(buildInvoice(id: 'ci1', storeId: 'st1'));
    await dataSource.add(buildInvoice(id: 'ci2', storeId: 'st2'));

    final store1 = await dataSource.getAll(storeId: 'st1');
    final store2 = await dataSource.getAll(storeId: 'st2');
    expect(store1.single.number, 1);
    expect(store2.single.number, 1);
  });

  test('getAll só devolve facturas da loja pedida', () async {
    final dataSource = CustomInvoiceSqliteDataSourceImpl(db);

    await dataSource.add(buildInvoice(id: 'ci1', storeId: 'st1'));
    await dataSource.add(buildInvoice(id: 'ci2', storeId: 'st2'));

    final other = await dataSource.getAll(storeId: 'st9');
    expect(other, isEmpty);
  });

  test('add com id duplicado lança (espelha a PK do banco)', () async {
    final dataSource = CustomInvoiceSqliteDataSourceImpl(db);
    await dataSource.add(buildInvoice(id: 'ci1'));

    await expectLater(
      dataSource.add(buildInvoice(id: 'ci1')),
      throwsA(isA<StateError>()),
    );
  });
}

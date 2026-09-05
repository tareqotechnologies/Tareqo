import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/custom_invoice_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/custom_invoice_repository_impl.dart';
import 'package:tareqo/domain/entities/custom_invoice.dart';

CustomInvoice buildInvoice({
  required String id,
  String storeId = 'st1',
  int number = 0,
  DateTime? createdAt,
}) =>
    CustomInvoice(
      id: id,
      storeId: storeId,
      number: number,
      clientName: 'Cliente $id',
      items: const [
        CustomInvoiceItem(
          productName: 'Caneta',
          quantity: 1,
          unitPriceCents: 200,
          subtotalCents: 200,
        ),
      ],
      totalAmountCents: 200,
      createdAt: createdAt ?? DateTime(2026, 8, 3, 10),
    );

void main() {
  group('CustomInvoiceLocalDataSourceImpl', () {
    test('add atribui número sequencial por loja (MAX+1)', () async {
      final dataSource = CustomInvoiceLocalDataSourceImpl();

      final first = await dataSource.add(buildInvoice(id: 'ci1'));
      final second = await dataSource.add(buildInvoice(id: 'ci2'));
      final otherStore = await dataSource.add(
        buildInvoice(id: 'ci3', storeId: 'st2'),
      );

      expect(first.number, 1);
      expect(second.number, 2);
      // Números independentes por loja (isolamento de loja).
      expect(otherStore.number, 1);
    });

    test('getAll devolve só facturas da loja, mais recentes primeiro',
        () async {
      final dataSource = CustomInvoiceLocalDataSourceImpl();

      await dataSource.add(
        buildInvoice(id: 'ci1', createdAt: DateTime(2026, 8, 1)),
      );
      await dataSource.add(
        buildInvoice(id: 'ci2', createdAt: DateTime(2026, 8, 5)),
      );
      await dataSource.add(
        buildInvoice(id: 'ci9', storeId: 'st2'),
      );

      final invoices = await dataSource.getAll(storeId: 'st1');
      expect(invoices.map((i) => i.id), ['ci2', 'ci1']);
    });

    test('add com id duplicado lança StateError', () async {
      final dataSource = CustomInvoiceLocalDataSourceImpl();
      await dataSource.add(buildInvoice(id: 'ci1'));

      await expectLater(
        dataSource.add(buildInvoice(id: 'ci1')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('CustomInvoiceRepositoryImpl', () {
    test('delega para o datasource (número atribuído na gravação)',
        () async {
      final repository = CustomInvoiceRepositoryImpl(
        CustomInvoiceLocalDataSourceImpl(),
      );

      final saved = await repository.add(
        buildInvoice(id: 'ci1').copyWith(number: 0),
      );
      final all = await repository.getByStore('st1');

      expect(saved.number, 1);
      expect(all, hasLength(1));
      expect(all.first.number, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/quotation_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/quotation_repository_impl.dart';
import 'package:tareqo/domain/entities/quotation.dart';

Quotation buildQuotation({
  required String id,
  String storeId = 'st1',
  int number = 0,
  QuotationStatus status = QuotationStatus.draft,
  DateTime? createdAt,
}) => Quotation(
  id: id,
  storeId: storeId,
  number: number,
  customerId: 'c1',
  customerName: 'Cliente $id',
  items: const [
    QuotationItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1000,
      unitPriceCents: 200,
    ),
  ],
  totalAmountCents: 200,
  status: status,
  validUntil: DateTime(2026, 8, 10),
  createdAt: createdAt ?? DateTime(2026, 8, 3, 10),
);

void main() {
  group('QuotationLocalDataSourceImpl', () {
    test('add atribui número sequencial por loja (MAX+1)', () async {
      final dataSource = QuotationLocalDataSourceImpl();

      final first = await dataSource.add(buildQuotation(id: 'qt1'));
      final second = await dataSource.add(buildQuotation(id: 'qt2'));
      final otherStore = await dataSource.add(
        buildQuotation(id: 'qt3', storeId: 'st2'),
      );

      expect(first.number, 1);
      expect(second.number, 2);
      // Números independentes por loja (isolamento de loja).
      expect(otherStore.number, 1);
    });

    test(
      'getAll devolve só cotações da loja, mais recentes primeiro',
      () async {
        final dataSource = QuotationLocalDataSourceImpl();

        await dataSource.add(
          buildQuotation(id: 'qt1', createdAt: DateTime(2026, 8, 1)),
        );
        await dataSource.add(
          buildQuotation(id: 'qt2', createdAt: DateTime(2026, 8, 5)),
        );
        await dataSource.add(buildQuotation(id: 'qt9', storeId: 'st2'));

        final quotations = await dataSource.getAll(storeId: 'st1');
        expect(quotations.map((q) => q.id), ['qt2', 'qt1']);
      },
    );

    test('add com id duplicado lança StateError', () async {
      final dataSource = QuotationLocalDataSourceImpl();
      await dataSource.add(buildQuotation(id: 'qt1'));

      await expectLater(
        dataSource.add(buildQuotation(id: 'qt1')),
        throwsA(isA<StateError>()),
      );
    });

    test('update grava a transição de estado preservando o número', () async {
      final dataSource = QuotationLocalDataSourceImpl();
      final saved = await dataSource.add(buildQuotation(id: 'qt1'));

      final updated = await dataSource.update(
        saved.copyWith(status: QuotationStatus.sent),
      );

      expect(updated.status, QuotationStatus.sent);
      expect(updated.number, saved.number);
      expect(
        (await dataSource.getAll(storeId: 'st1')).single.status,
        QuotationStatus.sent,
      );
    });

    test('update de cotação inexistente lança StateError', () async {
      final dataSource = QuotationLocalDataSourceImpl();

      await expectLater(
        dataSource.update(buildQuotation(id: 'qt9')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('QuotationRepositoryImpl', () {
    test('delega para o datasource (número atribuído na gravação)', () async {
      final repository = QuotationRepositoryImpl(
        QuotationLocalDataSourceImpl(),
      );

      final saved = await repository.add(
        buildQuotation(id: 'qt1').copyWith(number: 0),
      );
      final all = await repository.getByStore('st1');

      expect(saved.number, 1);
      expect(all, hasLength(1));
      expect(all.first.number, 1);
    });

    test('update delega a transição de estado', () async {
      final repository = QuotationRepositoryImpl(
        QuotationLocalDataSourceImpl(),
      );
      final saved = await repository.add(buildQuotation(id: 'qt1'));

      final updated = await repository.update(
        saved.copyWith(status: QuotationStatus.accepted),
      );

      expect(updated.status, QuotationStatus.accepted);
      expect(
        (await repository.getByStore('st1')).single.status,
        QuotationStatus.accepted,
      );
    });
  });
}

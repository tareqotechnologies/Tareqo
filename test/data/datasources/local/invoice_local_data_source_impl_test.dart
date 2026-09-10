import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/invoice_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/invoice.dart';

Invoice _invoice(
  String id, {
  String tenantId = 'tn1',
  InvoiceStatus status = InvoiceStatus.pending,
  DateTime? createdAt,
  String period = 'Agosto 2026',
}) => Invoice(
  id: id,
  tenantId: tenantId,
  planId: 'pl_starter',
  amountCents: 9900,
  status: status,
  dueDate: DateTime(2026, 9, 1),
  period: period,
  createdAt: createdAt ?? DateTime(2026, 8, 1),
);

void main() {
  group('InvoiceLocalDataSourceImpl (memória — web/fallback)', () {
    test(
      'create numera sequencialmente (MAX+1) e preserva id informado',
      () async {
        final ds = InvoiceLocalDataSourceImpl();

        final a = await ds.create(
          _invoice('', createdAt: DateTime(2026, 8, 1)),
        );
        final b = await ds.create(
          _invoice('meu-id', createdAt: DateTime(2026, 8, 2)),
        );

        expect(a.id, isNotEmpty); // id vazio → gerado pelo datasource
        expect(a.id, startsWith('inv'));
        expect(b.id, 'meu-id'); // id informado é preservado
        expect(a.number, 1);
        expect(b.number, 2);
      },
    );

    test('getByTenant filtra e ordena MAIS RECENTE primeiro', () async {
      final ds = InvoiceLocalDataSourceImpl(
        seed: [
          _invoice('i1', createdAt: DateTime(2026, 8, 1)),
          _invoice('i2', tenantId: 'tn2'),
          _invoice('i3', createdAt: DateTime(2026, 8, 15)),
        ],
      );

      final invoices = await ds.getByTenant('tn1');

      expect(invoices.map((i) => i.id), ['i3', 'i1']);
    });

    test('getPending devolve só PENDENTES, mais antiga primeiro', () async {
      final ds = InvoiceLocalDataSourceImpl(
        seed: [
          _invoice('i1', createdAt: DateTime(2026, 8, 10)),
          _invoice('i2', status: InvoiceStatus.paid),
          _invoice('i3', createdAt: DateTime(2026, 8, 5)),
          _invoice('i4', status: InvoiceStatus.expired),
          _invoice('i5', status: InvoiceStatus.cancelled),
        ],
      );

      final pending = await ds.getPending();

      expect(pending.map((i) => i.id), ['i3', 'i1']);
    });

    test('getAll devolve todas em ordem de criação', () async {
      final ds = InvoiceLocalDataSourceImpl(
        seed: [
          _invoice('i1', createdAt: DateTime(2026, 8, 2)),
          _invoice('i2', createdAt: DateTime(2026, 8, 1)),
        ],
      );

      expect((await ds.getAll()).map((i) => i.id), ['i2', 'i1']);
    });

    test('markAsPaid carimba pago com o instante do recebimento', () async {
      final ds = InvoiceLocalDataSourceImpl(seed: [_invoice('i1')]);

      await ds.markAsPaid('i1');

      final paid = await ds.getByTenant('tn1');
      expect(paid.single.status, InvoiceStatus.paid);
      expect(paid.single.paidAt, isNotNull);
    });

    test('markAsPaid de factura inexistente lança StateError', () async {
      final ds = InvoiceLocalDataSourceImpl();
      await expectLater(ds.markAsPaid('fantasma'), throwsA(isA<StateError>()));
    });

    test('cancel marca cancelada (sem carimbar pagamento)', () async {
      final ds = InvoiceLocalDataSourceImpl(seed: [_invoice('i1')]);

      await ds.cancel('i1');

      final cancelled = await ds.getByTenant('tn1');
      expect(cancelled.single.status, InvoiceStatus.cancelled);
      expect(cancelled.single.paidAt, isNull);
    });

    test('cancel de factura inexistente lança StateError', () async {
      final ds = InvoiceLocalDataSourceImpl();
      await expectLater(ds.cancel('fantasma'), throwsA(isA<StateError>()));
    });

    test(
      'hasPendingForPeriod identifica pendência do período (só mesma tenant)',
      () async {
        final ds = InvoiceLocalDataSourceImpl(
          seed: [
            _invoice('i1', period: 'Agosto 2026'),
            _invoice('i2', tenantId: 'tn2', period: 'Agosto 2026'),
          ],
        );

        expect(await ds.hasPendingForPeriod('tn1', 'Agosto 2026'), isTrue);
        // Mesmo período, mas pago → não bloqueia nova geração:
        final paid = await ds.create(
          _invoice('i3', status: InvoiceStatus.paid),
        );
        final ds2 = InvoiceLocalDataSourceImpl(
          seed: [_invoice('i3', status: InvoiceStatus.paid)],
        );
        expect(await ds2.hasPendingForPeriod('tn1', 'Agosto 2026'), isFalse);
        expect(paid.status, InvoiceStatus.paid);
      },
    );

    test('hasPendingForPeriod devolve false para período novo', () async {
      final ds = InvoiceLocalDataSourceImpl(seed: [_invoice('i1')]);
      expect(await ds.hasPendingForPeriod('tn1', 'Setembro 2026'), isFalse);
    });
  });
}

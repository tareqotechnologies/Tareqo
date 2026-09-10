import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/invoice_notification_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';

InvoiceNotification _notification(
  String id, {
  String tenantId = 'tn1',
  bool isRead = false,
  DateTime? createdAt,
}) => InvoiceNotification(
  id: id,
  tenantId: tenantId,
  type: InvoiceNotificationType.invoiceGenerated,
  title: 'Factura gerada',
  body: 'Factura de Agosto',
  isRead: isRead,
  createdAt: createdAt ?? DateTime(2026, 8, 1),
);

void main() {
  group('InvoiceNotificationLocalDataSourceImpl (memória — web/fallback)', () {
    test('create gera id quando vazio e preserva id informado', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl();

      final a = await ds.create(
        _notification('').copyWith(createdAt: DateTime(2026, 8, 1)),
      );
      final b = await ds.create(_notification('meu-id'));

      expect(a.id, startsWith('inv_notif'));
      expect(b.id, 'meu-id');
    });

    test('getByTenant filtra e ordena MAIS RECENTE primeiro', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl(
        seed: [
          _notification('n1', createdAt: DateTime(2026, 8, 1)),
          _notification('n2', tenantId: 'tn2'),
          _notification('n3', createdAt: DateTime(2026, 8, 15)),
        ],
      );

      expect((await ds.getByTenant('tn1')).map((n) => n.id), ['n3', 'n1']);
    });

    test(
      'getUnreadByTenant devolve só NÃO LIDAS (mais recente primeiro)',
      () async {
        final ds = InvoiceNotificationLocalDataSourceImpl(
          seed: [
            _notification('n1', isRead: true),
            _notification('n2', createdAt: DateTime(2026, 8, 2)),
            _notification('n3', createdAt: DateTime(2026, 8, 3)),
            _notification('n4', tenantId: 'tn2'),
          ],
        );

        expect((await ds.getUnreadByTenant('tn1')).map((n) => n.id), [
          'n3',
          'n2',
        ]);
      },
    );

    test('getUnreadCount conta só não lidas da tenant', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl(
        seed: [
          _notification('n1'),
          _notification('n2', isRead: true),
          _notification('n3', tenantId: 'tn2'),
        ],
      );

      expect(await ds.getUnreadCount('tn1'), 1);
      expect(await ds.getUnreadCount('tn2'), 1);
      expect(await ds.getUnreadCount('fantasma'), 0);
    });

    test('markAsRead carimba isRead + readAt (uma notificação)', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl(
        seed: [_notification('n1'), _notification('n2')],
      );

      await ds.markAsRead('n1');

      final list = await ds.getByTenant('tn1');
      final n1 = list.firstWhere((n) => n.id == 'n1');
      final n2 = list.firstWhere((n) => n.id == 'n2');
      expect(n1.isRead, isTrue);
      expect(n1.readAt, isNotNull);
      expect(n2.isRead, isFalse);
    });

    test('markAsRead de notificação inexistente lança StateError', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl();
      await expectLater(ds.markAsRead('fantasma'), throwsA(isA<StateError>()));
    });

    test('markAllAsRead marca TODAS do tenant (só dele)', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl(
        seed: [
          _notification('n1'),
          _notification('n2'),
          _notification('n3', tenantId: 'tn2'),
          _notification('n4', isRead: true),
        ],
      );

      await ds.markAllAsRead('tn1');

      final tn1 = await ds.getByTenant('tn1');
      expect(tn1.every((n) => n.isRead), isTrue);
      // Isolamento: a de outro tenant continua não lida.
      final tn2 = await ds.getByTenant('tn2');
      expect(tn2.single.isRead, isFalse);
    });

    test('delete remove a notificação (e falha para inexistente)', () async {
      final ds = InvoiceNotificationLocalDataSourceImpl(
        seed: [_notification('n1'), _notification('n2')],
      );

      await ds.delete('n1');
      expect((await ds.getByTenant('tn1')).map((n) => n.id), ['n2']);

      await expectLater(ds.delete('fantasma'), throwsA(isA<StateError>()));
    });
  });
}

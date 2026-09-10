import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/admin_message_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/audit_log_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/admin_message.dart';

AdminMessage _message(
  String id, {
  String tenantId = 'tn1',
  bool isRead = false,
  DateTime? createdAt,
}) => AdminMessage(
  id: id,
  tenantId: tenantId,
  type: AdminMessageType.general,
  title: 'Aviso',
  body: 'Corpo do aviso $id',
  isRead: isRead,
  createdAt: createdAt ?? DateTime(2026, 8, 1),
);

void main() {
  group('AdminMessageLocalDataSourceImpl (memória — dev/testes)', () {
    test('create guarda e getByTenant devolve MAIS RECENTE primeiro', () async {
      final ds = AdminMessageLocalDataSourceImpl();
      await ds.create(_message('m1', createdAt: DateTime(2026, 8, 1)));
      await ds.create(_message('m2', tenantId: 'tn2'));
      await ds.create(_message('m3', createdAt: DateTime(2026, 8, 15)));

      final messages = await ds.getByTenant('tn1');

      expect(messages.map((m) => m.id), ['m3', 'm1']);
    });

    test('getUnreadCount conta só não lidas do tenant', () async {
      final ds = AdminMessageLocalDataSourceImpl();
      await ds.create(_message('m1'));
      await ds.create(_message('m2', isRead: true));
      await ds.create(_message('m3', tenantId: 'tn2'));

      expect(await ds.getUnreadCount('tn1'), 1);
      expect(await ds.getUnreadCount('tn2'), 1);
    });

    test('markAsRead marca uma (inexistente é no-op silencioso)', () async {
      final ds = AdminMessageLocalDataSourceImpl();
      await ds.create(_message('m1'));
      await ds.create(_message('m2'));

      await ds.markAsRead('m1');
      await ds.markAsRead('fantasma'); // contrato: sem exceção

      final messages = await ds.getByTenant('tn1');
      expect(messages.firstWhere((m) => m.id == 'm1').isRead, isTrue);
      expect(messages.firstWhere((m) => m.id == 'm2').isRead, isFalse);
    });

    test('markAllAsRead marca todas do tenant (só dele)', () async {
      final ds = AdminMessageLocalDataSourceImpl();
      await ds.create(_message('m1'));
      await ds.create(_message('m2', isRead: true));
      await ds.create(_message('m3', tenantId: 'tn2'));

      await ds.markAllAsRead('tn1');

      final tn1 = await ds.getByTenant('tn1');
      expect(tn1.every((m) => m.isRead), isTrue);
      expect((await ds.getByTenant('tn2')).single.isRead, isFalse);
    });
  });

  group('AuditLogLocalDataSourceImpl (modo local)', () {
    test('getAuditLog devolve SEMPRE vazio (sem tabela local)', () async {
      const ds = AuditLogLocalDataSourceImpl();

      final log = await ds.getAuditLog();

      expect(log, isEmpty);
    });

    test('getAuditLog respeita o limite informado (contrato)', () async {
      const ds = AuditLogLocalDataSourceImpl();
      expect(await ds.getAuditLog(limit: 5), isEmpty);
    });
  });
}

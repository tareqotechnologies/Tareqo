import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/repositories/i_admin_message_repository.dart';
import 'package:tareqo/domain/repositories/i_invoice_notification_repository.dart';
import 'package:tareqo/domain/usecases/get_tenant_admin_messages_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_notifications_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_admin_messages_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_admin_message_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:tareqo/presentation/controllers/admin_message_providers.dart';
import 'package:tareqo/presentation/controllers/notification_providers.dart';
import 'package:tareqo/presentation/screens/dashboard/notifications_screen.dart';

/// Repositório de notificações de facturas em memória.
class _FakeNotificationRepository implements IInvoiceNotificationRepository {
  _FakeNotificationRepository(this._notifications);

  final List<InvoiceNotification> _notifications;
  int markOneCalls = 0;
  int markAllCalls = 0;
  String? lastMarkedId;

  @override
  Future<InvoiceNotification> create(InvoiceNotification notification) async =>
      notification;

  @override
  Future<List<InvoiceNotification>> getByTenant(String tenantId) async =>
      _notifications;

  @override
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) async =>
      _notifications.where((n) => !n.isRead).toList();

  @override
  Future<int> getUnreadCount(String tenantId) async =>
      _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> markAsRead(String notificationId) async {
    markOneCalls++;
    lastMarkedId = notificationId;
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    markAllCalls++;
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> delete(String notificationId) async {}
}

/// Repositório de mensagens do admin em memória.
class _FakeAdminMessageRepository implements IAdminMessageRepository {
  _FakeAdminMessageRepository(this._messages);

  final List<AdminMessage> _messages;
  int markOneCalls = 0;
  int markAllCalls = 0;

  @override
  Future<AdminMessage> create(AdminMessage message) async => message;

  @override
  Future<List<AdminMessage>> getByTenant(String tenantId) async => _messages;

  @override
  Future<int> getUnreadCount(String tenantId) async =>
      _messages.where((m) => !m.isRead).length;

  @override
  Future<void> markAsRead(String messageId) async {
    markOneCalls++;
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    markAllCalls++;
    for (var i = 0; i < _messages.length; i++) {
      _messages[i] = _messages[i].copyWith(isRead: true);
    }
  }
}

InvoiceNotification _notification({
  String id = 'n1',
  InvoiceNotificationType type = InvoiceNotificationType.invoiceGenerated,
  bool isRead = false,
  DateTime? createdAt,
}) => InvoiceNotification(
  id: id,
  tenantId: 'tn1',
  type: type,
  title: 'Nova factura gerada',
  body: 'Factura INV-00001 no valor de 990,00 MT',
  isRead: isRead,
  createdAt: createdAt ?? DateTime.now(),
);

AdminMessage _message({
  String id = 'm1',
  bool isRead = false,
  AdminMessageType type = AdminMessageType.billingQuote,
}) => AdminMessage(
  id: id,
  tenantId: 'tn1',
  type: type,
  title: 'Cotação de Plano — Comercial',
  body: 'Segue a cotação para renovação do seu plano.',
  isRead: isRead,
  createdAt: DateTime.now(),
);

Widget _buildApp({
  required _FakeNotificationRepository notificationRepo,
  required _FakeAdminMessageRepository messageRepo,
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getTenantNotificationsUseCaseProvider.overrideWithValue(
        GetTenantNotificationsUseCase(notificationRepo),
      ),
      markNotificationAsReadUseCaseProvider.overrideWithValue(
        MarkNotificationAsReadUseCase(notificationRepo),
      ),
      markAllNotificationsAsReadUseCaseProvider.overrideWithValue(
        MarkAllNotificationsAsReadUseCase(notificationRepo),
      ),
      getTenantAdminMessagesUseCaseProvider.overrideWithValue(
        GetTenantAdminMessagesUseCase(messageRepo),
      ),
      markAdminMessageAsReadUseCaseProvider.overrideWithValue(
        MarkAdminMessageAsReadUseCase(messageRepo),
      ),
      markAllAdminMessagesAsReadUseCaseProvider.overrideWithValue(
        MarkAllAdminMessagesAsReadUseCase(messageRepo),
      ),
    ],
    child: testApp(
      home: const NotificationsScreen(),
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.7, child: child!),
    ),
  );
}

void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('estado vazio quando não há notificações nem mensagens', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([]),
        messageRepo: _FakeAdminMessageRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem notificações'), findsOneWidget);
    expect(
      find.text('As notificações de facturas aparecerão aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('lista mensagens do admin e notificações de factura com badge', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([
          _notification(id: 'n1'),
          _notification(id: 'n2', isRead: true),
        ]),
        messageRepo: _FakeAdminMessageRepository([_message()]),
      ),
    );
    await tester.pumpAndSettle();

    // Mensagem do admin primeiro, depois notificações — dois tiles com
    // o mesmo título (n1 não lida em negrito, n2 lida em peso normal).
    expect(find.text('Cotação de Plano — Comercial'), findsOneWidget);
    expect(find.text('Nova factura gerada'), findsNWidgets(2));
    // Badge do header = não lidas (1 mensagem + 1 notificação). A pílula
    // do filtro "Não lidas" mostra a mesma contagem → 2 instâncias.
    expect(find.text('2'), findsNWidgets(2));
    // Botão "marcar todas" visível com não lidas.
    expect(find.text('Marcar todas como lidas'), findsOneWidget);
  });

  testWidgets('filtro "Não lidas" esconde as lidas; "Todas" restaura', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([
          _notification(id: 'n1'),
          _notification(
            id: 'n2',
            isRead: true,
            createdAt: DateTime(2026, 9, 1),
          ),
        ]),
        messageRepo: _FakeAdminMessageRepository([_message(isRead: true)]),
      ),
    );
    await tester.pumpAndSettle();

    // Todas: 3 itens (1 mensagem + 2 notificações).
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Nova factura gerada'), findsNWidgets(2));

    // Não lidas: só a notificação não lida (1 título no tile).
    await tester.tap(find.text('Não lidas').first);
    await tester.pumpAndSettle();
    expect(find.text('Nova factura gerada'), findsOneWidget);
    expect(find.text('Cotação de Plano — Comercial'), findsNothing);
  });

  testWidgets('tocar no tile não lido abre o detalhe e marca como lida', (
    tester,
  ) async {
    _useWideViewport(tester);
    final notificationRepo = _FakeNotificationRepository([_notification()]);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: notificationRepo,
        messageRepo: _FakeAdminMessageRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova factura gerada'));
    await tester.pumpAndSettle();

    // Bottom sheet de detalhes com o corpo completo (corpo no tile + no
    // sheet → 2 instâncias).
    expect(
      find.text('Factura INV-00001 no valor de 990,00 MT'),
      findsNWidgets(2),
    );
    // Marcada como lida ao abrir.
    expect(notificationRepo.markOneCalls, 1);
    expect(notificationRepo.lastMarkedId, 'n1');

    // Fecha tocando na barreira.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    // Só o tile continua (o sheet fechou) — corpo volta a 1 instância.
    expect(
      find.text('Factura INV-00001 no valor de 990,00 MT'),
      findsOneWidget,
    );
  });

  testWidgets("botão done_all marca a notificação como lida sem abrir", (
    tester,
  ) async {
    _useWideViewport(tester);
    final notificationRepo = _FakeNotificationRepository([_notification()]);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: notificationRepo,
        messageRepo: _FakeAdminMessageRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.done_all_outlined));
    await tester.pumpAndSettle();

    expect(notificationRepo.markOneCalls, 1);
    // Detalhe NÃO abriu — o corpo aparece só no tile (1 instância).
    expect(
      find.text('Factura INV-00001 no valor de 990,00 MT'),
      findsOneWidget,
    );
  });

  testWidgets('"Marcar todas como lidas" chama os dois repositórios', (
    tester,
  ) async {
    _useWideViewport(tester);
    final notificationRepo = _FakeNotificationRepository([_notification()]);
    final messageRepo = _FakeAdminMessageRepository([_message()]);
    await tester.pumpWidget(
      _buildApp(notificationRepo: notificationRepo, messageRepo: messageRepo),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar todas como lidas'));
    await tester.pumpAndSettle();

    expect(notificationRepo.markAllCalls, 1);
    expect(messageRepo.markAllCalls, 1);
  });

  testWidgets('cada tipo renderiza o ícone e o rótulo correctos', (
    tester,
  ) async {
    _useWideViewport(tester);
    final notificationRepo = _FakeNotificationRepository([
      _notification(id: 'n1', type: InvoiceNotificationType.invoiceGenerated),
      _notification(id: 'n2', type: InvoiceNotificationType.invoiceDueSoon),
      _notification(id: 'n3', type: InvoiceNotificationType.invoiceExpired),
      _notification(id: 'n4', type: InvoiceNotificationType.invoicePaid),
      _notification(id: 'n5', type: InvoiceNotificationType.addOnExpiringSoon),
      _notification(id: 'n6', type: InvoiceNotificationType.addOnExpired),
    ]);
    final messageRepo = _FakeAdminMessageRepository([
      _message(id: 'm1', type: AdminMessageType.billingQuote),
      _message(id: 'm2', type: AdminMessageType.planExpiryChange),
      _message(id: 'm3', type: AdminMessageType.planExpiringSoon),
      _message(id: 'm4', type: AdminMessageType.general),
    ]);
    await tester.pumpWidget(
      _buildApp(notificationRepo: notificationRepo, messageRepo: messageRepo),
    );
    await tester.pumpAndSettle();

    // Ícones por tipo — cada braço do switch dos helpers.
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat_outlined), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.extension_off_outlined), findsOneWidget);

    // Rótulos localizados (pt) por tipo.
    expect(find.text('Cotação'), findsOneWidget);
    expect(find.text('Validade'), findsOneWidget);
    expect(find.text('Expira'), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Factura'), findsOneWidget);
    expect(find.text('Vence'), findsOneWidget);
    expect(find.text('Expirada'), findsOneWidget);
    expect(find.text('Paga'), findsOneWidget);
    expect(find.text('A expirar'), findsOneWidget);
    expect(find.text('Expirado'), findsOneWidget);
  });

  testWidgets('detalhe da mensagem do admin marca como lida e exibe o sheet', (
    tester,
  ) async {
    _useWideViewport(tester);
    final messageRepo = _FakeAdminMessageRepository([
      _message(id: 'm1', type: AdminMessageType.planExpiringSoon),
    ]);
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([]),
        messageRepo: messageRepo,
      ),
    );
    await tester.pumpAndSettle();

    // when — abre o detalhe da mensagem do admin.
    await tester.tap(find.text('Cotação de Plano — Comercial'));
    await tester.pumpAndSettle();

    // then — sheet com o corpo completo (tile + sheet → 2 instâncias) e
    // marcação de leitura no repositório.
    expect(
      find.text('Segue a cotação para renovação do seu plano.'),
      findsNWidgets(2),
    );
    expect(messageRepo.markOneCalls, 1);
  });

  testWidgets('data relativa: ontem e dias atrás nos tiles', (tester) async {
    _useWideViewport(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([
          _notification(
            id: 'n1',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          _notification(
            id: 'n2',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          _notification(
            id: 'n3',
            createdAt: now.subtract(const Duration(days: 1, hours: 1)),
          ),
        ]),
        messageRepo: _FakeAdminMessageRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    // then — rótulos pt de tempo relativo: "Ontem" e "3 dias atrás".
    expect(find.text('Ontem'), findsWidgets);
    expect(find.textContaining('dias atrás'), findsOneWidget);
  });

  testWidgets('data relativa: minutos e agora mesmo', (tester) async {
    _useWideViewport(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      _buildApp(
        notificationRepo: _FakeNotificationRepository([
          _notification(id: 'n1', createdAt: now),
          _notification(
            id: 'n2',
            createdAt: now.subtract(const Duration(minutes: 5)),
          ),
        ]),
        messageRepo: _FakeAdminMessageRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    // then — "Agora mesmo" e "há 5 min" (formato do header, ARB pt:
    // dashboardActivityMinutesAgo = "há {count} min").
    expect(find.text('Agora mesmo'), findsWidgets);
    expect(find.textContaining('5 min'), findsOneWidget);
  });
}

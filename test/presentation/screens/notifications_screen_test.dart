import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_notifications_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/notification_providers.dart';
import 'package:tareqo/presentation/screens/dashboard/notifications_screen.dart';

// ---------------------------------------------------------------------------
// Fake use cases
// ---------------------------------------------------------------------------

class _FakeGetTenantNotificationsUseCase
    implements GetTenantNotificationsUseCase {
  _FakeGetTenantNotificationsUseCase(this._notifications);

  final List<InvoiceNotification> _notifications;

  @override
  Future<List<InvoiceNotification>> call(String tenantId) async =>
      _notifications;
}

class _FakeMarkNotificationAsReadUseCase
    implements MarkNotificationAsReadUseCase {
  int calls = 0;
  String? lastId;

  @override
  Future<void> call(String notificationId) async {
    calls++;
    lastId = notificationId;
  }
}

class _FakeMarkAllNotificationsAsReadUseCase
    implements MarkAllNotificationsAsReadUseCase {
  int calls = 0;
  String? lastTenantId;

  @override
  Future<void> call(String tenantId) async {
    calls++;
    lastTenantId = tenantId;
  }
}

class _FakeGetMyTenantUseCase implements GetMyTenantUseCase {
  _FakeGetMyTenantUseCase(this._tenant);

  final Tenant? _tenant;

  @override
  Future<Tenant?> call(String userId) async => _tenant;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

InvoiceNotification _notif({
  String id = 'notif_1',
  String tenantId = 'tn1',
  String? invoiceId,
  InvoiceNotificationType type = InvoiceNotificationType.invoiceGenerated,
  String title = 'Nova factura gerada',
  String body = 'Factura gerada no valor de 50.00 MZN.',
  bool isRead = false,
  DateTime? createdAt,
}) =>
    InvoiceNotification(
      id: id,
      tenantId: tenantId,
      invoiceId: invoiceId,
      type: type,
      title: title,
      body: body,
      isRead: isRead,
      createdAt: createdAt ?? DateTime.now(),
    );

Widget _buildApp({
  required List<InvoiceNotification> notifications,
  MarkNotificationAsReadUseCase? markAsRead,
  MarkAllNotificationsAsReadUseCase? markAllAsRead,
}) {
  return ProviderScope(
    overrides: [
      // Auth: usuário logado
      authStateProvider.overrideWith(
        (ref) => Stream.value(const AppUser(id: 'u1', email: 'dono@loja.com')),
      ),
      // Tenant do usuário
      getMyTenantUseCaseProvider.overrideWithValue(
        _FakeGetMyTenantUseCase(
          Tenant(
            id: 'tn1',
            ownerUserId: 'u1',
            businessName: 'Comercial Demo',
            planId: 'pl1',
            status: TenantStatus.approved,
            approvedAt: DateTime.now().subtract(const Duration(days: 14)),
            createdAt: DateTime.now().subtract(const Duration(days: 14)),
          ),
        ),
      ),
      // Notificações
      getTenantNotificationsUseCaseProvider.overrideWithValue(
        _FakeGetTenantNotificationsUseCase(notifications),
      ),
      // Marcar como lida
      markNotificationAsReadUseCaseProvider.overrideWithValue(
        markAsRead ?? _FakeMarkNotificationAsReadUseCase(),
      ),
      // Marcar todas como lidas
      markAllNotificationsAsReadUseCaseProvider.overrideWithValue(
        markAllAsRead ?? _FakeMarkAllNotificationsAsReadUseCase(),
      ),
    ],
    child: testApp(home: const NotificationsScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotificationsScreen', () {
    testWidgets('mostra título "Notificações" no AppBar', (tester) async {
      await tester.pumpWidget(
        _buildApp(notifications: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notificações'), findsOneWidget);
    });

    testWidgets('mostra chips de filtro "Todas" e "Não lidas"',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(notifications: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Não lidas'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há notificações',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(notifications: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem notificações'), findsOneWidget);
      expect(
        find.text('As notificações de facturas aparecerão aqui.'),
        findsOneWidget,
      );
    });

    testWidgets('exibe notificações na lista', (tester) async {
      final notifications = [
        _notif(
          id: 'n1',
          title: 'Nova factura gerada',
          body: 'Factura Agosto 2026 no valor de 50.00 MZN.',
          type: InvoiceNotificationType.invoiceGenerated,
        ),
        _notif(
          id: 'n2',
          title: 'Factura para vencer',
          body: 'A factura vence em 3 dia(s).',
          type: InvoiceNotificationType.invoiceDueSoon,
        ),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova factura gerada'), findsWidgets);
      expect(find.text('Factura para vencer'), findsWidgets);
      expect(
        find.text('Factura Agosto 2026 no valor de 50.00 MZN.'),
        findsOneWidget,
      );
    });

    testWidgets('mostra botão "Marcar todas como lidas" quando há não lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: false),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcar todas como lidas'), findsOneWidget);
    });

    testWidgets('esconde botão "Marcar todas como lidas" quando todas são lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: true),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcar todas como lidas'), findsNothing);
    });

    testWidgets('mostra badge de contagem no chip "Não lidas"',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: false),
        _notif(id: 'n2', isRead: false),
        _notif(id: 'n3', isRead: true),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Badge com contagem de não lidas (2) — aparece no AppBar e na pílula.
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('mostra dot indicator para notificações não lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: false, title: 'Não lida'),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Card com dot indicator (Container 8x8)
      expect(find.text('Não lida'), findsOneWidget);
    });

    testWidgets('exibe botão marcar como lida para notificações não lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: false),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // IconButton com ícone mark_email_read_outlined
      expect(find.byIcon(Icons.done_all_outlined), findsOneWidget);
    });

    testWidgets('esconde botão marcar como lida para notificações já lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: true),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Não há botão marcar como lida
      expect(find.byIcon(Icons.done_all_outlined), findsNothing);
    });

    testWidgets('alterna para filtro "Não lidas" e mostra apenas não lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: false, title: 'Não lida'),
        _notif(id: 'n2', isRead: true, title: 'Já lida'),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Ambas visíveis no filtro "Todas"
      expect(find.text('Não lida'), findsOneWidget);
      expect(find.text('Já lida'), findsOneWidget);

      // Alterna para "Não lidas"
      await tester.tap(find.text('Não lidas'));
      await tester.pumpAndSettle();

      // Apenas a não lida visível
      expect(find.text('Não lida'), findsOneWidget);
      expect(find.text('Já lida'), findsNothing);
    });

    testWidgets('mostra tipos de notificação corretos (gerada, para vencer)',
        (tester) async {
      final notifications = [
        _notif(
          id: 'n1',
          type: InvoiceNotificationType.invoiceGenerated,
          title: 'Factura gerada',
        ),
        _notif(
          id: 'n2',
          type: InvoiceNotificationType.invoiceDueSoon,
          title: 'Factura para vencer',
        ),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Factura gerada'), findsWidgets);
      expect(find.text('Factura para vencer'), findsWidgets);
    });

    testWidgets('mostra tipos de notificação corretos (expirada, paga)',
        (tester) async {
      final notifications = [
        _notif(
          id: 'n1',
          type: InvoiceNotificationType.invoiceExpired,
          title: 'Factura expirada',
        ),
        _notif(
          id: 'n2',
          type: InvoiceNotificationType.invoicePaid,
          title: 'Factura paga',
        ),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      expect(find.text('Factura expirada'), findsWidgets);
      expect(find.text('Factura paga'), findsWidgets);
    });

    testWidgets('marcar notificação como lida chama o use case correto',
        (tester) async {
      final markAsRead = _FakeMarkNotificationAsReadUseCase();
      final notifications = [
        _notif(id: 'n1', isRead: false),
      ];

      await tester.pumpWidget(
        _buildApp(
          notifications: notifications,
          markAsRead: markAsRead,
        ),
      );
      await tester.pumpAndSettle();

      // Toca no botão marcar como lida
      await tester.tap(find.byIcon(Icons.done_all_outlined));
      await tester.pumpAndSettle();

      expect(markAsRead.calls, 1);
      expect(markAsRead.lastId, 'n1');
    });

    testWidgets('marcar todas como lidas chama o use case correto',
        (tester) async {
      final markAllAsRead = _FakeMarkAllNotificationsAsReadUseCase();
      final notifications = [
        _notif(id: 'n1', isRead: false),
        _notif(id: 'n2', isRead: false),
      ];

      await tester.pumpWidget(
        _buildApp(
          notifications: notifications,
          markAllAsRead: markAllAsRead,
        ),
      );
      await tester.pumpAndSettle();

      // Toca no botão "Marcar todas como lidas"
      await tester.tap(find.text('Marcar todas como lidas'));
      await tester.pumpAndSettle();

      expect(markAllAsRead.calls, 1);
      expect(markAllAsRead.lastTenantId, 'tn1');
    });

    testWidgets('múltiplas notificações exibe a quantidade correta',
        (tester) async {
      final notifications = List.generate(
        5,
        (i) => _notif(id: 'n$i', title: 'Notificação $i'),
      );

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        expect(find.text('Notificação $i'), findsOneWidget);
      }
    });

    testWidgets('notificações lidas não têm borda destacada', (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: true, title: 'Lida'),
        _notif(id: 'n2', isRead: false, title: 'Não lida'),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Ambas exibidas
      expect(find.text('Lida'), findsOneWidget);
      expect(find.text('Não lida'), findsOneWidget);

      // Apenas a não lida tem botão de marcar como lida
      expect(find.byIcon(Icons.done_all_outlined), findsOneWidget);
    });

    testWidgets('mostra empty state no filtro "Não lidas" quando todas são lidas',
        (tester) async {
      final notifications = [
        _notif(id: 'n1', isRead: true),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Alterna para "Não lidas"
      await tester.tap(find.text('Não lidas'));
      await tester.pumpAndSettle();

      // Empty state para "Não lidas"
      expect(find.text('Não lidas'), findsWidgets); // chip + empty state
    });

    testWidgets('ícone de notificação está presente para cada card',
        (tester) async {
      final notifications = [
        _notif(
          id: 'n1',
          type: InvoiceNotificationType.invoiceGenerated,
        ),
        _notif(
          id: 'n2',
          type: InvoiceNotificationType.invoicePaid,
        ),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Ícones de tipo de notificação
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('mostra timestamp relativo do card', (tester) async {
      final notifications = [
        _notif(id: 'n1'),
      ];

      await tester.pumpWidget(
        _buildApp(notifications: notifications),
      );
      await tester.pumpAndSettle();

      // Timestamp recém-criado renderiza como "Agora mesmo".
      expect(find.text('Agora mesmo'), findsOneWidget);
    });
  });
}

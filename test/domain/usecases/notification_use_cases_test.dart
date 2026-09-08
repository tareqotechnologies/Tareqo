import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/repositories/i_invoice_notification_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/usecases/get_tenant_notifications_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/notify_invoice_generated_use_case.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeInvoiceNotificationRepository
    implements IInvoiceNotificationRepository {
  final List<InvoiceNotification> _notifications = [];
  bool createCalled = false;
  bool markAsReadCalled = false;
  bool markAllAsReadCalled = false;

  @override
  Future<InvoiceNotification> create(InvoiceNotification notification) async {
    createCalled = true;
    final created = notification.copyWith(
      id: notification.id.isEmpty
          ? 'notif_${_notifications.length + 1}'
          : notification.id,
    );
    _notifications.add(created);
    return created;
  }

  @override
  Future<List<InvoiceNotification>> getByTenant(String tenantId) async =>
      List.unmodifiable(
        _notifications.where((n) => n.tenantId == tenantId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) async =>
      List.unmodifiable(
        _notifications
            .where((n) => n.tenantId == tenantId && !n.isRead)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<int> getUnreadCount(String tenantId) async =>
      _notifications.where((n) => n.tenantId == tenantId && !n.isRead).length;

  @override
  Future<void> markAsRead(String notificationId) async {
    markAsReadCalled = true;
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    markAllAsReadCalled = true;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].tenantId == tenantId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> delete(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
  }
}

class _FakePlanRepository implements IPlanRepository {
  final List<Plan> _plans = [];

  void addPlan(Plan plan) => _plans.add(plan);

  @override
  Future<List<Plan>> getActivePlans() async =>
      List.unmodifiable(_plans.where((p) => p.isActive));

  @override
  Future<List<Plan>> getAllPlans() async => List.unmodifiable(_plans);

  @override
  Future<Plan?> getById(String id) async {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Future<void> add(Plan plan) async => _plans.add(plan);

  @override
  Future<void> update(Plan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) _plans[index] = plan;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Plan _basicPlan({
  String id = 'pl1',
  String name = 'Essencial',
  int priceMonthlyCents = 5000,
}) => Plan(id: id, name: name, priceMonthlyCents: priceMonthlyCents);

Invoice _basicInvoice({
  String id = 'inv1',
  String tenantId = 'tn1',
  String planId = 'pl1',
  int amountCents = 5000,
  InvoiceStatus status = InvoiceStatus.pending,
  DateTime? dueDate,
}) {
  final now = DateTime.now();
  return Invoice(
    id: id,
    tenantId: tenantId,
    planId: planId,
    amountCents: amountCents,
    status: status,
    dueDate: dueDate ?? now.add(const Duration(days: 7)),
    period: 'Agosto 2026',
    createdAt: now,
  );
}

InvoiceNotification _notif({
  String id = 'notif_1',
  String tenantId = 'tn1',
  String? invoiceId,
  InvoiceNotificationType type = InvoiceNotificationType.invoiceGenerated,
  String title = 'Nova factura gerada',
  String body = 'Factura gerada',
  bool isRead = false,
  DateTime? createdAt,
}) => InvoiceNotification(
  id: id,
  tenantId: tenantId,
  invoiceId: invoiceId,
  type: type,
  title: title,
  body: body,
  isRead: isRead,
  createdAt: createdAt ?? DateTime.now(),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotifyInvoiceGeneratedUseCase', () {
    test('cria notificação quando factura é gerada e plano existe', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.call(invoice);

      expect(notification, isNotNull);
      expect(notification!.tenantId, 'tn1');
      expect(notification.invoiceId, 'inv1');
      expect(notification.type, InvoiceNotificationType.invoiceGenerated);
      expect(notification.title, isNotEmpty);
      expect(notification.body, contains('50.00'));
      expect(notification.body, contains('MZN'));
      expect(notifRepo.createCalled, isTrue);
      expect(notifRepo._notifications, hasLength(1));
    });

    test('retorna null quando plano não existe', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      // Não adiciona nenhum plano

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.call(invoice);

      expect(notification, isNull);
      expect(notifRepo.createCalled, isFalse);
    });

    test('notifyDueSoon cria notificação de factura para vencer', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice(
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );

      final notification = await useCase.notifyDueSoon(invoice);

      expect(notification, isNotNull);
      expect(notification!.type, InvoiceNotificationType.invoiceDueSoon);
      expect(notification.title, contains('vencer'));
      expect(notification.body, contains('dia(s)'));
    });

    test('notifyDueSoon retorna null quando plano não existe', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.notifyDueSoon(invoice);

      expect(notification, isNull);
    });

    test('notifyExpired cria notificação de factura expirada', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice(
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final notification = await useCase.notifyExpired(invoice);

      expect(notification, isNotNull);
      expect(notification!.type, InvoiceNotificationType.invoiceExpired);
      expect(notification.title, contains('expirada'));
    });

    test('notifyExpired retorna null quando plano não existe', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.notifyExpired(invoice);

      expect(notification, isNull);
    });

    test('notifyPaid cria notificação de factura paga', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice(status: InvoiceStatus.paid);

      final notification = await useCase.notifyPaid(invoice);

      expect(notification, isNotNull);
      expect(notification!.type, InvoiceNotificationType.invoicePaid);
      expect(notification.title, contains('paga'));
    });

    test('notifyPaid retorna null quando plano não existe', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.notifyPaid(invoice);

      expect(notification, isNull);
    });

    test('inclui valor formatado no corpo da notificação', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice(amountCents: 10000);

      final notification = await useCase.call(invoice);

      expect(notification, isNotNull);
      expect(notification!.body, contains('100.00'));
    });

    test('inclui período no corpo da notificação', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();

      final notification = await useCase.call(invoice);

      expect(notification, isNotNull);
      expect(notification!.body, contains(invoice.period));
    });

    test('inclui data de vencimento na notificação', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      final useCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final dueDate = DateTime(2026, 9, 15);
      final invoice = _basicInvoice(dueDate: dueDate);

      final notification = await useCase.call(invoice);

      expect(notification, isNotNull);
      expect(notification!.body, contains('15/9/2026'));
    });
  });

  group('GetTenantNotificationsUseCase', () {
    test('retorna notificações de um tenant específico', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      // Adiciona notificações de dois tenants
      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', createdAt: DateTime.now()),
        _notif(id: 'n2', tenantId: 'tn2', createdAt: DateTime.now()),
        _notif(
          id: 'n3',
          tenantId: 'tn1',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);

      final useCase = GetTenantNotificationsUseCase(notifRepo);
      final result = await useCase('tn1');

      expect(result, hasLength(2));
      expect(result.every((n) => n.tenantId == 'tn1'), isTrue);
    });

    test('retorna lista vazia quando tenant não tem notificações', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      final useCase = GetTenantNotificationsUseCase(notifRepo);
      final result = await useCase('tn_inexistente');

      expect(result, isEmpty);
    });

    test('retorna notificações ordenadas por data desc', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final now = DateTime.now();

      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', createdAt: now),
        _notif(
          id: 'n2',
          tenantId: 'tn1',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        _notif(
          id: 'n3',
          tenantId: 'tn1',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ]);

      final useCase = GetTenantNotificationsUseCase(notifRepo);
      final result = await useCase('tn1');

      expect(result, hasLength(3));
      expect(result[0].id, 'n1'); // Mais recente primeiro
      expect(result[1].id, 'n3');
      expect(result[2].id, 'n2');
    });
  });

  group('MarkNotificationAsReadUseCase', () {
    test('marca notificação como lida', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      notifRepo._notifications.add(
        _notif(id: 'n1', tenantId: 'tn1', isRead: false),
      );

      final useCase = MarkNotificationAsReadUseCase(notifRepo);
      await useCase('n1');

      expect(notifRepo.markAsReadCalled, isTrue);
      expect(notifRepo._notifications.first.isRead, isTrue);
      expect(notifRepo._notifications.first.readAt, isNotNull);
    });

    test('marca apenas a notificação correta como lida', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', isRead: false),
        _notif(id: 'n2', tenantId: 'tn1', isRead: false),
      ]);

      final useCase = MarkNotificationAsReadUseCase(notifRepo);
      await useCase('n1');

      expect(notifRepo._notifications[0].isRead, isTrue);
      expect(notifRepo._notifications[1].isRead, isFalse);
    });
  });

  group('MarkAllNotificationsAsReadUseCase', () {
    test('marca todas as notificações de um tenant como lidas', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', isRead: false),
        _notif(id: 'n2', tenantId: 'tn1', isRead: false),
        _notif(id: 'n3', tenantId: 'tn1', isRead: true),
        _notif(id: 'n4', tenantId: 'tn2', isRead: false), // Outro tenant
      ]);

      final useCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await useCase('tn1');

      expect(notifRepo.markAllAsReadCalled, isTrue);
      // tn1: todas marcadas como lidas
      expect(notifRepo._notifications[0].isRead, isTrue);
      expect(notifRepo._notifications[1].isRead, isTrue);
      expect(notifRepo._notifications[2].isRead, isTrue); // Já estava lida
      // tn2: continua não lida (outro tenant)
      expect(notifRepo._notifications[3].isRead, isFalse);
    });

    test('não altera notificações já lidas', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      final readAt = DateTime(2026, 8, 28);
      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', isRead: true, createdAt: readAt),
      ]);

      final useCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await useCase('tn1');

      expect(notifRepo.markAllAsReadCalled, isTrue);
      // A notificação já lida continua com os mesmos dados
      expect(notifRepo._notifications[0].isRead, isTrue);
    });

    test('funciona quando não há notificações para marcar', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      final useCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await useCase('tn_sem_notifs');

      expect(notifRepo.markAllAsReadCalled, isTrue);
      expect(notifRepo._notifications, isEmpty);
    });

    test('marca todas as notificações (pendentes e já lidas)', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();

      notifRepo._notifications.addAll([
        _notif(id: 'n1', tenantId: 'tn1', isRead: false),
        _notif(id: 'n2', tenantId: 'tn1', isRead: false),
      ]);

      final useCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await useCase('tn1');

      final allRead = notifRepo._notifications.every((n) => n.isRead);
      expect(allRead, isTrue);

      final allHaveReadAt = notifRepo._notifications.every(
        (n) => n.readAt != null,
      );
      expect(allHaveReadAt, isTrue);
    });
  });

  group('Integração — fluxo completo de notificação', () {
    test('factura gerada → notificação criada → marca como lida', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      // 1. Gera notificação de factura
      final notifyUseCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();
      final notification = await notifyUseCase.call(invoice);

      expect(notification, isNotNull);
      expect(notifRepo._notifications, hasLength(1));
      expect(notifRepo._notifications.first.isRead, isFalse);

      // 2. Lista notificações do tenant
      final getUseCase = GetTenantNotificationsUseCase(notifRepo);
      final notifications = await getUseCase('tn1');
      expect(notifications, hasLength(1));

      // 3. Marca como lida
      final markUseCase = MarkNotificationAsReadUseCase(notifRepo);
      await markUseCase(notification!.id);

      expect(notifRepo._notifications.first.isRead, isTrue);
      expect(notifRepo._notifications.first.readAt, isNotNull);
    });

    test('múltiplas notificações → marca todas como lidas', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      // Gera múltiplas notificações
      final notifyUseCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();
      await notifyUseCase.call(invoice);
      await notifyUseCase.notifyDueSoon(invoice);
      await notifyUseCase.notifyExpired(invoice);

      expect(notifRepo._notifications, hasLength(3));

      // Marca todas como lidas
      final markAllUseCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await markAllUseCase('tn1');

      final allRead = notifRepo._notifications.every((n) => n.isRead);
      expect(allRead, isTrue);
    });

    test('contagem de não lidas diminui após marcar como lida', () async {
      final notifRepo = _FakeInvoiceNotificationRepository();
      final planRepo = _FakePlanRepository();
      planRepo.addPlan(_basicPlan());

      // Gera 3 notificações
      final notifyUseCase = NotifyInvoiceGeneratedUseCase(notifRepo, planRepo);
      final invoice = _basicInvoice();
      final n1 = await notifyUseCase.call(invoice);
      await notifyUseCase.notifyDueSoon(invoice);
      await notifyUseCase.notifyExpired(invoice);

      // Contagem inicial
      var unreadCount = await notifRepo.getUnreadCount('tn1');
      expect(unreadCount, 3);

      // Marca uma como lida
      final markUseCase = MarkNotificationAsReadUseCase(notifRepo);
      await markUseCase(n1!.id);

      unreadCount = await notifRepo.getUnreadCount('tn1');
      expect(unreadCount, 2);

      // Marca todas como lidas
      final markAllUseCase = MarkAllNotificationsAsReadUseCase(notifRepo);
      await markAllUseCase('tn1');

      unreadCount = await notifRepo.getUnreadCount('tn1');
      expect(unreadCount, 0);
    });
  });
}

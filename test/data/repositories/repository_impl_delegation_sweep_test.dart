import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/admin_message_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/audit_log_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/cash_closing_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/customer_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/employee_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/employee_management_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/invoice_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/invoice_notification_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/plan_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/plan_request_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/purchase_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/stock_lot_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/store_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/tenant_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/admin_message_repository_impl.dart';
import 'package:tareqo/data/repositories/audit_log_repository_impl.dart';
import 'package:tareqo/data/repositories/cash_closing_repository_impl.dart';
import 'package:tareqo/data/repositories/customer_repository_impl.dart';
import 'package:tareqo/data/repositories/employee_management_repository_impl.dart';
import 'package:tareqo/data/repositories/employee_repository_impl.dart';
import 'package:tareqo/data/repositories/invoice_notification_repository_impl.dart';
import 'package:tareqo/data/repositories/invoice_repository_impl.dart';
import 'package:tareqo/data/repositories/plan_repository_impl.dart';
import 'package:tareqo/data/repositories/plan_request_repository_impl.dart';
import 'package:tareqo/data/repositories/purchase_repository_impl.dart';
import 'package:tareqo/data/repositories/stock_lot_repository_impl.dart';
import 'package:tareqo/data/repositories/store_repository_impl.dart';
import 'package:tareqo/data/repositories/tenant_repository_impl.dart';
import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';

/// Sweep dos `*RepositoryImpl` de DELEGAÇÃO sobre datasources locais em
/// memória — cada método do repositório é exercitado pelo menos uma vez e
/// o efeito é conferido NO datasource (a lista delega, o estado fica).
void main() {
  group('TenantRepositoryImpl', () {
    final tenant = Tenant(
      id: 'tn1',
      ownerUserId: 'u1',
      businessName: 'Padaria Central',
      planId: 'pl1',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 8, 1),
    );
    final repo = TenantRepositoryImpl(
      TenantLocalDataSourceImpl(seed: [tenant], employeeUserIds: ['u2']),
    );

    test('getMyTenant resolve dono e funcionário, null para fora', () async {
      expect(await repo.getMyTenant('u1'), same(tenant));
      expect(await repo.getMyTenant('u2'), same(tenant));
      expect(await repo.getMyTenant('u3'), isNull);
    });

    test('getById/getPending/getAll delegam', () async {
      expect((await repo.getById('tn1'))?.id, 'tn1');
      expect((await repo.getById('tnX')), isNull);
      expect(await repo.getPending(), isEmpty);
      expect(await repo.getAll(), hasLength(1));
    });

    test('requestAccess cria tenant pendente', () async {
      final created = await repo.requestAccess(
        ownerUserId: 'u9',
        businessName: 'Nova Loja',
        planId: 'pl1',
        currencyCode: 'MZN',
        language: 'pt',
      );
      expect(created.businessName, 'Nova Loja');
      expect(created.currencyCode, 'MZN');
      expect(await repo.getPending(), hasLength(1));
    });

    test(
      'updateSettings/approve/reject/updatePlan/updateBilling aplicam',
      () async {
        await repo.updateSettings('tn1', currencyCode: 'BRL', language: 'en');
        expect((await repo.getById('tn1'))!.currencyCode, 'BRL');

        await repo.updatePlan('tn1', 'pl2');
        expect((await repo.getById('tn1'))!.planId, 'pl2');

        await repo.updateBilling(
          'tn1',
          planExpiresAt: DateTime(2026, 10, 1),
          nextInvoiceAt: DateTime(2026, 9, 24),
        );
        final billed = await repo.getById('tn1');
        expect(billed!.planExpiresAt, DateTime(2026, 10, 1));
        expect(billed.nextInvoiceAt, DateTime(2026, 9, 24));

        final requested = await repo.requestAccess(
          ownerUserId: 'u8',
          businessName: 'Outra',
          planId: 'pl1',
          currencyCode: 'MZN',
          language: 'pt',
        );
        await repo.reject(requested.id, 'Documentos incompletos');
        final rejected = await repo.getById(requested.id);
        expect(rejected!.status, TenantStatus.rejected);
        expect(rejected.rejectionReason, 'Documentos incompletos');

        await repo.approve('tn1');
        expect((await repo.getById('tn1'))!.status, TenantStatus.approved);
      },
    );
  });

  group('InvoiceRepositoryImpl', () {
    final repo = InvoiceRepositoryImpl(InvoiceLocalDataSourceImpl());

    test('ciclo completo: create → pending → markAsPaid → cancel', () async {
      final invoice = await repo.create(
        Invoice(
          id: 'inv-1',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 9900,
          dueDate: DateTime(2026, 10, 1),
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      expect(invoice.number, 1);

      await repo.create(
        Invoice(
          id: 'inv-2',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 9900,
          dueDate: DateTime(2026, 11, 1),
          createdAt: DateTime(2026, 9, 2),
        ),
      );

      expect(await repo.getByTenant('tn1'), hasLength(2));
      expect(await repo.getPending(), hasLength(2));
      expect(await repo.getAll(), hasLength(2));
      expect(await repo.hasPendingForPeriod('tn1', 'Setembro 2026'), isFalse);

      await repo.markAsPaid('inv-1');
      expect(await repo.getPending(), hasLength(1));

      await repo.cancel('inv-2');
      expect(await repo.getPending(), isEmpty);
    });
  });

  group('InvoiceNotificationRepositoryImpl', () {
    final repo = InvoiceNotificationRepositoryImpl(
      InvoiceNotificationLocalDataSourceImpl(),
    );

    InvoiceNotification build(String id, {String tenantId = 'tn1'}) =>
        InvoiceNotification(
          id: id,
          tenantId: tenantId,
          type: InvoiceNotificationType.invoiceGenerated,
          title: 'Factura gerada',
          body: 'INV-00001',
          createdAt: DateTime(2026, 9, 1),
        );

    test('create/getByTenant/getUnread*/mark*/delete', () async {
      await repo.create(build('n1'));
      await repo.create(build('n2'));
      await repo.create(build('n3', tenantId: 'tn2'));

      expect(await repo.getByTenant('tn1'), hasLength(2));
      expect(await repo.getUnreadByTenant('tn1'), hasLength(2));
      expect(await repo.getUnreadCount('tn1'), 2);

      await repo.markAsRead('n1');
      expect(await repo.getUnreadCount('tn1'), 1);

      await repo.markAllAsRead('tn1');
      expect(await repo.getUnreadCount('tn1'), 0);
      expect(await repo.getUnreadCount('tn2'), 1);

      await repo.delete('n2');
      expect(await repo.getByTenant('tn1'), hasLength(1));
    });
  });

  group('PlanRepositoryImpl', () {
    final repo = PlanRepositoryImpl(PlanLocalDataSourceImpl());

    test('add/getActivePlans/getAllPlans/getById/update', () async {
      const plan = Plan(
        id: 'pl1',
        name: 'Básico',
        priceMonthlyCents: 4990,
        maxStores: 2,
        maxEmployees: 5,
      );
      await repo.add(plan);

      expect(await repo.getActivePlans(), hasLength(1));
      expect(await repo.getAllPlans(), hasLength(1));
      expect((await repo.getById('pl1'))?.name, 'Básico');

      await repo.update(plan.copyWith(isActive: false, name: 'Básico antigo'));
      expect(await repo.getActivePlans(), isEmpty);
      expect((await repo.getById('pl1'))!.isActive, isFalse);
    });
  });

  group('PlanRequestRepositoryImpl', () {
    final repo = PlanRequestRepositoryImpl(PlanRequestLocalDataSourceImpl());

    test('create/getByTenant/getPending/decide', () async {
      final request = await repo.create(
        tenantId: 'tn1',
        currentPlanId: 'pl1',
        requestedPlanId: 'pl3',
      );
      expect(request.status, PlanRequestStatus.pending);
      expect(await repo.getByTenant('tn1'), hasLength(1));
      expect(await repo.getPending(), hasLength(1));
      expect((await repo.getById(request.id))?.requestedPlanId, 'pl3');

      await repo.decide(request.id, approve: true);
      expect(await repo.getPending(), isEmpty);
      expect(
        (await repo.getById(request.id))!.status,
        PlanRequestStatus.approved,
      );
    });
  });

  group('AdminMessageRepositoryImpl', () {
    final repo = AdminMessageRepositoryImpl(AdminMessageLocalDataSourceImpl());

    test(
      'create/getByTenant/getUnreadCount/markAsRead/markAllAsRead',
      () async {
        await repo.create(
          AdminMessage(
            id: 'm1',
            tenantId: 'tn1',
            type: AdminMessageType.billingQuote,
            title: 'Cotação',
            body: 'Pro por 2.500 MZN/mês',
            createdAt: DateTime(2026, 9, 1),
          ),
        );
        await repo.create(
          AdminMessage(
            id: 'm2',
            tenantId: 'tn1',
            type: AdminMessageType.general,
            title: 'Aviso',
            body: 'Manutenção',
            createdAt: DateTime(2026, 9, 2),
          ),
        );

        expect(await repo.getByTenant('tn1'), hasLength(2));
        expect(await repo.getUnreadCount('tn1'), 2);

        await repo.markAsRead('m1');
        expect(await repo.getUnreadCount('tn1'), 1);

        await repo.markAllAsRead('tn1');
        expect(await repo.getUnreadCount('tn1'), 0);
      },
    );
  });

  group('CustomerRepositoryImpl', () {
    final repo = CustomerRepositoryImpl(CustomerLocalDataSourceImpl());

    test('add/getAll/update/delete', () async {
      const customer = Customer(id: 'c1', name: 'Ana', phone: '841234567');
      await repo.add(customer);
      expect(await repo.getAll(storeId: 'st1'), hasLength(1));

      await repo.update(customer.copyWith(name: 'Ana Marques'));
      final updated = await repo.getAll(storeId: 'st1');
      expect(updated.first.name, 'Ana Marques');

      await repo.delete('c1');
      expect(await repo.getAll(storeId: 'st1'), isEmpty);
    });
  });

  group('EmployeeRepositoryImpl', () {
    final repo = EmployeeRepositoryImpl(EmployeeLocalDataSourceImpl());

    test('add/getByTenant/getByStore/setActive', () async {
      const employee = StoreEmployee(
        id: 'se1',
        tenantId: 'tn1',
        storeId: 'st1',
        userId: 'u2',
        fullName: 'Carlos',
        email: 'carlos@loja.co.mz',
      );
      await repo.add(employee);

      expect(await repo.getByTenant('tn1'), hasLength(1));
      expect(await repo.getByStore('st1'), hasLength(1));

      await repo.setActive(employeeId: 'se1', isActive: false);
      final stored = await repo.getByStore('st1');
      expect(stored.first.isActive, isFalse);
    });
  });

  group('StoreRepositoryImpl', () {
    final repo = StoreRepositoryImpl(StoreLocalDataSourceImpl());

    test('add/getByTenant/update', () async {
      const store = Store(
        id: 'st2',
        tenantId: 'tn1',
        name: 'Loja Baixa',
        city: 'Maputo',
      );
      await repo.add(store);

      expect(await repo.getByTenant('tn1'), hasLength(1));

      await repo.update(store.copyWith(name: 'Loja Baixa II'));
      expect((await repo.getByTenant('tn1')).first.name, 'Loja Baixa II');
    });
  });

  group('CashClosingRepositoryImpl', () {
    final repo = CashClosingRepositoryImpl(CashClosingLocalDataSourceImpl());

    test('save cria e substitui por dia; getByDay/getAll', () async {
      final closing = CashClosing(
        id: 'cc1',
        day: DateTime(2026, 9, 10),
        totalSalesCents: 150000,
        expectedCashCents: 90000,
        countedCashCents: 89500,
        closedAt: DateTime(2026, 9, 10, 20, 30),
      );
      await repo.save(closing);

      expect(
        await repo.getByDay(storeId: 'st1', day: DateTime(2026, 9, 10, 14)),
        isNotNull,
      );
      expect(await repo.getAll(storeId: 'st1'), hasLength(1));

      // Mesmo dia → o registro é SUBSTITUÍDO (não duplicado).
      await repo.save(closing.copyWith(countedCashCents: 90000));
      final all = await repo.getAll(storeId: 'st1');
      expect(all, hasLength(1));
      expect(all.first.countedCashCents, 90000);
    });
  });

  group('StockLotRepositoryImpl', () {
    // Repo novo por teste: o estado do grupo vazaría entre os casos.
    StockLotRepositoryImpl buildRepo() =>
        StockLotRepositoryImpl(StockLotLocalDataSourceImpl());

    StockLot lot(String id, int current, {DateTime? expiry}) => StockLot(
      id: id,
      productId: 'p1',
      entryDate: DateTime(2026, 9, 1),
      expiryDate: expiry,
      initialQuantity: 10000,
      currentQuantity: current,
      costPriceCents: 450000,
    );

    test('add/getActiveByProduct/getByStore FIFO por validade', () async {
      final repo = buildRepo();
      await repo.add(lot('lot-b', 5000, expiry: DateTime(2026, 10, 1)));
      await repo.add(lot('lot-a', 3000, expiry: DateTime(2026, 9, 20)));
      await repo.add(lot('lot-empty', 0, expiry: DateTime(2026, 9, 15)));

      final active = await repo.getActiveByProduct('p1', storeId: 'st1');
      expect(active.map((l) => l.id).toList(), ['lot-a', 'lot-b']);
      expect(await repo.getByStore(storeId: 'st1'), hasLength(2));
    });

    test('updateQuantity/increaseQuantity aplicam no lote', () async {
      final repo = buildRepo();
      await repo.add(lot('lot-1', 5000));
      await repo.updateQuantity('lot-1', 2000, storeId: 'st1');
      expect(
        (await repo.getByStore(storeId: 'st1')).first.currentQuantity,
        2000,
      );

      await repo.increaseQuantity('lot-1', 1500, storeId: 'st1');
      expect(
        (await repo.getByStore(storeId: 'st1')).first.currentQuantity,
        3500,
      );
    });
  });

  group('PurchaseRepositoryImpl', () {
    final repo = PurchaseRepositoryImpl(PurchaseLocalDataSourceImpl());

    test('add/getAll', () async {
      await repo.add(
        Purchase(
          id: 'pu1',
          supplierName: 'Distribuidora X',
          items: const [
            PurchaseItem(
              productId: 'p1',
              productName: 'Arroz',
              quantity: 10000,
              unitPriceCents: 450000,
            ),
          ],
          totalAmountCents: 450000,
          dateTime: DateTime(2026, 9, 1),
        ),
      );

      final purchases = await repo.getAll(storeId: 'st1');
      expect(purchases, hasLength(1));
      expect(purchases.first.supplierName, 'Distribuidora X');
    });
  });

  group('AuditLogRepositoryImpl', () {
    test('getAuditLog delega ao datasource local', () async {
      final repo = const AuditLogRepositoryImpl(AuditLogLocalDataSourceImpl());
      expect(await repo.getAuditLog(), isEmpty);
      expect(await repo.getAuditLog(limit: 5), isEmpty);
    });
  });

  group('EmployeeManagementRepositoryImpl', () {
    final repo = EmployeeManagementRepositoryImpl(
      EmployeeManagementLocalDataSourceImpl(),
    );

    test('clockIn/clockOut/getAttendance', () async {
      await repo.clockIn(
        storeId: 'st1',
        userId: 'u2',
        workDate: '2026-09-11',
        clockIn: DateTime(2026, 9, 11, 8),
        recordedBy: 'u1',
      );

      final attendance = await repo.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-11',
      );
      expect(attendance, hasLength(1));
      expect(attendance.first.userId, 'u2');

      await repo.clockOut(
        storeId: 'st1',
        userId: 'u2',
        workDate: '2026-09-11',
        clockOut: DateTime(2026, 9, 11, 17),
      );
      final closed = await repo.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-11',
      );
      expect(closed.first.clockOut, isNotNull);
    });

    test('setCommissionRate/getCommissionRates', () async {
      await repo.setCommissionRate(storeId: 'st1', userId: 'u2', rateBps: 500);
      final rates = await repo.getCommissionRates(storeId: 'st1');
      expect(rates, hasLength(1));
      expect(rates.first.rateBps, 500);
    });

    test('setTarget/getTargets/removeTarget', () async {
      await repo.setTarget(
        storeId: 'st1',
        userId: 'u2',
        month: '2026-09',
        targetCents: 100000,
      );
      final targets = await repo.getTargets(storeId: 'st1', month: '2026-09');
      expect(targets, hasLength(1));
      expect(targets.first.targetCents, 100000);

      await repo.removeTarget(targets.first.id, storeId: 'st1');
      expect(await repo.getTargets(storeId: 'st1'), isEmpty);
    });
  });
}

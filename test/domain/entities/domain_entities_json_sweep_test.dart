import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';

/// Sweep dos `fromJson` ainda não exercitados nas entidades de domínio.
///
/// Cada teste faz round-trip `toJson()` → `fromJson()` e confere os campos
/// que distinguem o caso (defaults, enums, datas nulas). Mesma convenção de
/// `domain_entities_misc_test.dart`.
void main() {
  group('AddOn / TenantAddOn', () {
    test('AddOn.fromJson round-trip preserva categoria e preço', () {
      const addOn = AddOn(
        id: 'ao1',
        name: 'Relatórios Avançados',
        description: 'PDFs avançados',
        category: AddOnCategory.reports,
        priceMonthlyCents: 2500,
      );

      final restored = AddOn.fromJson(addOn.toJson());

      expect(restored.id, 'ao1');
      expect(restored.category, AddOnCategory.reports);
      expect(restored.priceMonthlyCents, 2500);
      expect(restored.iconName, '');
      expect(restored.isAvailable, isTrue);
    });

    test('TenantAddOn.fromJson com e sem expiresAt', () {
      final activated = TenantAddOn(
        id: 'tao1',
        tenantId: 'tn1',
        addOnId: 'ao1',
        activatedAt: DateTime(2026, 9, 1),
      );
      final withExpiry = activated.copyWith(expiresAt: DateTime(2026, 10, 1));

      final restoredNoExpiry = TenantAddOn.fromJson(activated.toJson());
      final restoredWithExpiry = TenantAddOn.fromJson(withExpiry.toJson());

      expect(restoredNoExpiry.expiresAt, isNull);
      expect(restoredNoExpiry.isActive, isTrue);
      expect(restoredWithExpiry.expiresAt, DateTime(2026, 10, 1));
    });
  });

  group('AdminMessage', () {
    test(
      'fromJson round-trip de mensagem não lida (isRead/readAt defaults)',
      () {
        final message = AdminMessage(
          id: 'am1',
          tenantId: 'tn1',
          type: AdminMessageType.billingQuote,
          title: 'Cotação de Plano',
          body: 'Pro por 2.500 MZN/mês',
          createdAt: DateTime(2026, 9, 10, 9),
        );

        final restored = AdminMessage.fromJson(message.toJson());

        expect(restored.type, AdminMessageType.billingQuote);
        expect(restored.title, 'Cotação de Plano');
        expect(restored.isRead, isFalse);
        expect(restored.readAt, isNull);
        expect(restored.createdAt, message.createdAt);
      },
    );
  });

  group('AppUser', () {
    test('fromJson round-trip com fullName default', () {
      const user = AppUser(id: 'u1', email: 'dono@loja.co.mz');

      final restored = AppUser.fromJson(user.toJson());

      expect(restored.id, 'u1');
      expect(restored.email, 'dono@loja.co.mz');
      expect(restored.fullName, '');
    });
  });

  group('CashClosing', () {
    test('fromJson round-trip preserva o Z por forma de pagamento', () {
      final closing = CashClosing(
        id: 'cc1',
        day: DateTime(2026, 9, 10),
        totalSalesCents: 150000,
        expectedCashCents: 90000,
        countedCashCents: 89500,
        salesByMethodCents: const {'Dinheiro': 90000, 'M-Pesa': 60000},
        closedAt: DateTime(2026, 9, 10, 20, 30),
      );

      final restored = CashClosing.fromJson(closing.toJson());

      expect(restored.storeId, 'st1');
      expect(restored.totalSalesCents, 150000);
      expect(restored.salesByMethodCents, {'Dinheiro': 90000, 'M-Pesa': 60000});
      expect(restored.differenceCents, -500);
    });
  });

  group('Customer', () {
    test('fromJson round-trip com contactos', () {
      const customer = Customer(
        id: 'c1',
        name: 'Ana Marques',
        phone: '+258841234567',
        email: 'ana@exemplo.mz',
      );

      final restored = Customer.fromJson(customer.toJson());

      expect(restored.name, 'Ana Marques');
      expect(restored.storeId, 'st1');
      expect(restored.phone, '+258841234567');
      expect(restored.email, 'ana@exemplo.mz');
    });
  });

  group('Invoice', () {
    test('fromJson round-trip paga, com paidAt e notes', () {
      final invoice = Invoice(
        id: 'inv1',
        number: 7,
        tenantId: 'tn1',
        planId: 'pl1',
        amountCents: 29900,
        status: InvoiceStatus.paid,
        dueDate: DateTime(2026, 10, 1),
        period: 'Setembro 2026',
        paidAt: DateTime(2026, 9, 8, 14),
        notes: 'Pago por referência',
        createdAt: DateTime(2026, 9, 1),
      );

      final restored = Invoice.fromJson(invoice.toJson());

      expect(restored.number, 7);
      expect(restored.status, InvoiceStatus.paid);
      expect(restored.amountCents, 29900);
      expect(restored.paidAt, DateTime(2026, 9, 8, 14));
      expect(restored.notes, 'Pago por referência');
    });

    test('fromJson round-trip pendente (paidAt/notes nulos)', () {
      final invoice = Invoice(
        id: 'inv2',
        tenantId: 'tn1',
        planId: 'pl1',
        amountCents: 9900,
        dueDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 1),
      );

      final restored = Invoice.fromJson(invoice.toJson());

      expect(restored.status, InvoiceStatus.pending);
      expect(restored.paidAt, isNull);
      expect(restored.notes, isNull);
    });
  });

  group('InvoiceNotification', () {
    test('fromJson round-trip sem factura associada', () {
      final notification = InvoiceNotification(
        id: 'in1',
        tenantId: 'tn1',
        type: InvoiceNotificationType.addOnExpiringSoon,
        title: 'Add-on a expirar',
        body: 'Relatórios avançados expira em 3 dias',
        createdAt: DateTime(2026, 9, 9),
      );

      final restored = InvoiceNotification.fromJson(notification.toJson());

      expect(restored.type, InvoiceNotificationType.addOnExpiringSoon);
      expect(restored.invoiceId, isNull);
      expect(restored.isRead, isFalse);
      expect(restored.readAt, isNull);
    });
  });

  group('Plan', () {
    test('fromJson round-trip com add-ons incluídos', () {
      const plan = Plan(
        id: 'pl2',
        name: 'Profissional',
        description: 'Até 3 lojas',
        priceMonthlyCents: 9900,
        maxStores: 3,
        maxEmployees: 10,
        bundledAddOns: ['ao_advanced_reports'],
      );

      final restored = Plan.fromJson(plan.toJson());

      expect(restored.name, 'Profissional');
      expect(restored.priceMonthlyCents, 9900);
      expect(restored.maxStores, 3);
      expect(restored.bundledAddOns, ['ao_advanced_reports']);
      expect(restored.isActive, isTrue);
    });
  });

  group('PlanRequest', () {
    test('fromJson round-trip aprovado com decidedAt', () {
      final request = PlanRequest(
        id: 'pr1',
        tenantId: 'tn1',
        currentPlanId: 'pl1',
        requestedPlanId: 'pl3',
        status: PlanRequestStatus.approved,
        decidedAt: DateTime(2026, 9, 9, 11),
        createdAt: DateTime(2026, 9, 8),
      );

      final restored = PlanRequest.fromJson(request.toJson());

      expect(restored.status, PlanRequestStatus.approved);
      expect(restored.currentPlanId, 'pl1');
      expect(restored.requestedPlanId, 'pl3');
      expect(restored.decidedAt, DateTime(2026, 9, 9, 11));
    });
  });

  group('Product', () {
    test('fromJson round-trip de granel (vendaPorFracao + unitLabel)', () {
      const product = Product(
        id: 'p1',
        name: 'Arroz Txitxiri',
        purchasePriceCents: 450000,
        salePriceCents: 600000,
        stockQuantity: 17500,
        code: '20 10011',
        vendaPorFracao: true,
        unitLabel: 'kg',
      );

      final restored = Product.fromJson(product.toJson());

      expect(restored.name, 'Arroz Txitxiri');
      expect(restored.stockQuantity, 17500);
      expect(restored.vendaPorFracao, isTrue);
      expect(restored.unitLabel, 'kg');
      expect(restored.isActive, isTrue);
      expect(restored.imagePath, '');
    });

    test('fromJson preserva o tipo do produto (round-trip)', () {
      const product = Product(
        id: 'p1',
        name: 'Farinha de trigo',
        purchasePriceCents: 450000,
        salePriceCents: 600000,
        type: ProductType.rawMaterial,
      );

      final restored = Product.fromJson(product.toJson());

      expect(restored.type, ProductType.rawMaterial);
    });

    test('fromJson tolera tipo desconhecido → resale (nunca lança)', () {
      // Simula um payload gravado por uma versão mais nova do app: o valor
      // do enum não existe neste build. Mesma tolerância dos datasources
      // SQLite/Supabase (firstWhere(...orElse: resale)) — não pode quebrar.
      final json = <String, dynamic>{
        'id': 'p1',
        'name': 'Produto do futuro',
        'purchasePriceCents': 100,
        'salePriceCents': 200,
        'type': 'tipoDeVersaoFutura',
      };

      final restored = Product.fromJson(json);

      expect(restored.type, ProductType.resale);
    });
  });

  group('StockLot', () {
    test('fromJson round-trip sem validade (FIFO por entrada)', () {
      final lot = StockLot(
        id: 'lot1',
        productId: 'p1',
        entryDate: DateTime(2026, 9, 1),
        initialQuantity: 10000,
        currentQuantity: 4000,
        costPriceCents: 450000,
      );

      final restored = StockLot.fromJson(lot.toJson());

      expect(restored.productId, 'p1');
      expect(restored.entryDate, DateTime(2026, 9, 1));
      expect(restored.expiryDate, isNull);
      expect(restored.currentQuantity, 4000);
      expect(restored.costPriceCents, 450000);
    });
  });

  group('Store', () {
    test('fromJson round-trip com NUIT e cidade', () {
      const store = Store(
        id: 'st1',
        tenantId: 'tn1',
        name: 'Loja Baixa',
        address: 'Av. 24 de Julho, 1200',
        phone: '+258842345678',
        nuit: '400123456',
        city: 'Maputo',
      );

      final restored = Store.fromJson(store.toJson());

      expect(restored.name, 'Loja Baixa');
      expect(restored.nuit, '400123456');
      expect(restored.city, 'Maputo');
      expect(restored.email, '');
    });
  });

  group('StoreEmployee', () {
    test('fromJson round-trip de gerente desativado', () {
      const employee = StoreEmployee(
        id: 'se1',
        tenantId: 'tn1',
        storeId: 'st1',
        userId: 'u2',
        fullName: 'Carlos Silva',
        email: 'carlos@loja.co.mz',
        role: EmployeeRole.manager,
        isActive: false,
      );

      final restored = StoreEmployee.fromJson(employee.toJson());

      expect(restored.fullName, 'Carlos Silva');
      expect(restored.role, EmployeeRole.manager);
      expect(restored.isActive, isFalse);
    });
  });

  group('Tenant', () {
    test('fromJson round-trip rejeitado com motivo', () {
      final tenant = Tenant(
        id: 'tn1',
        ownerUserId: 'u1',
        businessName: 'Padaria Central',
        planId: 'pl1',
        status: TenantStatus.rejected,
        rejectionReason: 'Documentos incompletos',
        createdAt: DateTime(2026, 8, 30),
      );

      final restored = Tenant.fromJson(tenant.toJson());

      expect(restored.businessName, 'Padaria Central');
      expect(restored.status, TenantStatus.rejected);
      expect(restored.rejectionReason, 'Documentos incompletos');
      expect(restored.currencyCode, 'MZN');
      expect(restored.language, 'pt');
    });
  });
}

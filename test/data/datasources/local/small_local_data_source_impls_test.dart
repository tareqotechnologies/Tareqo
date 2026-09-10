import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/cash_closing_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/customer_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/employee_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/plan_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/plan_request_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/purchase_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/store_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;

void main() {
  group('CashClosingLocalDataSourceImpl (memória)', () {
    CashClosing buildClosing(
      String id, {
      String storeId = 'st1',
      DateTime? day,
      int counted = 1000,
      int expected = 1000,
    }) => CashClosing(
      id: id,
      storeId: storeId,
      day: day ?? DateTime(2026, 8, 16),
      totalSalesCents: 5000,
      expectedCashCents: expected,
      countedCashCents: counted,
      closedAt: DateTime(2026, 8, 16, 18),
    );

    test('save insere e getByDay devolve o fecho do dia', () async {
      final ds = CashClosingLocalDataSourceImpl();
      await ds.save(buildClosing('z1'));

      final closing = await ds.getByDay(
        storeId: 'st1',
        day: DateTime(2026, 8, 16),
      );
      expect(closing!.id, 'z1');
    });

    test('getByDay ignora a HORA (unicidade por loja + dia)', () async {
      final ds = CashClosingLocalDataSourceImpl();
      await ds.save(buildClosing('z1', day: DateTime(2026, 8, 16, 18, 30)));

      final closing = await ds.getByDay(
        storeId: 'st1',
        day: DateTime(2026, 8, 16, 9),
      );
      expect(closing!.id, 'z1');
    });

    test(
      'save do MESMO dia é UPSERT (corrige contagem, não duplica)',
      () async {
        final ds = CashClosingLocalDataSourceImpl();
        await ds.save(buildClosing('z1', counted: 900));

        // Refazer o fecho do dia (recontagem física) atualiza o registro.
        await ds.save(buildClosing('z2', counted: 1000));

        final all = await ds.getAll(storeId: 'st1');
        expect(all, hasLength(1));
        expect(all.single.id, 'z2');
        expect(all.single.countedCashCents, 1000);
      },
    );

    test('getByDay de dia sem fecho devolve null', () async {
      final ds = CashClosingLocalDataSourceImpl();
      expect(
        await ds.getByDay(storeId: 'st1', day: DateTime(2026, 8, 10)),
        isNull,
      );
    });

    test('getAll isola por loja e ordena MAIS RECENTE primeiro', () async {
      final ds = CashClosingLocalDataSourceImpl();
      await ds.save(buildClosing('z-antigo', day: DateTime(2026, 8, 15)));
      await ds.save(buildClosing('z-outra', storeId: 'st2'));
      await ds.save(buildClosing('z-hoje', day: DateTime(2026, 8, 16)));

      final all = await ds.getAll(storeId: 'st1');

      expect(all.map((c) => c.id), ['z-hoje', 'z-antigo']);
    });
  });

  group('CustomerLocalDataSourceImpl (memória)', () {
    Customer buildCustomer(
      String id, {
      String storeId = 'st1',
      String name = 'Ana',
    }) => Customer(id: id, storeId: storeId, name: name);

    test(
      'add + getAll filtra por loja e ordena por nome (case-insensitive)',
      () async {
        final ds = CustomerLocalDataSourceImpl();
        await ds.add(buildCustomer('c1', name: 'carla'));
        await ds.add(buildCustomer('c2', name: 'Bruno'));
        await ds.add(buildCustomer('c3', name: 'ana'));
        await ds.add(buildCustomer('c4', storeId: 'st2'));

        final customers = await ds.getAll(storeId: 'st1');

        expect(customers.map((c) => c.id), ['c3', 'c2', 'c1']);
      },
    );

    test('update substitui o registro', () async {
      final ds = CustomerLocalDataSourceImpl();
      await ds.add(buildCustomer('c1'));

      await ds.update(buildCustomer('c1', name: 'Ana Maria'));

      final customers = await ds.getAll(storeId: 'st1');
      expect(customers.single.name, 'Ana Maria');
    });

    test('update de cliente inexistente é no-op (não cria)', () async {
      final ds = CustomerLocalDataSourceImpl();
      await ds.add(buildCustomer('c1'));

      await ds.update(buildCustomer('fantasma'));

      expect(await ds.getAll(storeId: 'st1'), hasLength(1));
    });

    test('delete remove só o cliente pedido', () async {
      final ds = CustomerLocalDataSourceImpl();
      await ds.add(buildCustomer('c1'));
      await ds.add(buildCustomer('c2'));

      await ds.delete('c1');

      expect((await ds.getAll(storeId: 'st1')).map((c) => c.id), ['c2']);
    });
  });

  group('StoreLocalDataSourceImpl (memória)', () {
    Store buildStore(String id, {String tenantId = 'tn1'}) =>
        Store(id: id, tenantId: tenantId, name: 'Loja $id');

    test('getByTenant filtra as lojas do tenant', () async {
      final ds = StoreLocalDataSourceImpl();
      await ds.add(buildStore('s1'));
      await ds.add(buildStore('s2', tenantId: 'tn2'));

      expect((await ds.getByTenant('tn1')).map((s) => s.id), ['s1']);
      expect(await ds.getByTenant('fantasma'), isEmpty);
    });

    test('add + update', () async {
      final ds = StoreLocalDataSourceImpl();
      await ds.add(buildStore('s1'));

      await ds.update(
        buildStore('s1', tenantId: 'tn1').copyWith(name: 'Matriz'),
      );

      final stores = await ds.getByTenant('tn1');
      expect(stores.single.name, 'Matriz');
    });

    test('update de loja inexistente é no-op', () async {
      final ds = StoreLocalDataSourceImpl();
      await ds.add(buildStore('s1'));

      await ds.update(buildStore('fantasma'));

      expect(await ds.getByTenant('tn1'), hasLength(1));
    });
  });

  group('EmployeeLocalDataSourceImpl (memória)', () {
    StoreEmployee buildEmployee(
      String id, {
      String storeId = 'st1',
      String tenantId = 'tn1',
    }) => StoreEmployee(
      id: id,
      tenantId: tenantId,
      storeId: storeId,
      userId: 'u-$id',
      fullName: 'Func $id',
      email: '$id@x.com',
    );

    test('getByTenant e getByStore filtram corretamente', () async {
      final ds = EmployeeLocalDataSourceImpl();
      await ds.add(buildEmployee('e1'));
      await ds.add(buildEmployee('e2', storeId: 'st2'));
      await ds.add(buildEmployee('e3', tenantId: 'tn2', storeId: 'st3'));

      expect((await ds.getByTenant('tn1')).map((e) => e.id), ['e1', 'e2']);
      expect((await ds.getByStore('st1')).map((e) => e.id), ['e1']);
    });

    test('setActive desativa e reativa o vínculo', () async {
      final ds = EmployeeLocalDataSourceImpl();
      await ds.add(buildEmployee('e1'));

      await ds.setActive(employeeId: 'e1', isActive: false);
      expect((await ds.getByTenant('tn1')).single.isActive, isFalse);

      await ds.setActive(employeeId: 'e1', isActive: true);
      expect((await ds.getByTenant('tn1')).single.isActive, isTrue);
    });

    test('setActive de inexistente é no-op (não lança)', () async {
      final ds = EmployeeLocalDataSourceImpl();
      await expectLater(
        ds.setActive(employeeId: 'fantasma', isActive: false),
        completes,
      );
    });
  });

  group('PlanLocalDataSourceImpl (memória)', () {
    Plan buildPlan(
      String id, {
      int price = 9900,
      bool active = true,
      int maxStores = 2,
    }) => Plan(
      id: id,
      name: 'Plano $id',
      priceMonthlyCents: price,
      maxStores: maxStores,
      isActive: active,
    );

    test('getActivePlans devolve só ativos, ordenados por preço', () async {
      final ds = PlanLocalDataSourceImpl();
      await ds.add(buildPlan('pl-b', price: 19900));
      await ds.add(buildPlan('pl-a', price: 4900));
      await ds.add(buildPlan('pl-off', active: false));

      expect((await ds.getActivePlans()).map((p) => p.id), ['pl-a', 'pl-b']);
    });

    test('getAllPlans inclui inativos, ordenados por preço', () async {
      final ds = PlanLocalDataSourceImpl();
      await ds.add(buildPlan('pl-b', price: 19900));
      await ds.add(buildPlan('pl-a', price: 4900));

      expect((await ds.getAllPlans()).map((p) => p.id), ['pl-a', 'pl-b']);
    });

    test('add de id DUPLICADO lança StateError (protege PK)', () async {
      final ds = PlanLocalDataSourceImpl();
      await ds.add(buildPlan('pl-a'));

      await expectLater(ds.add(buildPlan('pl-a')), throwsA(isA<StateError>()));
    });

    test('update substitui e falha para inexistente', () async {
      final ds = PlanLocalDataSourceImpl();
      await ds.add(buildPlan('pl-a', price: 4900));

      await ds.update(buildPlan('pl-a', price: 7900));
      expect((await ds.getById('pl-a'))!.priceMonthlyCents, 7900);

      await expectLater(
        ds.update(buildPlan('fantasma')),
        throwsA(isA<StateError>()),
      );
    });

    test('getById devolve null para desconhecido', () async {
      final ds = PlanLocalDataSourceImpl();
      expect(await ds.getById('fantasma'), isNull);
    });
  });

  group('PlanRequestLocalDataSourceImpl (memória)', () {
    test('create nasce PENDING com id gerado', () async {
      final ds = PlanRequestLocalDataSourceImpl();

      final request = await ds.create(
        tenantId: 'tn1',
        currentPlanId: 'pl_starter',
        requestedPlanId: 'pl_pro',
      );

      expect(request.status, PlanRequestStatus.pending);
      expect(request.id, startsWith('pr'));
      expect((await ds.getById(request.id))!.status, PlanRequestStatus.pending);
    });

    test('decide(approve: true/false) transiciona e carimba a data', () async {
      final ds = PlanRequestLocalDataSourceImpl();
      final a = await ds.create(
        tenantId: 'tn1',
        currentPlanId: 'pl_starter',
        requestedPlanId: 'pl_pro',
      );
      final b = await ds.create(
        tenantId: 'tn1',
        currentPlanId: 'pl_starter',
        requestedPlanId: 'pl_max',
      );

      await ds.decide(a.id, approve: true);
      await ds.decide(b.id, approve: false);

      expect((await ds.getById(a.id))!.status, PlanRequestStatus.approved);
      expect((await ds.getById(a.id))!.decidedAt, isNotNull);
      expect((await ds.getById(b.id))!.status, PlanRequestStatus.rejected);
    });

    test('decide de inexistente lança StateError', () async {
      final ds = PlanRequestLocalDataSourceImpl();
      await expectLater(
        ds.decide('fantasma', approve: true),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'getPending devolve só pendentes; getByTenant ordena recente 1º',
      () async {
        final ds = PlanRequestLocalDataSourceImpl(
          seed: [
            PlanRequest(
              id: 'pr1',
              tenantId: 'tn1',
              currentPlanId: 'pl_starter',
              requestedPlanId: 'pl_pro',
              status: PlanRequestStatus.approved,
              createdAt: DateTime(2026, 8, 1),
            ),
            PlanRequest(
              id: 'pr2',
              tenantId: 'tn1',
              currentPlanId: 'pl_starter',
              requestedPlanId: 'pl_pro',
              createdAt: DateTime(2026, 8, 10),
            ),
          ],
        );

        expect((await ds.getPending()).map((r) => r.id), ['pr2']);
        expect((await ds.getByTenant('tn1')).map((r) => r.id), ['pr2', 'pr1']);
        expect(await ds.getById('fantasma'), isNull);
      },
    );
  });

  group('ProductLocalDataSourceImpl (memória)', () {
    Product buildProduct(
      String id, {
      String storeId = 'st1',
      int stock = 100,
    }) => Product(
      id: id,
      storeId: storeId,
      name: 'Prod $id',
      purchasePriceCents: 500,
      salePriceCents: 900,
      stockQuantity: stock,
    );

    test(
      'getAll ordena por nome (case-insensitive) e filtra por loja',
      () async {
        final ds = ProductLocalDataSourceImpl();
        await ds.add(buildProduct('p2', stock: 1));
        await ds.add(buildProduct('p1', stock: 2));
        await ds.add(buildProduct('p3', storeId: 'st2'));

        final products = await ds.getAll(storeId: 'st1');
        expect(products.map((p) => p.id), ['p1', 'p2']);
      },
    );

    test('getById escopa por loja (outra loja não vê)', () async {
      final ds = ProductLocalDataSourceImpl();
      await ds.add(buildProduct('p1', storeId: 'st1'));

      expect((await ds.getById('p1', storeId: 'st1'))!.id, 'p1');
      expect(await ds.getById('p1', storeId: 'st2'), isNull);
    });

    test(
      'update preserva o ESTOQUE (mutação só via FifoStockUseCase)',
      () async {
        final ds = ProductLocalDataSourceImpl();
        await ds.add(buildProduct('p1', stock: 777));

        // update carregando um stockQuantity DIFERENTE — deve ser ignorado.
        await ds.update(
          buildProduct('p1', stock: 999).copyWith(name: 'Novo nome'),
        );

        final product = await ds.getById('p1', storeId: 'st1');
        expect(product!.name, 'Novo nome');
        expect(product.stockQuantity, 777);
      },
    );

    test('update de produto DE OUTRA LOJA lança StateError', () async {
      final ds = ProductLocalDataSourceImpl();
      await ds.add(buildProduct('p1', storeId: 'st1'));

      await expectLater(
        ds.update(buildProduct('p1', storeId: 'st2')),
        throwsA(isA<StateError>()),
      );
    });

    test('updateStock grava valor absoluto e falha fora da loja', () async {
      final ds = ProductLocalDataSourceImpl();
      await ds.add(buildProduct('p1', stock: 100));

      await ds.updateStock('p1', 55, storeId: 'st1');
      expect((await ds.getById('p1', storeId: 'st1'))!.stockQuantity, 55);

      await expectLater(
        ds.updateStock('p1', 0, storeId: 'st2'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('PurchaseLocalDataSourceImpl (memória)', () {
    Purchase buildPurchase(String id, {String storeId = 'st1'}) => Purchase(
      id: id,
      storeId: storeId,
      supplierName: 'Fornecedor X',
      items: const [],
      totalAmountCents: 15000,
      paymentMethod: PaymentMethod.cash,
      dateTime: DateTime(2026, 8, 16),
    );

    test('add + getAll filtra por loja', () async {
      final ds = PurchaseLocalDataSourceImpl();
      await ds.add(buildPurchase('pc1'));
      await ds.add(buildPurchase('pc2', storeId: 'st2'));

      expect((await ds.getAll(storeId: 'st1')).map((p) => p.id), ['pc1']);
      expect((await ds.getAll(storeId: 'st2')).map((p) => p.id), ['pc2']);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/domain/entities/audit_entry.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/approve_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_audit_log_use_case.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/domain/usecases/reject_tenant_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/addon_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_tenants_screen.dart';

class _FakeGetPendingTenantsUseCase implements GetPendingTenantsUseCase {
  _FakeGetPendingTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<Tenant>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha pendentes');
    return _tenants;
  }
}

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<Tenant>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha todos');
    return _tenants;
  }
}

class _FakeApproveTenantUseCase implements ApproveTenantUseCase {
  int calls = 0;
  String? lastTenantId;

  /// IDs para os quais a aprovação falha (erro parcial em lote).
  Set<String> throwFor = const {};

  @override
  Future<void> call(String tenantId) async {
    calls++;
    lastTenantId = tenantId;
    if (throwFor.contains(tenantId)) {
      throw Exception('falha ao aprovar');
    }
  }
}

class _FakeRejectTenantUseCase implements RejectTenantUseCase {
  int calls = 0;
  String? lastTenantId;
  String? lastReason;

  /// IDs para os quais a rejeição falha (erro parcial em lote).
  Set<String> throwFor = const {};

  @override
  Future<void> call(String tenantId, String reason) async {
    calls++;
    lastTenantId = tenantId;
    lastReason = reason;
    if (throwFor.contains(tenantId)) {
      throw Exception('falha ao rejeitar');
    }
  }
}

class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
  _FakeGetAllPlansUseCase(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

class _FakeGetStoresUseCase implements GetStoresUseCase {
  _FakeGetStoresUseCase(this._stores);

  final List<Store> _stores;

  @override
  Future<List<Store>> call(String tenantId) async => _stores;
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
  _FakeGetEmployeesUseCase(this._employees);

  final List<StoreEmployee> _employees;

  @override
  Future<List<StoreEmployee>> call(String tenantId) async => _employees;
}

class _FakeGetAuditLogUseCase implements GetAuditLogUseCase {
  _FakeGetAuditLogUseCase(this._entries);

  final List<AuditEntry> _entries;

  @override
  Future<List<AuditEntry>> call({int limit = 100}) async => _entries;
}

/// Backend de add-ons em memória — os widgets consultam
/// `tenantActiveAddOnIdsProvider` via `addOnDataSourceProvider`.
class _FakeAddOnDataSource implements AddOnLocalDataSource {
  _FakeAddOnDataSource([Set<String>? active]) : _active = {...?active};

  final Set<String> _active;

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async => {..._active};

  @override
  Future<void> activate(String tenantId, String addOnId) async {
    _active.add(addOnId);
  }

  @override
  Future<void> deactivate(String tenantId, String addOnId) async {
    _active.remove(addOnId);
  }

  @override
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  }) async {}

  @override
  Future<bool> isActive(String tenantId, String addOnId) async =>
      _active.contains(addOnId);

  @override
  Future<List<TenantAddOn>> getByTenant(String tenantId) async => const [];

  @override
  Future<int> deactivateExpired() async => 0;

  @override
  Future<List<TenantAddOn>> getExpired() async => const [];
}

const _defaultPlans = [
  Plan(id: 'pl1', name: 'Essencial', priceMonthlyCents: 2990),
  Plan(id: 'pl2', name: 'Comercial', priceMonthlyCents: 9900),
];

/// ownerUserId com ≥8 caracteres: o sheet de detalhes faz
/// `substring(0, 8)` — IDs curtos estouram (RangeError).
Tenant _pendingTenant({String id = 'tn1', String name = 'Comercial Demo'}) =>
    Tenant(
      id: id,
      ownerUserId: 'owner12345',
      businessName: name,
      planId: 'pl2',
      status: TenantStatus.pending,
      createdAt: DateTime(2026, 8, 1),
    );

Widget _buildApp({
  required List<Tenant> pending,
  required List<Tenant> all,
  ApproveTenantUseCase? approve,
  RejectTenantUseCase? reject,
  List<Plan> plans = _defaultPlans,
  List<Store> stores = const [],
  List<StoreEmployee> employees = const [],
  List<AuditEntry> auditLog = const [],
  _FakeAddOnDataSource? addOns,
  _FakeGetPendingTenantsUseCase? pendingUseCase,
  _FakeGetAllTenantsUseCase? allUseCase,
}) {
  return ProviderScope(
    overrides: [
      getPendingTenantsUseCaseProvider.overrideWithValue(
        pendingUseCase ?? _FakeGetPendingTenantsUseCase(pending),
      ),
      getAllTenantsUseCaseProvider.overrideWithValue(
        allUseCase ?? _FakeGetAllTenantsUseCase(all),
      ),
      approveTenantUseCaseProvider.overrideWithValue(
        approve ?? _FakeApproveTenantUseCase(),
      ),
      rejectTenantUseCaseProvider.overrideWithValue(
        reject ?? _FakeRejectTenantUseCase(),
      ),
      getAllPlansUseCaseProvider.overrideWithValue(
        _FakeGetAllPlansUseCase(plans),
      ),
      getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase(stores)),
      getEmployeesUseCaseProvider.overrideWithValue(
        _FakeGetEmployeesUseCase(employees),
      ),
      getAuditLogUseCaseProvider.overrideWithValue(
        _FakeGetAuditLogUseCase(auditLog),
      ),
      if (addOns != null) addOnDataSourceProvider.overrideWithValue(addOns),
    ],
    child: testApp(
      home: const AdminTenantsScreen(),
      // A fonte de teste (Ahem) é mais larga que a Outfit de produção — o
      // sheet de detalhes (limitado a 640px pelo framework) estoura Rows
      // de texto longo. Clamp de escala compensa sem afetar as asserções.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.8, child: child!),
    ),
  );
}

/// Viewport largo e alto (1250×1600): a fonte de teste (Ahem) é bem mais
/// larga que a Outfit de produção — 400px estoura Rows de cards/barras e
/// ~560px estoura o header de seção do sheet de detalhes.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Rola o ListView do DraggableScrollableSheet até [target] ficar visível.
Future<void> _scrollSheetUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final scrollable = find
      .descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 12 && !tester.any(target); i++) {
    await tester.drag(scrollable, const Offset(0, -420));
    await tester.pumpAndSettle();
  }
  expect(tester.any(target), isTrue);
}

void main() {
  testWidgets('exibe os tenants pendentes com contagem', (tester) async {
    _useWideViewport(tester);
    final pending = [
      _pendingTenant(name: 'Comercial Demo'),
      _pendingTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    expect(find.text('2 aguardando aprovação'), findsOneWidget);
    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Aprovar'), findsNWidgets(2));
    expect(find.text('Rejeitar'), findsNWidgets(2));
  });

  testWidgets('mostra estado vazio quando não há pendentes', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(pending: const [], all: const []));
    await tester.pumpAndSettle();
    expect(find.text('Nada pendente'), findsOneWidget);
    expect(find.text('Novas solicitações aparecem aqui.'), findsOneWidget);
  });

  testWidgets('aprovar chama o ApproveTenantUseCase e atualiza', (
    tester,
  ) async {
    _useWideViewport(tester);
    final approve = _FakeApproveTenantUseCase();
    final pending = [_pendingTenant()];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, approve: approve),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(approve.calls, 1);
    expect(approve.lastTenantId, 'tn1');
    expect(find.text('Acesso de Comercial Demo aprovado!'), findsOneWidget);
  });

  testWidgets('rejeitar pede o motivo e chama o RejectTenantUseCase', (
    tester,
  ) async {
    _useWideViewport(tester);
    final reject = _FakeRejectTenantUseCase();
    final pending = [_pendingTenant()];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, reject: reject),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeitar'));
    await tester
        .pumpAndSettle(); // Diálogo de motivo — procura o TextField dentro do diálogo.
    expect(find.text('Rejeitar Comercial Demo'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Documentação incompleta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rejeitar'));
    await tester.pumpAndSettle();

    expect(reject.calls, 1);
    expect(reject.lastTenantId, 'tn1');
    expect(reject.lastReason, 'Documentação incompleta');
    expect(
      find.text('Solicitação de Comercial Demo rejeitada.'),
      findsOneWidget,
    );
  });

  testWidgets('alterna para a lista de todos os tenants', (tester) async {
    _useWideViewport(tester);
    final approved = Tenant(
      id: 'tn3',
      ownerUserId: 'owner22222',
      businessName: 'Farmácia Vida',
      planId: 'pl1',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 7, 10),
    );

    await tester.pumpWidget(_buildApp(pending: const [], all: [approved]));
    await tester.pumpAndSettle();

    // Alterna para "Todos".
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Aprovado'), findsOneWidget);
  });

  testWidgets('busca filtra pendentes e o botão de limpar restaura', (
    tester,
  ) async {
    _useWideViewport(tester);
    final pending = [
      _pendingTenant(name: 'Comercial Demo'),
      _pendingTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();

    // Badge de contagem do resultado + apenas o tenant filtrado.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Comercial Demo'), findsNothing);

    // Limpar a busca restaura a lista completa. O ✕ do campo de busca tem
    // size 16 — o ícone do botão "Rejeitar" dos cards também é Icons.close
    // (sem size), então filtramos pelo tamanho.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.close && w.size == 16,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('seleção múltipla: long press, marcar todos e aprovar em lote', (
    tester,
  ) async {
    _useWideViewport(tester);
    final approve = _FakeApproveTenantUseCase();
    final pending = [
      _pendingTenant(name: 'Comercial Demo'),
      _pendingTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, approve: approve),
    );
    await tester.pumpAndSettle();

    // Long press entra no modo seleção com o card tocado marcado.
    await tester.longPress(find.text('Comercial Demo'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));

    // Checkbox do segundo card complementa a seleção.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Desmarcar todos'), findsOneWidget);

    await tester.tap(find.text('Aprovar (2)'));
    await tester.pumpAndSettle();

    expect(approve.calls, 2);
    expect(find.text('2 tenants aprovados'), findsOneWidget);
    // Barra de seleção some (modo encerrado).
    expect(find.text('2 / 2'), findsNothing);
  });

  testWidgets('card aprovado mostra nome do plano, data e badge de add-ons', (
    tester,
  ) async {
    _useWideViewport(tester);
    final approved = Tenant(
      id: 'tn3',
      ownerUserId: 'owner22222',
      businessName: 'Farmácia Vida',
      planId: 'pl2',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 8, 1),
    );

    await tester.pumpWidget(
      _buildApp(
        pending: const [],
        all: [approved],
        addOns: _FakeAddOnDataSource({'ao_custom_invoice', 'ao_quotation'}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Aprovado'), findsOneWidget);
    expect(find.text('Comercial · 1/8/2026'), findsOneWidget);
    // Badge de add-ons activos (2 IDs no datasource falso).
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('copiar o ID do proprietário mostra snackbar', (tester) async {
    _useWideViewport(tester);
    final approved = Tenant(
      id: 'tn3',
      ownerUserId: 'owner22222',
      businessName: 'Farmácia Vida',
      planId: 'pl1',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 7, 10),
    );

    await tester.pumpWidget(_buildApp(pending: const [], all: [approved]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy).first);
    await tester.pumpAndSettle();

    expect(find.text('Copiado para a área de transferência'), findsOneWidget);
  });

  testWidgets('detalhe do tenant pendente: chips, infos e seções vazias', (
    tester,
  ) async {
    _useWideViewport(tester);
    final pending = [_pendingTenant()];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comercial Demo'));
    await tester.pumpAndSettle();

    // Header + chips de estado/plano.
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Pendente'), findsWidgets);
    expect(find.text('Plano'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);

    // Info rows — ownerUserId truncado a 8 caracteres, moeda e idioma.
    expect(find.text('ID do proprietário'), findsOneWidget);
    expect(find.text('owner123'), findsOneWidget);
    expect(find.text('MZN'), findsOneWidget);
    expect(find.text('PT'), findsOneWidget);

    // Copiar o owner ID via tap na linha.
    await tester.tap(find.text('owner123'));
    await tester.pumpAndSettle();
    expect(find.text('Copiado para a área de transferência'), findsOneWidget);

    // Seções vazias (sem lojas/funcionários/atividade).
    await _scrollSheetUntilVisible(tester, find.text('Funcionários'));
    expect(find.text('Nenhuma loja criada'), findsOneWidget);
    expect(find.text('Nenhum funcionário vinculado'), findsOneWidget);
    expect(
      find.text('Nenhuma atividade recente para este tenant'),
      findsOneWidget,
    );

    // Fechar o sheet tocando na barreira (fora do sheet) — arrastar até o
    // topo dispensaria o modal junto ( gesture de pull-to-dismiss).
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Estado'), findsNothing);
  });

  testWidgets('detalhe do tenant rejeitado mostra o motivo', (tester) async {
    _useWideViewport(tester);
    final rejected = Tenant(
      id: 'tn1',
      ownerUserId: 'owner1234',
      businessName: 'Mercado Central',
      planId: 'pl1',
      status: TenantStatus.rejected,
      rejectionReason: 'Documentação incompleta',
      createdAt: DateTime(2026, 8, 1),
    );

    await tester.pumpWidget(_buildApp(pending: const [], all: [rejected]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado Central'));
    await tester.pumpAndSettle();

    await _scrollSheetUntilVisible(
      tester,
      find.text('Documentação incompleta'),
    );
    expect(find.text('Motivo da rejeição'), findsOneWidget);
    expect(find.text('Documentação incompleta'), findsOneWidget);
    expect(find.text('Rejeitado'), findsWidgets);
  });

  testWidgets('detalhe do tenant aprovado: facturação, uso e seções', (
    tester,
  ) async {
    _useWideViewport(tester);
    final now = DateTime.now();
    final approved = Tenant(
      id: 'tn1',
      ownerUserId: 'owner1234',
      businessName: 'Farmácia Vida',
      planId: 'pl2',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 8, 1),
      approvedAt: now.subtract(const Duration(days: 30)),
      // +2h de folga: mantém inDays == 20 apesar do truncamento.
      planExpiresAt: now.add(const Duration(days: 20, hours: 2)),
      nextInvoiceAt: now.add(const Duration(days: 13, hours: 2)),
    );
    const plans = [
      Plan(
        id: 'pl2',
        name: 'Comercial',
        priceMonthlyCents: 9900,
        maxStores: 2,
        maxEmployees: 5,
      ),
    ];

    await tester.pumpWidget(
      _buildApp(
        pending: const [],
        all: [approved],
        plans: plans,
        stores: const [
          Store(
            id: 'st1',
            tenantId: 'tn1',
            name: 'Loja Centro',
            city: 'Maputo',
          ),
        ],
        employees: const [
          StoreEmployee(
            id: 'e1',
            tenantId: 'tn1',
            storeId: 'st1',
            userId: 'u1',
            fullName: 'Ana Silva',
            email: 'ana@farmaciavida.co.mz',
            role: EmployeeRole.manager,
          ),
        ],
        auditLog: [
          AuditEntry(
            id: 7,
            actorUserId: 'admin9',
            action: 'tenant_decision',
            entityType: 'tenants',
            entityId: 'tn1',
            detail: const {'status': 'approved'},
            createdAt: now,
          ),
          // Atividade de OUTRO tenant — deve ser filtrada fora do sheet.
          AuditEntry(
            id: 8,
            action: 'plan_change',
            entityType: 'plans',
            entityId: 'outro-tenant',
            createdAt: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Farmácia Vida'));
    await tester.pumpAndSettle();

    expect(find.text('Aprovado'), findsWidgets);

    // ── Ciclo de facturação (30d aprovado, 20d restantes → não é trial).
    await _scrollSheetUntilVisible(tester, find.text('FACTURAÇÃO'));
    expect(find.text('Activo: 20 dias restantes'), findsOneWidget);
    expect(find.text('Valor mensal'), findsOneWidget);
    expect(find.text('R\$ 99,00'), findsOneWidget);
    expect(find.text('Próxima factura'), findsOneWidget);

    // ── Uso vs limites do plano (1/2 lojas, 1/5 funcionários).
    await _scrollSheetUntilVisible(tester, find.text('USO vs LIMITES'));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    // ── Lojas e funcionários com dados.
    await _scrollSheetUntilVisible(tester, find.text('Loja Centro'));
    expect(find.text('1 loja'), findsOneWidget);
    expect(find.text('Maputo'), findsOneWidget);
    await _scrollSheetUntilVisible(tester, find.text('Ana Silva'));
    expect(find.text('1 funcionário'), findsOneWidget);
    expect(find.text('Gestor'), findsOneWidget);

    // ── Atividade recente filtrada por entityId do tenant.
    await _scrollSheetUntilVisible(tester, find.text('Tenant decision'));
    expect(find.text('1 ação recente'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    // Atividade de outro tenant NÃO aparece.
    expect(find.text('Plan change'), findsNothing);
  });

  testWidgets(
    'rejeição em lote pede o motivo e rejeita todos os selecionados',
    (tester) async {
      _useWideViewport(tester);
      final reject = _FakeRejectTenantUseCase();
      final pending = [
        _pendingTenant(name: 'Comercial Demo'),
        _pendingTenant(id: 'tn2', name: 'Mercado Central'),
      ];

      await tester.pumpWidget(
        _buildApp(pending: pending, all: pending, reject: reject),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Comercial Demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rejeitar (2)'));
      await tester.pumpAndSettle();

      // Diálogo de motivo em lote com o título com contagem.
      expect(find.text('Rejeitar 2 tenants'), findsOneWidget);
      expect(find.text('Motivo da rejeição'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Documentos falsificados',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Rejeitar'));
      await tester.pumpAndSettle();

      expect(reject.calls, 2);
      expect(reject.lastReason, 'Documentos falsificados');
      expect(find.text('2 tenants rejeitados'), findsOneWidget);
      // Modo de seleção encerrado.
      expect(find.text('2 / 2'), findsNothing);
    },
  );

  testWidgets('erro parcial na aprovação em lote mostra snackbar de erro', (
    tester,
  ) async {
    _useWideViewport(tester);
    final approve = _FakeApproveTenantUseCase()
      ..throwFor = {'tn2'}; // 2ª aprovação falha.
    final pending = [
      _pendingTenant(name: 'Comercial Demo'),
      _pendingTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, approve: approve),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Comercial Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar (2)'));
    await tester.pumpAndSettle();

    // Ambos foram tentados, mas só 1 teve sucesso → mensagem de erro parcial.
    expect(approve.calls, 2);
    expect(
      find.text(
        'Erro ao aprovar tenants. Alguns podem não ter sido processados.',
      ),
      findsOneWidget,
    );
    expect(find.text('2 tenants aprovados'), findsNothing);
  });

  testWidgets('erro na carga mostra ErrorView e o retry recupera', (
    tester,
  ) async {
    _useWideViewport(tester);
    // Riverpod 3 reexecuta o provider automaticamente (retry com backoff)
    // enquanto a carga falha — o número exato de chamadas depende do
    // schedule interno, então as asserções usam limites inferiores.
    final pendingUseCase = _FakeGetPendingTenantsUseCase([_pendingTenant()])
      ..throwOnCall = true;

    await tester.pumpWidget(
      _buildApp(
        pending: const [],
        all: const [],
        pendingUseCase: pendingUseCase,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar as solicitações.'),
      findsOneWidget,
    );
    final callsAfterInitial = pendingUseCase.calls;
    expect(callsAfterInitial, greaterThanOrEqualTo(1));

    // Retry com o use case ainda falhando → o erro persiste.
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar as solicitações.'),
      findsOneWidget,
    );
    expect(pendingUseCase.calls, greaterThan(callsAfterInitial));

    // Retry com o use case recuperado volta à lista.
    pendingUseCase.throwOnCall = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Comercial Demo'), findsOneWidget);
  });

  testWidgets('pull-to-refresh recarrega a lista de pendentes', (tester) async {
    _useWideViewport(tester);
    final pendingUseCase = _FakeGetPendingTenantsUseCase([_pendingTenant()]);

    await tester.pumpWidget(
      _buildApp(
        pending: [_pendingTenant()],
        all: [_pendingTenant()],
        pendingUseCase: pendingUseCase,
      ),
    );
    await tester.pumpAndSettle();
    expect(pendingUseCase.calls, 1);

    // ListView usa AlwaysScrollableScrollPhysics → overscroll dispara o
    // RefreshIndicator mesmo com conteúdo curto.
    await tester.fling(find.text('Comercial Demo'), const Offset(0, 400), 800);
    await tester.pumpAndSettle();

    expect(pendingUseCase.calls, 2);
    expect(find.text('Comercial Demo'), findsOneWidget);
  });
}

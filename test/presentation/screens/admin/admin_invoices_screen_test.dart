import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/cancel_invoice_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/mark_invoice_as_paid_use_case.dart';
import 'package:tareqo/presentation/controllers/invoice_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_invoices_screen.dart';

class _FakeGetPendingInvoicesUseCase implements GetPendingInvoicesUseCase {
  _FakeGetPendingInvoicesUseCase(this._invoices);

  final List<Invoice> _invoices;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<Invoice>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha pendentes');
    return _invoices;
  }
}

class _FakeGetAllInvoicesUseCase implements GetAllInvoicesUseCase {
  _FakeGetAllInvoicesUseCase(this._invoices);

  final List<Invoice> _invoices;
  int calls = 0;

  @override
  Future<List<Invoice>> call() async {
    calls++;
    return _invoices;
  }
}

class _FakeMarkInvoiceAsPaidUseCase implements MarkInvoiceAsPaidUseCase {
  int calls = 0;
  String? lastInvoiceId;
  bool throwOnCall = false;

  @override
  Future<void> call(String invoiceId) async {
    calls++;
    lastInvoiceId = invoiceId;
    if (throwOnCall) throw Exception('falha ao marcar paga');
  }
}

class _FakeCancelInvoiceUseCase implements CancelInvoiceUseCase {
  int calls = 0;
  String? lastInvoiceId;
  bool throwOnCall = false;

  @override
  Future<void> call(String invoiceId) async {
    calls++;
    lastInvoiceId = invoiceId;
    if (throwOnCall) throw Exception('falha ao cancelar');
  }
}

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
  _FakeGetAllPlansUseCase(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

const _defaultPlans = [
  Plan(id: 'pl1', name: 'Essencial', priceMonthlyCents: 2990),
  Plan(id: 'pl2', name: 'Comercial', priceMonthlyCents: 9900),
];

final _defaultTenants = [
  Tenant(
    id: 'tn1',
    ownerUserId: 'owner11111',
    businessName: 'Farmácia Vida',
    planId: 'pl2',
    status: TenantStatus.approved,
    createdAt: DateTime(2026, 8, 1),
  ),
  Tenant(
    id: 'tn2',
    ownerUserId: 'owner22222',
    businessName: 'Mercado Central',
    planId: 'pl1',
    status: TenantStatus.approved,
    createdAt: DateTime(2026, 8, 1),
  ),
];

Invoice _invoice({
  String id = 'inv-001',
  String tenantId = 'tn1',
  String planId = 'pl2',
  int amountCents = 9900,
  InvoiceStatus status = InvoiceStatus.pending,
  DateTime? dueDate,
  String period = 'Setembro 2026',
  DateTime? paidAt,
}) => Invoice(
  id: id,
  tenantId: tenantId,
  planId: planId,
  amountCents: amountCents,
  status: status,
  dueDate: dueDate ?? DateTime(2026, 9, 15),
  period: period,
  paidAt: paidAt,
  createdAt: DateTime(2026, 9, 1),
);

Widget _buildApp({
  List<Invoice> pending = const [],
  List<Invoice> all = const [],
  List<Tenant>? tenants,
  List<Plan> plans = _defaultPlans,
  _FakeMarkInvoiceAsPaidUseCase? markPaid,
  _FakeCancelInvoiceUseCase? cancel,
  _FakeGetPendingInvoicesUseCase? pendingUseCase,
  _FakeGetAllInvoicesUseCase? allUseCase,
}) {
  return ProviderScope(
    overrides: [
      getPendingInvoicesUseCaseProvider.overrideWithValue(
        pendingUseCase ?? _FakeGetPendingInvoicesUseCase(pending),
      ),
      getAllInvoicesUseCaseProvider.overrideWithValue(
        allUseCase ?? _FakeGetAllInvoicesUseCase(all),
      ),
      markInvoiceAsPaidUseCaseProvider.overrideWithValue(
        markPaid ?? _FakeMarkInvoiceAsPaidUseCase(),
      ),
      cancelInvoiceUseCaseProvider.overrideWithValue(
        cancel ?? _FakeCancelInvoiceUseCase(),
      ),
      getAllTenantsUseCaseProvider.overrideWithValue(
        _FakeGetAllTenantsUseCase(tenants ?? _defaultTenants),
      ),
      getAllPlansUseCaseProvider.overrideWithValue(
        _FakeGetAllPlansUseCase(plans),
      ),
    ],
    child: testApp(
      home: const AdminInvoicesScreen(),
      // A fonte de teste (Ahem) é quadrada e muito mais larga que a Inter
      // de produção: os botões do card têm largura fixa (160px) e o rótulo
      // "Marcar como paga" estoura ~104px mesmo com viewport largo. Clamp
      // mais agressivo compensa sem afetar as asserções de texto.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 0.35,
        child: child!,
      ),
    ),
  );
}

/// Viewport largo e alto: evita overflow da fonte Ahem nos cards/pills.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('lista pendente com nomes de tenant/plano resolvidos', (
    tester,
  ) async {
    _useWideViewport(tester);
    final pending = [
      _invoice(),
      _invoice(
        id: 'inv-002',
        tenantId: 'tn2',
        planId: 'pl1',
        amountCents: 2990,
      ),
    ];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    // Títulos resolvidos via allTenantsProvider (não IDs brutos).
    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Setembro 2026 · Comercial'), findsOneWidget);
    expect(find.text('Setembro 2026 · Essencial'), findsOneWidget);
    // Valor em unidades (centavos → 99.00 / 29.90).
    expect(find.text('Valor: 99.00'), findsOneWidget);
    expect(find.text('Valor: 29.90'), findsOneWidget);
    // Pills de vencimento e chips de estado pendente.
    expect(find.text('Vencimento:'), findsNothing); // label vem com a data
    expect(find.textContaining('Vencimento:'), findsNWidgets(2));
    expect(find.text('Pendente'), findsNWidgets(2));
    // Ações só em facturas pendentes.
    expect(find.text('Marcar como paga'), findsNWidgets(2));
    expect(find.text('Cancelar'), findsNWidgets(2));
  });

  testWidgets('alternar para Todos mostra estados pagos/expirados/cancelados', (
    tester,
  ) async {
    _useWideViewport(tester);
    final all = [
      _invoice(),
      _invoice(
        id: 'inv-003',
        status: InvoiceStatus.paid,
        paidAt: DateTime(2026, 9, 10),
      ),
      _invoice(id: 'inv-004', tenantId: 'tn2', status: InvoiceStatus.expired),
      _invoice(
        id: 'inv-005',
        tenantId: 'tn2',
        planId: 'pl1',
        status: InvoiceStatus.cancelled,
      ),
    ];

    await tester.pumpWidget(_buildApp(pending: [all.first], all: all));
    await tester.pumpAndSettle();

    // Visão pendente: só a pendente.
    expect(find.text('Farmácia Vida'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    // Todos os 4 cards, cada um com o chip de estado.
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Paga'), findsOneWidget);
    expect(find.text('Expirada'), findsOneWidget);
    expect(find.text('Cancelada'), findsOneWidget);
    // Pill de data de pagamento só na paga.
    expect(find.textContaining('Pago em:'), findsOneWidget);
    // Ações só na pendente.
    expect(find.text('Marcar como paga'), findsOneWidget);
  });

  testWidgets('marcar como paga chama o use case e atualiza', (tester) async {
    _useWideViewport(tester);
    final markPaid = _FakeMarkInvoiceAsPaidUseCase();
    final pendingUseCase = _FakeGetPendingInvoicesUseCase([_invoice()]);
    final allUseCase = _FakeGetAllInvoicesUseCase([_invoice()]);

    await tester.pumpWidget(
      _buildApp(
        pending: [_invoice()],
        all: [_invoice()],
        markPaid: markPaid,
        pendingUseCase: pendingUseCase,
        allUseCase: allUseCase,
      ),
    );
    await tester.pumpAndSettle();
    expect(pendingUseCase.calls, 1);
    expect(allUseCase.calls, 1);

    await tester.tap(find.text('Marcar como paga'));
    await tester.pumpAndSettle();

    expect(markPaid.calls, 1);
    expect(markPaid.lastInvoiceId, 'inv-001');
    expect(find.text('Factura marcada como paga!'), findsOneWidget);
    // Ambos os providers foram recarregados.
    expect(pendingUseCase.calls, 2);
    expect(allUseCase.calls, 2);
  });

  testWidgets('erro ao marcar como paga mostra snackbar de erro', (
    tester,
  ) async {
    _useWideViewport(tester);
    final markPaid = _FakeMarkInvoiceAsPaidUseCase()..throwOnCall = true;

    await tester.pumpWidget(
      _buildApp(pending: [_invoice()], all: [_invoice()], markPaid: markPaid),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar como paga'));
    await tester.pumpAndSettle();

    expect(markPaid.calls, 1);
    expect(
      find.text('Não foi possível marcar como paga. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Factura marcada como paga!'), findsNothing);
  });

  testWidgets('cancelar com confirmação chama o use case', (tester) async {
    _useWideViewport(tester);
    final cancel = _FakeCancelInvoiceUseCase();

    await tester.pumpWidget(
      _buildApp(pending: [_invoice()], all: [_invoice()], cancel: cancel),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();

    // Dialog de confirmação com o período interpolado.
    expect(find.text('Cancelar factura?'), findsOneWidget);
    expect(find.text('Cancelar a factura de Setembro 2026?'), findsOneWidget);

    await tester.tap(find.text('Sim, cancelar'));
    await tester.pumpAndSettle();

    expect(cancel.calls, 1);
    expect(cancel.lastInvoiceId, 'inv-001');
    expect(find.text('Factura cancelada.'), findsOneWidget);
  });

  testWidgets('cancelar com dialog dispensado não chama o use case', (
    tester,
  ) async {
    _useWideViewport(tester);
    final cancel = _FakeCancelInvoiceUseCase();

    await tester.pumpWidget(
      _buildApp(pending: [_invoice()], all: [_invoice()], cancel: cancel),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();

    // Cancelar dentro do dialog — o card por baixo também tem 'Cancelar'.
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(cancel.calls, 0);
    expect(find.text('Factura cancelada.'), findsNothing);
    // Card continua com ações.
    expect(find.text('Marcar como paga'), findsOneWidget);
  });

  testWidgets('erro ao cancelar mostra snackbar de erro', (tester) async {
    _useWideViewport(tester);
    final cancel = _FakeCancelInvoiceUseCase()..throwOnCall = true;

    await tester.pumpWidget(
      _buildApp(pending: [_invoice()], all: [_invoice()], cancel: cancel),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim, cancelar'));
    await tester.pumpAndSettle();

    expect(cancel.calls, 1);
    expect(
      find.text('Não foi possível cancelar a factura. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Factura cancelada.'), findsNothing);
  });

  testWidgets('busca filtra por nome, período e plano; limpar restaura', (
    tester,
  ) async {
    _useWideViewport(tester);
    final pending = [
      _invoice(),
      _invoice(
        id: 'inv-002',
        tenantId: 'tn2',
        planId: 'pl1',
        amountCents: 2990,
      ),
    ];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    // Por nome do tenant.
    await tester.enterText(find.byType(TextField), 'vida');
    await tester.pumpAndSettle();
    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Mercado Central'), findsNothing);

    // Por período.
    await tester.enterText(find.byType(TextField), 'setembro');
    await tester.pumpAndSettle();
    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);

    // Por nome do plano.
    await tester.enterText(find.byType(TextField), 'essencial');
    await tester.pumpAndSettle();
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Farmácia Vida'), findsNothing);

    // Sem resultado → estado vazio de busca.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum resultado'), findsOneWidget);

    // Limpar restaura (✕ tem size 16 — distinto do ícone dos botões).
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.close && w.size == 16,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
  });

  testWidgets('estado vazio difere entre pendentes e todos', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(pending: const [], all: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma factura pendente.'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma factura gerada ainda.'), findsOneWidget);
  });

  testWidgets('erro de carga mostra ErrorView e o retry recupera', (
    tester,
  ) async {
    _useWideViewport(tester);
    // Riverpod 3 reexecuta providers a falhar com backoff — usar limites
    // inferiores nas contagens (ver COVERAGE_REPORT.md §15).
    final pendingUseCase = _FakeGetPendingInvoicesUseCase([_invoice()])
      ..throwOnCall = true;

    await tester.pumpWidget(_buildApp(pendingUseCase: pendingUseCase));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as facturas.'), findsOneWidget);
    final callsAfterInitial = pendingUseCase.calls;
    expect(callsAfterInitial, greaterThanOrEqualTo(1));

    // Retry com o use case recuperado volta à lista.
    pendingUseCase.throwOnCall = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(pendingUseCase.calls, greaterThan(callsAfterInitial));
  });

  testWidgets('pull-to-refresh recarrega ambos os providers', (tester) async {
    _useWideViewport(tester);
    final pendingUseCase = _FakeGetPendingInvoicesUseCase([_invoice()]);
    final allUseCase = _FakeGetAllInvoicesUseCase([_invoice()]);

    await tester.pumpWidget(
      _buildApp(
        pending: [_invoice()],
        all: [_invoice()],
        pendingUseCase: pendingUseCase,
        allUseCase: allUseCase,
      ),
    );
    await tester.pumpAndSettle();
    expect(pendingUseCase.calls, 1);
    expect(allUseCase.calls, 1);

    // ListView usa AlwaysScrollableScrollPhysics → overscroll dispara o
    // RefreshIndicator mesmo com conteúdo curto.
    await tester.fling(find.text('Farmácia Vida'), const Offset(0, 400), 800);
    await tester.pumpAndSettle();

    expect(pendingUseCase.calls, 2);
    expect(allUseCase.calls, 2);
    expect(find.text('Farmácia Vida'), findsOneWidget);
  });

  testWidgets('tenant/plano desconhecidos caem no fallback para o ID', (
    tester,
  ) async {
    _useWideViewport(tester);
    final invoice = _invoice(tenantId: 'tn-fantasma', planId: 'pl-fantasma');

    await tester.pumpWidget(_buildApp(pending: [invoice], all: [invoice]));
    await tester.pumpAndSettle();

    // Sem tenant/plano correspondentes: mostra o ID bruto.
    expect(find.text('tn-fantasma'), findsOneWidget);
    expect(find.text('Setembro 2026 · pl-fantasma'), findsOneWidget);
  });
}

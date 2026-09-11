import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/send_admin_message_use_case.dart';
import 'package:tareqo/presentation/controllers/admin_message_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_messages_screen.dart';

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

class _FakeSendAdminMessageUseCase implements SendAdminMessageUseCase {
  int calls = 0;
  String? lastTenantId;
  AdminMessageType? lastType;
  String? lastTitle;
  String? lastBody;

  /// Quando true, o envio falha (caminho de erro com snackbar).
  bool throwOnCall = false;

  @override
  Future<AdminMessage> call({
    required String tenantId,
    required AdminMessageType type,
    required String title,
    required String body,
  }) async {
    calls++;
    lastTenantId = tenantId;
    lastType = type;
    lastTitle = title;
    lastBody = body;
    if (throwOnCall) throw Exception('falha ao enviar');
    return AdminMessage(
      id: 'am1',
      tenantId: tenantId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime(2026, 9, 11),
    );
  }
}

const _defaultPlans = [Plan(id: 'pl2', name: 'Comercial', priceMonthlyCents: 9900)];

Tenant _approvedTenant({
  String id = 'tn1',
  String name = 'Farmácia Vida',
  DateTime? expiresAt,
}) => Tenant(
  id: id,
  ownerUserId: 'owner12345',
  businessName: name,
  planId: 'pl2',
  status: TenantStatus.approved,
  createdAt: DateTime(2026, 8, 1),
  planExpiresAt: expiresAt,
);

Widget _buildApp({
  required List<Tenant> all,
  List<Plan> plans = _defaultPlans,
  _FakeSendAdminMessageUseCase? send,
}) {
  return ProviderScope(
    overrides: [
      getAllTenantsUseCaseProvider.overrideWithValue(
        _FakeGetAllTenantsUseCase(all),
      ),
      getAllPlansUseCaseProvider.overrideWithValue(
        _FakeGetAllPlansUseCase(plans),
      ),
      sendAdminMessageUseCaseProvider.overrideWithValue(
        send ?? _FakeSendAdminMessageUseCase(),
      ),
    ],
    child: testApp(
      home: const AdminMessagesScreen(),
      // A fonte de teste (Ahem) é mais larga que a Inter de produção —
      // clamp compensa sem afetar as asserções de texto.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 0.8,
        child: child!,
      ),
    ),
  );
}

/// Viewport largo e alto: evita overflow da fonte Ahem nos cards/preview.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Seleciona [name] no dropdown de tenants.
Future<void> _selectTenant(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<Tenant>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

/// Inicializa `allPlansProvider` no container do teste.
///
/// A tela só faz `ref.read` (sem subscrição) — em produção o shell admin
/// mantém o provider vivo; no teste isolado precisamos aquecê-lo
/// explicitamente antes de seleccionar o tenant, ou o nome do plano cai
/// no fallback para o ID bruto ("pl2").
Future<void> _warmPlans(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AdminMessagesScreen)),
  );
  await container.read(allPlansProvider.future);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validação: form vazio mostra erros e não envia', (tester) async {
    _useWideViewport(tester);
    final send = _FakeSendAdminMessageUseCase();

    await tester.pumpWidget(_buildApp(all: const [], send: send));
    await tester.pumpAndSettle();

    // Template sem tenant seleccionado é no-op (branch de guarda).
    await tester.tap(find.text('Cotação'));
    await tester.pumpAndSettle();
    expect(find.text('Template aplicado — edite conforme necessário'), findsNothing);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione um tenant.'), findsOneWidget);
    expect(find.text('Digite um título.'), findsOneWidget);
    expect(find.text('Digite o corpo da mensagem.'), findsOneWidget);
    expect(send.calls, 0);
  });

  testWidgets('dropdown lista apenas tenants aprovados', (tester) async {
    _useWideViewport(tester);

    await tester.pumpWidget(
      _buildApp(
        all: [
          _approvedTenant(),
          _approvedTenant(id: 'tn2', name: 'Comercial Demo'),
          Tenant(
            id: 'tn3',
            ownerUserId: 'owner33333',
            businessName: 'Pendente Ltda',
            planId: 'pl2',
            status: TenantStatus.pending,
            createdAt: DateTime(2026, 8, 1),
          ),
          Tenant(
            id: 'tn4',
            ownerUserId: 'owner44444',
            businessName: 'Rejeitado Ltda',
            planId: 'pl2',
            status: TenantStatus.rejected,
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<Tenant>));
    await tester.pumpAndSettle();

    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Pendente Ltda'), findsNothing);
    expect(find.text('Rejeitado Ltda'), findsNothing);
  });

  testWidgets('cotação: template preenche, envia e reseta o form', (
    tester,
  ) async {
    _useWideViewport(tester);
    final send = _FakeSendAdminMessageUseCase();
    final tenant = _approvedTenant(expiresAt: DateTime(2026, 10, 15));

    await tester.pumpWidget(
      _buildApp(all: [tenant], send: send),
    );
    await tester.pumpAndSettle();
    await _warmPlans(tester);

    await _selectTenant(tester, 'Farmácia Vida');

    // Chip informativo: nome · plano + validade dd/MM.
    expect(find.text('Farmácia Vida · Comercial'), findsOneWidget);
    expect(find.text('15/10'), findsOneWidget);

    await tester.tap(find.text('Cotação'));
    await tester.pumpAndSettle();

    // Título e corpo preenchidos pelo template; preview visível.
    expect(find.text('Cotação de Plano — Comercial'), findsWidgets);
    expect(find.textContaining('cotação para renovação'), findsWidgets);
    expect(
      find.text('Template aplicado — edite conforme necessário'),
      findsOneWidget,
    );
    expect(find.text('Preview'), findsOneWidget);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(send.calls, 1);
    expect(send.lastTenantId, 'tn1');
    expect(send.lastType, AdminMessageType.billingQuote);
    expect(send.lastTitle, 'Cotação de Plano — Comercial');

    // Sucesso: snackbar + form resetado (chip, textos e preview somem).
    expect(find.text('Mensagem enviada!'), findsOneWidget);
    expect(find.text('Cotação de Plano — Comercial'), findsNothing);
    expect(find.textContaining('Farmácia Vida ·'), findsNothing);
    expect(find.text('Preview'), findsNothing);
  });

  testWidgets('tipo seleccionado antes do tenant é aplicado automaticamente', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(all: [_approvedTenant()]));
    await tester.pumpAndSettle();

    // Tipo primeiro (ainda sem tenant — no-op).
    await tester.tap(find.text('Alterar Validade'));
    await tester.pumpAndSettle();
    expect(find.text('Template aplicado — edite conforme necessário'), findsNothing);

    // Tenant depois → o template do tipo já seleccionado é aplicado.
    await _warmPlans(tester);
    await _selectTenant(tester, 'Farmácia Vida');

    expect(find.text('Alteração de Validade — Comercial'), findsWidgets);
    expect(
      find.text('Template aplicado — edite conforme necessário'),
      findsOneWidget,
    );
  });

  testWidgets('plano a expirar usa os dias restantes na mensagem', (
    tester,
  ) async {
    _useWideViewport(tester);
    // +2h de folga: mantém inDays == 10 apesar do truncamento.
    final tenant = _approvedTenant(
      expiresAt: DateTime.now().add(const Duration(days: 10, hours: 2)),
    );

    await tester.pumpWidget(_buildApp(all: [tenant]));
    await tester.pumpAndSettle();
    await _warmPlans(tester);

    await _selectTenant(tester, 'Farmácia Vida');
    await tester.tap(find.text('Plano a Expirar'));
    await tester.pumpAndSettle();

    expect(find.text('⚠️ Plano a Expirar — Comercial'), findsWidgets);
    expect(find.textContaining('10 dias'), findsWidgets);
  });

  testWidgets('alterar validade sem expiração usa fallback e motivo', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(all: [_approvedTenant()]));
    await tester.pumpAndSettle();
    await _warmPlans(tester);

    await _selectTenant(tester, 'Farmácia Vida');
    await tester.tap(find.text('Alterar Validade'));
    await tester.pumpAndSettle();

    expect(find.text('Alteração de Validade — Comercial'), findsWidgets);
    expect(find.textContaining('Nova data de expiração'), findsWidgets);
    expect(find.textContaining('Ajuste administrativo'), findsWidgets);
  });

  testWidgets('mensagem livre não sobrescreve campos já preenchidos', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(all: [_approvedTenant()]));
    await tester.pumpAndSettle();
    await _warmPlans(tester);

    await _selectTenant(tester, 'Farmácia Vida');
    await tester.tap(find.text('Cotação'));
    await tester.pumpAndSettle();
    expect(find.text('Cotação de Plano — Comercial'), findsWidgets);

    // Mensagem Livre tem template vazio → título/corpo permanecem.
    await tester.tap(find.text('Mensagem Livre'));
    await tester.pumpAndSettle();

    expect(find.text('Cotação de Plano — Comercial'), findsWidgets);
  });

  testWidgets('erro no envio mostra snackbar e preserva os campos', (
    tester,
  ) async {
    _useWideViewport(tester);
    final send = _FakeSendAdminMessageUseCase()..throwOnCall = true;

    await tester.pumpWidget(_buildApp(all: [_approvedTenant()], send: send));
    await tester.pumpAndSettle();

    await _selectTenant(tester, 'Farmácia Vida');
    await tester.enterText(find.byType(TextFormField).at(0), 'Assunto teste');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Corpo da mensagem de teste',
    );
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(send.calls, 1);
    expect(find.text('Não foi possível enviar a mensagem. Tente novamente.'), findsOneWidget);
    // Campos preservados (sem reset) — o admin não perde o texto.
    expect(find.text('Assunto teste'), findsOneWidget);
    expect(find.text('Mensagem enviada!'), findsNothing);
  });
}

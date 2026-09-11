import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/audit_entry.dart';
import 'package:tareqo/domain/usecases/get_audit_log_use_case.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_audit_log_screen.dart';

class _FakeGetAuditLogUseCase implements GetAuditLogUseCase {
  _FakeGetAuditLogUseCase(this._entries, {this.throwOnCall = false});

  final List<AuditEntry> _entries;
  bool throwOnCall;
  int calls = 0;

  @override
  Future<List<AuditEntry>> call({int limit = 100}) async {
    calls++;
    if (throwOnCall) throw Exception('falha no registo de auditoria');
    return _entries;
  }
}

AuditEntry _entry({
  required int id,
  required String action,
  required String entityType,
  String? entityId,
  Map<String, dynamic>? detail,
  required DateTime createdAt,
  String? actorUserId,
}) =>
    AuditEntry(
      id: id,
      actorUserId: actorUserId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      detail: detail,
      createdAt: createdAt,
    );

/// Viewport alto e largo — o CustomScrollView empilha stats + busca +
/// filtros + grupos de data; e os tiles usam Text.rich (fonte Ahem é larga).
void _useWideTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Os tiles renderizam ação/entidade/ID num [Text.rich] — `find.text` só
/// casa com `Text.data`; e mesmo com `findRichText` a comparação é de
/// IGUALDADE do texto plano inteiro. `textContaining` casa por conteúdo.
Finder _tileText(String text) => find.textContaining(text, findRichText: true);

Widget _buildApp(_FakeGetAuditLogUseCase useCase) {
  return ProviderScope(
    overrides: [
      getAuditLogUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(home: const AdminAuditLogScreen()),
  );
}

void main() {
  testWidgets('exibe entradas agrupadas por data com stats e tempo relativo', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final now = DateTime.now();
    final entries = [
      _entry(
        id: 1,
        action: 'tenant_decision',
        entityType: 'tenants',
        entityId: 'mercado-abc',
        detail: const {'status': 'approved'},
        createdAt: now.subtract(const Duration(minutes: 2)),
        actorUserId: 'admin9',
      ),
      _entry(
        id: 2,
        action: 'plan_request_decision',
        entityType: 'plan_requests',
        entityId: 'req-77',
        detail: const {'status': 'rejected'},
        createdAt: now.subtract(const Duration(days: 1, minutes: 30)),
      ),
      _entry(
        id: 3,
        action: 'plan_change',
        entityType: 'plans',
        entityId: 'pl2',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      _entry(
        id: 4,
        action: 'tenant_decision',
        entityType: 'tenants',
        entityId: 'antigo-1',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    await tester.pumpWidget(_buildApp(_FakeGetAuditLogUseCase(entries)));
    await tester.pumpAndSettle();

    // Stats: total 4, aprovados 1, rejeitados 1, taxa 25%.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // aprovados e rejeitados
    expect(find.text('25%'), findsOneWidget);

    // Rótulos de ação (Text.rich nos tiles) + ID da entidade.
    expect(_tileText('Tenant decision'), findsNWidgets(2));
    expect(_tileText('Plan request decision'), findsOneWidget);
    expect(_tileText('Plan change'), findsOneWidget);
    expect(_tileText('mercado-abc'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('REJECTED'), findsOneWidget);

    // Grupos de data ordenados (header em maiúsculas).
    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('ONTEM'), findsOneWidget);
    expect(find.text('ESTA SEMANA'), findsOneWidget);
    expect(find.text('MAIS ANTIGO'), findsOneWidget);

    // Tempo relativo da entrada de hoje (2 min atrás).
    expect(find.text('2m'), findsOneWidget);
  });

  testWidgets('filtro por categoria mostra apenas as entradas da ação', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final now = DateTime.now();
    final entries = [
      _entry(
        id: 1,
        action: 'tenant_decision',
        entityType: 'tenants',
        entityId: 'mercado-abc',
        detail: const {'status': 'approved'},
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      _entry(
        id: 2,
        action: 'plan_request_decision',
        entityType: 'plan_requests',
        entityId: 'req-77',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      _entry(
        id: 3,
        action: 'plan_change',
        entityType: 'plans',
        entityId: 'pl2',
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
    ];

    await tester.pumpWidget(_buildApp(_FakeGetAuditLogUseCase(entries)));
    await tester.pumpAndSettle();

    // Filtro "Tenants" → apenas tenant_decision.
    await tester.tap(find.text('Tenants'));
    await tester.pumpAndSettle();

    expect(_tileText('mercado-abc'), findsOneWidget);
    expect(_tileText('req-77'), findsNothing);
    expect(_tileText('pl2'), findsNothing);
    // Stats continuam sobre TODAS as entradas (total 3).
    expect(find.text('3'), findsOneWidget);

    // Filtro "Upgrades" → apenas plan_request_decision.
    await tester.tap(find.text('Upgrades'));
    await tester.pumpAndSettle();

    expect(_tileText('req-77'), findsOneWidget);
    expect(_tileText('mercado-abc'), findsNothing);

    // Voltar para "Todos" restaura a lista completa. "Todos" também é o
    // rótulo da pill de stats — fica ACIMA da fileira de filtros, então
    // o chip é o .last.
    await tester.tap(find.text('Todos').last);
    await tester.pumpAndSettle();

    expect(_tileText('mercado-abc'), findsOneWidget);
    expect(_tileText('req-77'), findsOneWidget);
    expect(_tileText('pl2'), findsOneWidget);
  });

  testWidgets('busca filtra por entityId e o estado vazio orienta', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final now = DateTime.now();
    final entries = [
      _entry(
        id: 1,
        action: 'tenant_decision',
        entityType: 'tenants',
        entityId: 'mercado-abc',
        detail: const {'status': 'approved'},
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      _entry(
        id: 2,
        action: 'plan_change',
        entityType: 'plans',
        entityId: 'pl2',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    await tester.pumpWidget(_buildApp(_FakeGetAuditLogUseCase(entries)));
    await tester.pumpAndSettle();

    // Busca por parte do ID da entidade.
    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();

    expect(_tileText('mercado-abc'), findsOneWidget);
    expect(_tileText('pl2'), findsNothing);

    // Busca sem correspondência → estado vazio de filtro.
    await tester.enterText(find.byType(TextField), 'zzz-inexistente');
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma entrada corresponde ao filtro.'), findsOneWidget);

    // Limpar a busca (botão ✕ do campo) restaura todas as entradas.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(_tileText('mercado-abc'), findsOneWidget);
    expect(_tileText('pl2'), findsOneWidget);
  });

  testWidgets('tocar numa entrada abre o sheet de detalhes completo', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final now = DateTime.now();
    final entry = _entry(
      id: 7,
      action: 'tenant_decision',
      entityType: 'tenants',
      entityId: 'mercado-abc',
      detail: const {'status': 'approved', 'reason': 'documentos ok'},
      createdAt: now.subtract(const Duration(minutes: 2)),
      actorUserId: 'admin9',
    );

    await tester.pumpWidget(_buildApp(_FakeGetAuditLogUseCase([entry])));
    await tester.pumpAndSettle();

    // Toca no tile (o .first é o tile; o sheet ainda não existe).
    await tester.tap(_tileText('Tenant decision').first);
    await tester.pumpAndSettle();

    // Header do sheet + tile atrás (RichText do tile + Text do sheet).
    expect(_tileText('Tenant decision'), findsNWidgets(2));
    expect(find.text('Tenant  mercado-abc'), findsOneWidget);

    // Linhas de detalhe.
    expect(find.text('#7'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Responsável'), findsOneWidget);
    expect(find.text('admin9'), findsOneWidget);
    expect(find.text('Entidade'), findsOneWidget);
    expect(find.text('Ação'), findsOneWidget);
    expect(_tileText('mercado-abc'), findsNWidgets(3)); // tile + header + row

    // Payload JSON do detalhe + status dot em maiúsculas.
    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('status: '), findsOneWidget);
    expect(find.text('approved'), findsOneWidget); // valor JSON (minúsculo)
    expect(find.text('APPROVED'), findsNWidgets(2)); // dot do tile + do sheet
    expect(find.text('reason: '), findsOneWidget);
    expect(find.text('documentos ok'), findsOneWidget);
  });

  testWidgets('entrada sem status não mostra dot nem cor de decisão', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final now = DateTime.now();
    final entry = _entry(
      id: 3,
      action: 'plan_change',
      entityType: 'plans',
      entityId: 'pl2',
      createdAt: now.subtract(const Duration(minutes: 4)),
    );

    await tester.pumpWidget(_buildApp(_FakeGetAuditLogUseCase([entry])));
    await tester.pumpAndSettle();

    // Sem detail.status → nenhum rótulo de status em maiúsculas.
    expect(find.text('APPROVED'), findsNothing);
    expect(find.text('REJECTED'), findsNothing);
    expect(_tileText('Plan change'), findsOneWidget);
  });

  testWidgets('erro mostra ErrorView e o retry recarrega os dados', (
    tester,
  ) async {
    _useWideTallViewport(tester);
    final useCase = _FakeGetAuditLogUseCase(
      const [],
      throwOnCall: true,
    );

    await tester.pumpWidget(_buildApp(useCase));
    await tester.pumpAndSettle();

    // Erro exibido com o botão de retry — nunca silencioso.
    expect(
      find.text('Exception: falha no registo de auditoria'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Depois do retry (consulta passa a funcionar), os dados aparecem.
    useCase.throwOnCall = false;
    useCase.calls = 0;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(useCase.calls, 1);
    expect(find.text('Tentar novamente'), findsNothing);
  });
}

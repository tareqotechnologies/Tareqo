import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/data/datasources/remote/supabase_datasource_helpers.dart';
import 'package:tareqo/data/repositories/supabase_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/l10n/generated/app_localizations.dart';
import 'package:tareqo/main.dart' as app;

/// E2E do PAYLOAD REAL da RPC `get_cash_closing_summary` (prévia do
/// Z-report, H2) CONTRA O SUPABASE REAL.
///
/// Credenciais REAIS fornecidas em tempo de execução via --dart-define
/// (nunca versionadas — o ficheiro só contém os nomes dos defines):
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/cash_closing_summary_live_test.dart \
///     -d chrome --dart-define-from-file=env/dev.env \
///     --dart-define=TEST_OWNER_EMAIL=... --dart-define=TEST_OWNER_PASSWORD=...
///
/// O teste prova 4 coisas contra o servidor real:
///
/// 1. **Payload exato**: o `SupabaseCashClosingSummaryRepository` envia
///    exatamente `{p_store_id, p_day}` com o dia normalizado para o INÍCIO
///    do dia LOCAL em UTC (seam de OBSERVAÇÃO que não troca a chamada — o
///    payload capturado é encaminhado ao `supabaseClient` REAL);
/// 2. **Aceitação real**: a chamada real não lança (a RPC aceita o payload);
/// 3. **Agregação server-side coerente**: `total_sales_cents` = Σ da
///    abertura por forma e `expected_cash_cents` = só dinheiro (mesmos
///    invariantes que o `sql_check.sh` valida no smoke Postgres);
/// 4. **Cadeia registrada**: o `GetCashClosingSummaryUseCase` real do
///    ServiceLocator devolve o MESMO resultado — o app usa a RPC (sem
///    carregar vendas), e a guarda `is_my_store` rejeita loja alheia.
const _ownerEmail = String.fromEnvironment('TEST_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('TEST_OWNER_PASSWORD');

/// Marcador do ecrã de login, independente de idioma (título da app).
const _loginTitle = 'TAREQO';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 60),
  required String reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) return;
  }
  throw TestFailure('Timeout à espera de: $reason');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_ownerEmail.isEmpty || _ownerPassword.isEmpty) {
    throw StateError(
      'Faltam as credenciais: passe --dart-define=TEST_OWNER_EMAIL e '
      'TEST_OWNER_PASSWORD.',
    );
  }

  // Resolve o texto localizado ATUAL da app a partir de um contexto ABAIXO
  // do widget Localizations (o contexto do próprio MaterialApp devolve
  // null). O anchor tem de ser um widget renderizado nessa altura.
  AppLocalizations l10nOf(WidgetTester tester, {Finder? anchor}) {
    final finder = anchor ?? find.byType(Text).first;
    return AppLocalizations.of(tester.element(finder));
  }

  Future<void> doLogin(WidgetTester tester) async {
    await _pumpUntil(
      tester,
      () => find.text(_loginTitle).evaluate().isNotEmpty,
      reason: 'ecrã de login',
    );
    final l10n = l10nOf(tester, anchor: find.text(_loginTitle).first);
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.loginEmailLabel),
      _ownerEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.loginPasswordLabel),
      _ownerPassword,
    );
    await tester.tap(find.text(l10n.loginSignIn));
    await _pumpUntil(
      tester,
      () => find.byIcon(Icons.logout).evaluate().isNotEmpty,
      reason: 'dashboard após login',
    );
  }

  testWidgets(
    'payload real da RPC get_cash_closing_summary contra o Supabase: loja + '
    'início do dia local em UTC, agregação server-side coerente e guarda '
    'is_my_store',
    (tester) async {
      await app.main();
      await tester.pump(const Duration(seconds: 3));
      await doLogin(tester);

      // ── Resolve a loja REAL do dono logado (mesmo caminho do app) ──
      final userId = requireCurrentUserId();
      final tenant = await ServiceLocator.instance<GetMyTenantUseCase>()(
        userId,
      );
      if (tenant == null) {
        fail('Tenant não resolvido após o login do dono.');
      }
      final stores = await ServiceLocator.instance<GetStoresUseCase>()(
        tenant.id,
      );
      if (stores.isEmpty) {
        fail('O tenant do dono não possui lojas.');
      }
      final storeId = stores.first.id;

      final now = DateTime.now();
      final expectedDayUtc = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();

      // ── 1) PAYLOAD REAL: seam de OBSERVAÇÃO que encaminha ao servidor ──
      // O override NÃO troca a chamada por um fake: apenas REGISTRA o que o
      // repositório montaria e segue para o `supabaseClient` REAL. Se o
      // servidor rejeitar o payload, a chamada real lança PostgrestException.
      late String capturedFn;
      late Map<String, dynamic> capturedParams;
      Future<dynamic> observeAndForward(
        String fn,
        Map<String, dynamic> params,
      ) {
        capturedFn = fn;
        capturedParams = params;
        return supabaseClient.rpc(fn, params: params); // chamada REAL
      }

      final repo = SupabaseCashClosingSummaryRepository(rpc: observeAndForward);
      final summary = await repo.fetchSummary(storeId: storeId, day: now);

      // Payload exato que o app envia contra o servidor real.
      expect(capturedFn, 'get_cash_closing_summary');
      expect(capturedParams, {'p_store_id': storeId, 'p_day': expectedDayUtc});

      // O servidor real aceitou e agregou de forma coerente:
      // total = Σ da abertura por forma; esperado = só vendas em dinheiro.
      expect(summary.day, DateTime(now.year, now.month, now.day));
      final byMethodSum = summary.salesByMethodCents.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      expect(byMethodSum, summary.totalSalesCents);
      expect(
        summary.expectedCashCents,
        summary.salesByMethodCents['cash'] ?? 0,
      );
      for (final method in summary.salesByMethodCents.keys) {
        expect(
          PaymentMethod.values.asNameMap(),
          contains(method),
          reason: '$method não é uma forma de pagamento válida',
        );
      }
      // Fecho já registrado (se o dia estiver fechado) bate com a
      // agregação do dia — mesma fonte (linha UPSERT do close_cash_register).
      final existing = summary.existingClosing;
      if (existing != null) {
        expect(existing.totalSalesCents, summary.totalSalesCents);
        expect(existing.expectedCashCents, summary.expectedCashCents);
      }

      // ── 2) CADEIA REGISTRADA (use case real → RPC, sem carregar vendas) ──
      expect(
        ServiceLocator.instance.isRegistered<ICashClosingSummaryRepository>(),
        isTrue,
        reason: 'modo Supabase: o repositório server-side está registrado',
      );
      final registeredSummary =
          await ServiceLocator.instance<GetCashClosingSummaryUseCase>()(
            storeId: storeId,
            day: now,
          );
      expect(
        registeredSummary.totalSalesCents,
        summary.totalSalesCents,
        reason: 'a cadeia do app usa a MESMA agregação server-side',
      );
      expect(registeredSummary.expectedCashCents, summary.expectedCashCents);

      // ── 3) GUARDA is_my_store: loja alheia é rejeitada PELO SERVIDOR ──
      // A guarda é a autoridade (mesmo com um cliente que contorne a UI):
      // uma loja sintética fora do tenant do dono NÃO pode ser lida.
      await expectLater(
        repo.fetchSummary(
          storeId: '00000000-0000-0000-0000-000000000000',
          day: now,
        ),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.message,
            'message',
            contains('Acesso negado'),
          ),
        ),
      );
    },
  );
}

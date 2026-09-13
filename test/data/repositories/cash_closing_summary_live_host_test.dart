import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/core/network/supabase_bootstrap.dart';
import 'package:tareqo/data/repositories/supabase_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';

/// Executa a CADEIA REAL do E2E `cash_closing_summary_live_test.dart` na VM
/// do host (`flutter test`), sem device — o mesmo padrão do runner de
/// certificate pinning (`cert_pinning_live_host_test.dart`).
///
/// Motivo: os navegadores locais (Chrome/Edge 152) derrubam a sessão do
/// `flutter drive` logo após o debug service conectar — o E2E de browser
/// fica inviável NESTA máquina (limitação ambiental, não do teste). A cadeia
/// verificada aqui é a MESMA do E2E menos a UI:
///
/// 1. Supabase real inicializado com as credenciais de dev (dart-defines);
/// 2. login REAL (GoTrue) com o dono — `IAuthRepository.signIn` do app;
/// 3. tenant + lojas REAIS do dono (mesmos use cases do app);
/// 4. RPC REAL `get_cash_closing_summary` via seam de OBSERVAÇÃO que
///    encaminha ao servidor (payload capturado e validado);
/// 5. guarda `is_my_store` rejeitando loja alheia NO SERVIDOR.
///
/// É uma prova de INTEGRAÇÃO REAL (rede + Postgres + RLS), não de UI.
/// O teste é SKIPPED se as credenciais não forem passadas — o CI hermético
/// continua hermético; com credenciais, roda de verdade:
///
///   flutter test test/data/repositories/cash_closing_summary_live_host_test.dart \
///     --dart-define-from-file=env/dev.env \
///     --dart-define=TEST_OWNER_EMAIL=... --dart-define=TEST_OWNER_PASSWORD=...
const _ownerEmail = String.fromEnvironment('TEST_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('TEST_OWNER_PASSWORD');

void main() {
  // O Supabase persistence (SecureSupabaseLocalStorage) usa o canal do
  // flutter_secure_storage: no host VM é preciso mockar o canal (a sessão
  // do GoTrue persiste/lê por lá). Mock mínimo que mantém um mapa em
  // memória — o contrato do canal é preservado.
  // IMPORTANTE: IntegrationTestWidgetsFlutterBinding (e não o binding de
  // widget-test puro) — o binding de teste puro INTERCEPTA todo HttpClient
  // (respostas 400 falsas), o que mataria o login real. O binding de
  // integration test permite rede REAL (é o que o runner de cert-pinning
  // já usa com sucesso na VM do host).
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const secureChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStore = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureChannel, (call) async {
        switch (call.method) {
          case 'write':
            final args = call.arguments as Map<Object?, Object?>;
            secureStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'read':
            final args = call.arguments as Map<Object?, Object?>;
            return secureStore[args['key'] as String];
          case 'readAll':
            return Map<String, String>.of(secureStore);
          case 'delete':
            final args = call.arguments as Map<Object?, Object?>;
            secureStore.remove(args['key'] as String);
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'containsKey':
            final args = call.arguments as Map<Object?, Object?>;
            return secureStore.containsKey(args['key'] as String);
          default:
            return null;
        }
      });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });

  test(
    'cadeia real do fechamento de caixa contra o Supabase de dev: login, '
    'tenant/lojas reais, payload observado da RPC e guarda is_my_store',
    () async {
      if (_ownerEmail.isEmpty || _ownerPassword.isEmpty) {
        // Sem credenciais EXPLÍCITAS o teste NÃO toca na rede — o CI
        // hermético cai aqui e o teste NÃO mente (não valida nada contra
        // ar). Nota: NÃO dá para usar SupabaseConfig.isConfigured como
        // guarda — a config embutida (defaults de dev) o torna sempre
        // verdadeiro; a guarda correta é a credencial do dono.
        // ignore: avoid_print
        print(
          'SKIPPED (credenciais ausentes): passe --dart-define-from-file='
          'env/dev.env + TEST_OWNER_EMAIL/TEST_OWNER_PASSWORD.',
        );
        return;
      }

      await SupabaseBootstrap.initialize();
      await ServiceLocator.initialize();

      // ── 1) LOGIN REAL (GoTrue, mesmas credenciais do E2E de browser) ──
      final auth = ServiceLocator.instance<IAuthRepository>();
      final user = await auth.signIn(
        email: _ownerEmail,
        password: _ownerPassword,
      );
      expect(user.email, isNotEmpty);

      // ── 2) TENANT + LOJAS REAIS (mesmos use cases do app) ──
      final tenant = await ServiceLocator.instance<GetMyTenantUseCase>()(
        user.id,
      );
      expect(tenant, isNotNull, reason: 'dono tem tenant no projeto dev');
      final stores = await ServiceLocator.instance<GetStoresUseCase>()(
        tenant!.id,
      );
      expect(stores, isNotEmpty, reason: 'tenant do dono tem lojas');
      final storeId = stores.first.id;

      final now = DateTime.now();
      final expectedDayUtc = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();

      // ── 3) PAYLOAD REAL: seam de OBSERVAÇÃO encaminha ao servidor ──
      late String capturedFn;
      late Map<String, dynamic> capturedParams;
      Future<dynamic> observeAndForward(
        String fn,
        Map<String, dynamic> params,
      ) {
        capturedFn = fn;
        capturedParams = params;
        return Supabase.instance.client.rpc(fn, params: params); // REAL
      }

      final repo = SupabaseCashClosingSummaryRepository(rpc: observeAndForward);
      final summary = await repo.fetchSummary(storeId: storeId, day: now);

      // Payload exato que o app envia contra o servidor real.
      expect(capturedFn, 'get_cash_closing_summary');
      expect(capturedParams, {'p_store_id': storeId, 'p_day': expectedDayUtc});

      // Agregação server-side coerente (mesmos invariantes do smoke SQL).
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
      // Fecho já registrado (se houver) bate com a agregação do dia.
      final existing = summary.existingClosing;
      if (existing != null) {
        expect(existing.totalSalesCents, summary.totalSalesCents);
        expect(existing.expectedCashCents, summary.expectedCashCents);
      }

      // ── 4) CADEIA REGISTRADA (use case real → RPC) ──
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

      // ── 5) GUARDA is_my_store: loja alheia é rejeitada PELO SERVIDOR ──
      await expectLater(
        repo.fetchSummary(
          storeId: '00000000-0000-0000-0000-000000000000',
          day: now,
        ),
        throwsA(
          isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            contains('Acesso negado'),
          ),
        ),
      );

      // ── Limpeza: encerra a sessão real aberta pelo teste ──
      await auth.signOut();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

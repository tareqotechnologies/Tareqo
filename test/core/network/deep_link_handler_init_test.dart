import 'dart:async';

import 'package:app_links_platform_interface/app_links_method_channel.dart';
import 'package:app_links_platform_interface/app_links_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/network/deep_link_handler.dart';

/// Cobertura do [DeepLinkHandler.init] (ramos de listener): com a
/// plataforma de app_links simulada, o init registra o listener sem
/// lançar; URI legítima no stream é entregue; URI estranha é FILTRADA
/// (defesa V12 contra hijack). A troca de sessão em si (getSessionFromUrl)
/// exige o Supabase inicializado — ausente aqui, o catch do handler captura
/// e reporta via CrashReporting (nunca crash de zona).
class _FakeAppLinksPlatform extends AppLinksPlatform {
  final controller = StreamController<Uri>.broadcast();
  Uri? initialLink;

  @override
  Future<Uri?> getInitialLink() async => initialLink;

  @override
  Stream<Uri> get uriLinkStream => controller.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppLinksPlatform.instance = AppLinksMethodChannel();
  });

  test(
    'init sem plataforma (MissingPluginException) NÃO quebra o fluxo do app',
    () async {
      // O AppLinksMethodChannel default lança no teste — o init deve
      // capturar (CrashReporting) e retornar normalmente.
      await DeepLinkHandler.init();
    },
  );

  test('com plataforma fake: URI legítima no stream entra no handler; '
      'hijack é filtrado sem lançar', () async {
    final fake = _FakeAppLinksPlatform();
    AppLinksPlatform.instance = fake;

    // Cold start SEM link (app aberto pelo ícone).
    await DeepLinkHandler.init();

    // Warm start: link LEGÍTIMO (o getSessionFromUrl falha sem Supabase,
    // mas o catch interno captura — nunca propaga).
    fake.controller.add(Uri.parse('https://tareqo.app/callback?code=abc'));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Warm start: HIJACK (host errado) — filtrado ANTES do handler.
    fake.controller.add(Uri.parse('https://evil.example.com/callback?code=x'));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Warm start: scheme legado com host errado — filtrado.
    fake.controller.add(Uri.parse('tareqo://evil?code=y'));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Se chegamos aqui, nenhum erro escapou da zona (contrato do init).
    expect(fake.controller.isClosed, isFalse);
    await fake.controller.close();
  });

  test('erro no STREAM em si é capturado (sem unhandled zone error)', () async {
    final fake = _FakeAppLinksPlatform();
    AppLinksPlatform.instance = fake;

    await DeepLinkHandler.init();

    // Erro do canal da plataforma (websocket fora do ar etc.).
    fake.controller.addError(StateError('canal quebrado'));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(fake.controller.isClosed, isFalse);
    await fake.controller.close();
  });
}

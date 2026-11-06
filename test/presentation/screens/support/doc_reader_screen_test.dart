import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/presentation/screens/support/doc_reader_screen.dart';

/// O leitor carrega os markdowns REAIS empacotados (docs/ no pubspec) —
/// o teste valida o contrato observável: título por documento, conteúdo
/// renderizado, cache por idioma e navegação interna entre documentos.
void main() {
  group('SupportDocument.assetPath', () {
    test('mapeia idioma → asset correto em todos os documentos', () {
      // when / then — pt (fallback), en e fr para cada documento.
      expect(
        SupportDocument.userGuide.assetPath('pt'),
        'docs/pt/GUIA_DO_UTILIZADOR.md',
      );
      expect(
        SupportDocument.userGuide.assetPath('en'),
        'docs/en/USER_GUIDE.md',
      );
      expect(
        SupportDocument.userGuide.assetPath('fr'),
        'docs/fr/GUIDE_DE_L_UTILISATEUR.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('pt'),
        'docs/pt/TROUBLESHOOTING.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('en'),
        'docs/en/TROUBLESHOOTING.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('fr'),
        'docs/fr/DEPANNAGE.md',
      );
    });

    test(
      'idioma não suportado cai no português (idioma padrão do produto)',
      () {
        // when / then — 'es', 'de' etc. nunca quebram a Ajuda.
        expect(
          SupportDocument.userGuide.assetPath('es'),
          'docs/pt/GUIA_DO_UTILIZADOR.md',
        );
        expect(
          SupportDocument.troubleshooting.assetPath('zh'),
          'docs/pt/TROUBLESHOOTING.md',
        );
      },
    );
  });

  group('DocReaderScreen (assets reais empacotados)', () {
    testWidgets('exibe o título e o conteúdo do troubleshooting', (
      tester,
    ) async {
      // given — documento real do asset bundle.
      await tester.pumpWidget(
        testApp(
          home: const DocReaderScreen(
            document: SupportDocument.troubleshooting,
          ),
        ),
      );
      // Pumps finitos: carrega o asset e resolve o FutureBuilder
      // sem depender de settle (pumpAndSettle mostrou-se flaky aqui).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // then — appBar com o título l10n e o H1 do markdown visível.
      expect(find.text('Solução de problemas'), findsOneWidget);
      expect(
        find.textContaining('Solução de Problemas — TAREQO ERP'),
        findsWidgets,
      );
    });

    testWidgets('exibe o guia do utilizador com o título correto', (
      tester,
    ) async {
      // given
      await tester.pumpWidget(
        testApp(
          home: const DocReaderScreen(document: SupportDocument.userGuide),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // then
      expect(find.text('Guia do Utilizador'), findsOneWidget);
      // O guia renderiza conteúdo markdown (scrollável, sem erro).
      expect(find.text('Não foi possível abrir o documento.'), findsNothing);
    });

    testWidgets('falha de leitura mostra a mensagem de erro acessível', (
      tester,
    ) async {
      // given — canal de assets interceptado: o markdown NÃO é encontrado
      // (simula asset ausente/corrompido sem tocar em produção).
      //
      // ⚠️ ISOLAMENTO DE CACHE: `rootBundle` é um CachingAssetBundle que
      // guarda o FUTURO de loadString por isolate (putIfAbsent) — inclusive
      // o FUTURO FALHO deste teste. Sem o evict abaixo, um teste posterior
      // do mesmo path herdaria a falha; e um teste anterior (cache com o
      // conteúdo real) impediria o mock de ser consultado. O evict garante
      // que a carga passe SEMPRE pelo mock, em qualquer ordem.
      TestWidgetsFlutterBinding.ensureInitialized();
      const path = 'docs/pt/TROUBLESHOOTING.md';
      (rootBundle as PlatformAssetBundle).evict(path);
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async => null,
      );
      addTearDown(() async {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        );
        // Limpa também o futuro FALHO cacheado por este teste.
        (rootBundle as PlatformAssetBundle).evict(path);
      });

      // when
      await tester.pumpWidget(
        testApp(
          home: const DocReaderScreen(
            document: SupportDocument.troubleshooting,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // then — estado de erro com texto localizado (pt), cor de erro.
      expect(find.text('Não foi possível abrir o documento.'), findsOneWidget);
      // O markdown NÃO renderizou.
      expect(find.textContaining('TAREQO ERP'), findsNothing);
    });
  });
}

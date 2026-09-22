import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/screens/support/doc_reader_screen.dart';
import 'package:tareqo/presentation/screens/support/support_screen.dart';

import '../../helpers/test_app.dart';

/// Após navegar (tap) para o leitor: o markdown é lido do disco (rootBundle)
/// com I/O real, mas o relógio dos testes é fake — sem `runAsync` o Future
/// só completaria quando o evento real rodasse (spinner eterno). Sonda até o
/// markdown estar em ecrã: cada rodada dá tempo REAL ao I/O + um pump.
Future<void> settleAfterTap(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(Markdown).evaluate().isNotEmpty) {
      // Transição da rota + renderização final.
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  fail('Leitor não renderizou o markdown a tempo.');
}

void main() {
  group('SupportDocument — resolução do asset por idioma', () {
    test('pt → documentos em português', () {
      expect(
        SupportDocument.userGuide.assetPath('pt'),
        'docs/pt/GUIA_DO_UTILIZADOR.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('pt'),
        'docs/pt/TROUBLESHOOTING.md',
      );
    });

    test('en → documentos em inglês', () {
      expect(
        SupportDocument.userGuide.assetPath('en'),
        'docs/en/USER_GUIDE.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('en'),
        'docs/en/TROUBLESHOOTING.md',
      );
    });

    test('fr → documentos em francês', () {
      expect(
        SupportDocument.userGuide.assetPath('fr'),
        'docs/fr/GUIDE_DE_L_UTILISATEUR.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('fr'),
        'docs/fr/DEPANNAGE.md',
      );
    });

    test('idioma desconhecido cai no português (padrão do produto)', () {
      expect(
        SupportDocument.userGuide.assetPath('zz'),
        'docs/pt/GUIA_DO_UTILIZADOR.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('zz'),
        'docs/pt/TROUBLESHOOTING.md',
      );
    });
  });

  group('SupportScreen (Ajuda)', () {
    testWidgets('lista os 3 tópicos: guia, solução de problemas e suporte', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      expect(find.text('Ajuda'), findsOneWidget); // AppBar
      expect(find.text('Guia do Utilizador'), findsOneWidget);
      expect(find.text('Solução de problemas'), findsOneWidget);
      expect(find.text('Fale com o suporte'), findsOneWidget);
      // Dicas de cada tópico (hints) presentes.
      expect(find.textContaining('Login, lojas, produtos'), findsOneWidget);
      expect(
        find.textContaining('Resolva problemas de login'),
        findsOneWidget,
      );
      expect(find.textContaining('Nossa equipe pode ajudar'), findsOneWidget);
      // Campo de busca e rodapé da referência.
      expect(find.text('Buscar na ajuda'), findsOneWidget);
      expect(find.text('Central de ajuda'), findsOneWidget);
    });

    testWidgets('abre o Guia do Utilizador (pt) no leitor interno', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      await tester.tap(find.text('Guia do Utilizador'));
      await settleAfterTap(tester);

      expect(find.byType(DocReaderScreen), findsOneWidget);
      // Markdown embutido renderizado: h1 do guia em português.
      expect(find.textContaining('Guia do Utilizador — TAREQO'), findsOneWidget);
    });

    testWidgets('abre a Solução de problemas (pt) no leitor interno', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      await tester.tap(find.text('Solução de problemas'));
      await settleAfterTap(tester);

      expect(find.byType(DocReaderScreen), findsOneWidget);
      expect(find.textContaining('Solução de Problemas — TAREQO'), findsOneWidget);
    });

    testWidgets('busca filtra os tópicos e o estado vazio aparece', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      // Filtra por "guia" — só o Guia do Utilizador permanece.
      await tester.enterText(find.byType(TextField), 'guia');
      await tester.pump();

      expect(find.text('Guia do Utilizador'), findsOneWidget);
      expect(find.text('Solução de problemas'), findsNothing);
      expect(find.text('Fale com o suporte'), findsNothing);
      // Rodapé some durante a busca (estado filtrado).
      expect(find.text('Central de ajuda'), findsNothing);

      // Busca sem acento encontra "Solução" (normalização).
      await tester.enterText(find.byType(TextField), 'solucao');
      await tester.pump();

      expect(find.text('Solução de problemas'), findsOneWidget);
      expect(find.text('Guia do Utilizador'), findsNothing);

      // Termo sem correspondência → estado vazio.
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('Nenhum resultado'), findsOneWidget);

      // Limpar a busca restaura a lista completa + rodapé.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('Guia do Utilizador'), findsOneWidget);
      expect(find.text('Solução de problemas'), findsOneWidget);
      expect(find.text('Fale com o suporte'), findsOneWidget);
      expect(find.text('Central de ajuda'), findsOneWidget);
    });

    testWidgets('busca por hint do suporte encontra o tile de contato', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      await tester.enterText(find.byType(TextField), 'equipe');
      await tester.pump();

      expect(find.text('Fale com o suporte'), findsOneWidget);
      expect(find.text('Guia do Utilizador'), findsNothing);
    });

    testWidgets('no idioma inglês abre o documento em inglês', (tester) async {
      await tester.pumpWidget(
        testApp(locale: const Locale('en'), home: const SupportScreen()),
      );

      // Hub em inglês.
      expect(find.text('Help'), findsOneWidget);
      await tester.tap(find.text('Troubleshooting'));
      await settleAfterTap(tester);

      // h1 do troubleshooting em inglês.
      expect(find.textContaining('Troubleshooting — TAREQO'), findsOneWidget);
    });
  });
}

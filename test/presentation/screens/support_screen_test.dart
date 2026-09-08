import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
        'docs/pt/GUIA_DO_USUARIO.md',
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
        'docs/pt/GUIA_DO_USUARIO.md',
      );
      expect(
        SupportDocument.troubleshooting.assetPath('zz'),
        'docs/pt/TROUBLESHOOTING.md',
      );
    });
  });

  group('SupportScreen (Ajuda)', () {
    testWidgets('lista o Guia do Usuário e o Troubleshooting', (tester) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      expect(find.text('Ajuda'), findsOneWidget); // AppBar
      expect(find.text('Guia do Usuário'), findsOneWidget);
      expect(
        find.text('Troubleshooting'),
        findsOneWidget,
      ); // Dicas de cada documento (hints) presentes.
      expect(find.textContaining('Login, lojas, produtos'), findsOneWidget);
      expect(find.textContaining('Problemas comuns: login'), findsOneWidget);
    });

    testWidgets('abre o Guia do Usuário (pt) no leitor interno', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      await tester.tap(find.text('Guia do Usuário'));
      await settleAfterTap(tester);

      expect(find.byType(DocReaderScreen), findsOneWidget);
      // Markdown embutido renderizado: h1 do guia em português.
      expect(find.textContaining('Guia do Usuário — TAREQO'), findsOneWidget);
    });

    testWidgets('abre o Troubleshooting (pt) no leitor interno', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(home: const SupportScreen()));

      await tester.tap(find.text('Troubleshooting'));
      await settleAfterTap(tester);

      expect(find.byType(DocReaderScreen), findsOneWidget);
      expect(find.textContaining('Troubleshooting — TAREQO'), findsOneWidget);
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

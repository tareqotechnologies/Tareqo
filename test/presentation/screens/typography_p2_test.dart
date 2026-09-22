import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';

/// Testes P2 da auditoria tipográfica:
///
/// - **P2-A · Escala de texto 2.0 no PDV** — o
///   `accessibility_text_scale_test.dart` cobria só o login; o PDV
///   ([NewSaleSheet]) é a superfície de maior frequência e concentra os
///   `SmartAmount` com FittedBox (que degrada silenciosamente com escala
///   alta: reduz o texto em vez de falhar).
/// - **P2-B · Overflow em francês** — fr é mais longo que pt nas mesmas
///   strings (`salesCartSection` fr: "Panier · …", `salesConfirm` fr:
///   "Confirmer la vente"); telas densas a 360dp (celular pequeno real)
///   exercitam `maxLines: 1` e FittedBox no limite.
/// - **P2-C · Cobertura de glifos da Inter** — parse do cmap dos dois TTFs
///   embutidos (variável da UI + Bold estático dos PDFs) contra os
///   caracteres reais dos três ARBs + símbolos de moeda do `Formatters`.
///   Falha se uma tradução nova introduzir caractere que a Inter não tem
///   (tofu ou fallback de sistema em produção).
void main() {
  setUpAll(() async {
    // Mesma carga de fonte dos goldens: os testes usam o tema real do app
    // (AppTheme.dark/light), que referencia a família 'Inter'.
    final bytes = File('assets/fonts/Inter-Variable.ttf').readAsBytesSync();
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  group('P2-A — PDV com escala de texto 2.0', () {
    setUp(() => AppClock.inject(() => kGoldenNow));
    tearDown(AppClock.reset);

    testWidgets('dark: renderiza sem overflow; ação principal alcançável', (
      tester,
    ) async {
      usePortraitViewport(tester, size: const Size(412, 915));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(newSaleGoldenApp(theme: AppTheme.dark));
      await tester.pumpAndSettle();

      // Sem exceções de layout (RenderFlex overflow falha o teste sozinho;
      // isto assegura que nenhuma foi engolida por um builder assíncrono).
      expect(tester.takeException(), isNull);

      // A ação principal existe, está posicionada na viewport e segue
      // hit-testável (não empurrada para fora por conteúdo que não encolhe).
      final confirmFinder = find.byWidgetPredicate(
        (w) => w is AppButton && w.label == 'Confirmar venda',
      );
      expect(confirmFinder, findsOneWidget);
      final rect = tester.getRect(confirmFinder);
      expect(rect.bottom, lessThanOrEqualTo(915),
          reason: 'botão Confirmar empurrado para fora da viewport na escala 2.0');
      expect(rect.top, greaterThanOrEqualTo(0));
    });

    testWidgets('light: renderiza sem overflow', (tester) async {
      usePortraitViewport(tester, size: const Size(412, 915));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(newSaleGoldenApp(theme: AppTheme.light));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.label == 'Confirmar venda',
        ),
        findsOneWidget,
      );
    });
  });

  group('P2-B — overflow em francês (360dp)', () {
    testWidgets('PDV em fr a 360dp sem exceções de layout', (tester) async {
      usePortraitViewport(tester, size: const Size(360, 800));
      await tester.pumpWidget(newSaleGoldenApp(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Prova de locale fr (não caiu no fallback pt): o botão de confirmação
      // usa o rótulo francês. ("Panier · …" só renderiza com carrinho
      // não-vazio — o golden nasce vazio.)
      expect(
        find.byWidgetPredicate(
          (w) => w is AppButton && w.label == 'Confirmer la vente',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'dashboard em fr a 360dp sem exceções de layout',
      (tester) async {
        usePortraitViewport(tester, size: const Size(360, 800));
        await tester.pumpWidget(dashboardGoldenApp(locale: const Locale('fr')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Rótulos fr longos presentes — a tela carregou em francês (não
        // caiu no fallback pt). "Activité du jour" fica abaixo do fold em
        // 800px; o greeting e as métricas são a prova visível.
        expect(find.textContaining('Bonjour'), findsOneWidget);
        expect(find.text('Ventes'), findsWidgets);
        expect(find.text('Caisse'), findsOneWidget);
      },
    );
  });

  group('P2-C — cobertura de glifos da Inter (cmap)', () {
    final required = _uiCharacters();

    test('conjunto de caracteres extraído não é trivialmente pequeno', () {
      // Guarda do próprio teste: se a extração quebrar (arbs movidos etc.),
      // falha aqui em vez de passar com conjunto vazio.
      expect(required.length, greaterThan(80));
    });

    for (final fontPath in const [
      'assets/fonts/Inter-Variable.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ]) {
      test('$fontPath cobre todos os caracteres da UI (pt/en/fr + moedas)', () {
        final cmap = _parseCmap(File(fontPath).readAsBytesSync());
        expect(cmap, isNotEmpty, reason: 'cmap não parseado em $fontPath');

        final missing = required
            .where((c) => !cmap.contains(c.codeUnitAt(0)))
            .toList();
        expect(
          missing,
          isEmpty,
          reason: 'Glifos ausentes em $fontPath: '
              '${missing.map((c) => '$c (U+${c.codeUnitAt(0).toRadixString(16)})').join(', ')}',
        );
      });
    }

    test('Inter-Bold tem os mesmos glifos essenciais da variável', () {
      final variable = _parseCmap(
        File('assets/fonts/Inter-Variable.ttf').readAsBytesSync(),
      );
      final bold = _parseCmap(
        File('assets/fonts/Inter-Bold.ttf').readAsBytesSync(),
      );
      final missingInBold = required
          .map((c) => c.codeUnitAt(0))
          .where((cp) => !bold.contains(cp) && variable.contains(cp))
          .toList();
      expect(
        missingInBold,
        isEmpty,
        reason: 'Bold estático não pode ter menos glifos que a variável '
            '(mesma versão upstream 4.001 — regressão de asset)',
      );
    });

    // Mono (família 'monospace' — Roboto Mono variável): usada em IDs,
    // código MFA (base32) e snippets do leitor de ajuda — conteúdo ASCII.
    test('assets/fonts/RobotoMono-Variable.ttf cobre o ASCII da UI mono', () {
      final cmap = _parseCmap(
        File('assets/fonts/RobotoMono-Variable.ttf').readAsBytesSync(),
      );
      expect(cmap, isNotEmpty, reason: 'cmap não parseado');

      // Core ASCII de IDs/códigos/snippets: alfanumérico + pontuação
      // comum de código e separadores de ID (uuid, base32, comandos).
      const monoSet =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
          ' -_.:/+#()[]=';
      final missing = monoSet
          .split('')
          .where((c) => !cmap.contains(c.codeUnitAt(0)))
          .toList();
      expect(
        missing,
        isEmpty,
        reason: 'Glifos ausentes na mono: '
            '${missing.map((c) => '$c (U+${c.codeUnitAt(0).toRadixString(16)})').join(', ')}',
      );
    });
  });
}

// ── Extração dos caracteres reais da UI ─────────────────────────────────────

/// Caracteres das traduções (valores dos 3 arbs) + símbolos de moeda do
/// `Formatters` + separadores de número que o intl pode inserir.
///
/// Allowlist documentada: `═` (U+2550) dos cabeçalhos de WhatsApp
/// (`customInvoiceWhatsAppHeader`/`quotationWhatsAppHeader`) é texto enviado
/// por mensagem — nunca renderizado pela Inter dentro do app.
Set<String> _uiCharacters() {
  const arbs = [
    'lib/l10n/app_pt.arb',
    'lib/l10n/app_en.arb',
    'lib/l10n/app_fr.arb',
  ];
  final chars = <String>{};
  for (final path in arbs) {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    _collectStrings(data, chars);
  }
  // Símbolos de moeda do Formatters (formatters.dart, _currencySymbols).
  chars.addAll('R\$US\u20ACMZ'.split(''));
  // Separadores de número usados pelo intl por locale (fr usa NNBSP/nbsp).
  chars.addAll(['\u00A0', '\u202F']);
  // Texto enviado por mensagem, nunca renderizado pela fonte da UI:
  chars.remove('═');
  chars.removeWhere((c) => c.codeUnitAt(0) < 32); // controles
  return chars;
}

void _collectStrings(Object? node, Set<String> out) {
  if (node is String) {
    out.addAll(node.split(''));
  } else if (node is Map) {
    for (final entry in node.entries) {
      if (entry.key is String && (entry.key as String).startsWith('@')) {
        continue; // metadados (@description etc.) não são UI
      }
      _collectStrings(entry.value, out);
    }
  }
}

// ── Parser mínimo de cmap (formatos 4 e 12) — sem dependências ──────────────

/// Code points mapeados no TTF. Suporta subtables formato 4 (BMP) e 12 —
/// suficiente para Latin/Latin-Ext; os demais formatos da Inter cobrem os
/// mesmos rangos e não adicionam code points para a UI.
Set<int> _parseCmap(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  int u16(int o) => data.getUint16(o);
  int u32(int o) => data.getUint32(o);

  final numTables = u16(4);
  int? cmapOff;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'cmap') {
      cmapOff = u32(rec + 8);
      break;
    }
  }
  if (cmapOff == null) return {};

  final nSub = u16(cmapOff + 2);
  final cps = <int>{};
  for (var i = 0; i < nSub; i++) {
    final rec = cmapOff + 4 + i * 8;
    final sub = cmapOff + u32(rec + 4);
    switch (u16(sub)) {
      case 4: // BMP, Windows Unicode
        final segX2 = u16(sub + 6);
        final segCount = segX2 ~/ 2;
        final endB = sub + 14;
        final startB = endB + segX2 + 2;
        final deltaB = startB + segX2;
        final rangeB = deltaB + segX2;
        for (var s = 0; s < segCount; s++) {
          final end = u16(endB + s * 2);
          final start = u16(startB + s * 2);
          final delta = u16(deltaB + s * 2);
          final ro = u16(rangeB + s * 2);
          if (start == 0xFFFF) continue;
          for (var c = start; c <= end && c != 0x10000; c++) {
            if (ro == 0) {
              if ((c + delta) & 0xFFFF != 0) cps.add(c);
            } else {
              final gi = rangeB + s * 2 + ro + (c - start) * 2;
              if (gi + 1 < bytes.length && u16(gi) != 0) cps.add(c);
            }
          }
        }
      case 12: // Full Unicode
        final nGroups = u32(sub + 12);
        for (var g = 0; g < nGroups; g++) {
          final rec2 = sub + 16 + g * 12;
          final start = u32(rec2);
          final end = u32(rec2 + 4);
          if (end - start > 0x10FFFF) continue; // sanidade
          for (var c = start; c <= end; c++) {
            cps.add(c);
          }
        }
    }
  }
  return cps;
}

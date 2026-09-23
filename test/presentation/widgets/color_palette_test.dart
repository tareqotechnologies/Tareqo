import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/l10n/generated/app_localizations_en.dart';
import 'package:tareqo/l10n/generated/app_localizations_pt.dart';
import 'package:tareqo/presentation/widgets/color_palette.dart';

/// Trava a paleta profissional usada pelas facturas personalizadas e
/// cotações: as 8 chaves estáveis (pt) com os hexadecimais da paleta RE2
/// (ver `lib/core/theme/app_colors.dart`) e a resolução localizada do
/// nome exibido ([paletteColorName]). RE2: a paleta NÃO tem verde — o
/// antigo swatch #16A34A saiu do sistema.
void main() {
  group('kColorPalettes', () {
    test('expõe as 8 cores estáveis da paleta RE2', () {
      expect(kColorPalettes, hasLength(8));
    });

    test('chaves estáveis mapeiam para os hexadecimais da paleta RE2', () {
      expect(kColorPalettes['Petroleo'], const Color(0xFF10282A));
      expect(kColorPalettes['Slate'], const Color(0xFF3D4D55));
      expect(kColorPalettes['Terracota'], const Color(0xFFB58863));
      expect(kColorPalettes['Bege'], const Color(0xFFD3C3B9));
      expect(kColorPalettes['Cinza quente'], const Color(0xFFA79E9C));
      expect(kColorPalettes['Tinta petroleo'], const Color(0xFF2E6E75));
      expect(kColorPalettes['Tinta slate'], const Color(0xFF2C3E45));
      expect(kColorPalettes['Preto suave'], const Color(0xFF161616));
    });

    test('nenhum swatch é verde (regra RE2: sem verde no sistema)', () {
      // Guard de regressão: se alguém reintroduzir o verde da paleta
      // antiga (#16A34A/#22C55E), este teste falha antes do release.
      for (final color in kColorPalettes.values) {
        expect(color, isNot(const Color(0xFF16A34A)));
        expect(color, isNot(const Color(0xFF22C55E)));
      }
    });
  });

  group('paletteColorName', () {
    final pt = AppLocalizationsPt();
    final en = AppLocalizationsEn();

    test('resolve cada chave da paleta para o nome localizado (pt)', () {
      expect(paletteColorName('Petroleo', pt), pt.palettePetrol);
      expect(paletteColorName('Slate', pt), pt.paletteSlate);
      expect(paletteColorName('Terracota', pt), pt.paletteTerracotta);
      expect(paletteColorName('Bege', pt), pt.paletteBeige);
      expect(paletteColorName('Cinza quente', pt), pt.paletteWarmGray);
      expect(paletteColorName('Tinta petroleo', pt), pt.palettePetrolInk);
      expect(paletteColorName('Tinta slate', pt), pt.paletteSlateInk);
    });

    test('Preto suave (na paleta, fora do switch) cai no rótulo padrão', () {
      expect(paletteColorName('Preto suave', pt), pt.paletteSoftBlack);
      expect(paletteColorName('Preto suave', en), en.paletteSoftBlack);
    });

    test('chave desconhecida cai no rótulo padrão (Preto suave)', () {
      expect(paletteColorName('Magenta', pt), pt.paletteSoftBlack);
      expect(paletteColorName('', pt), pt.paletteSoftBlack);
    });

    test('nome troca de idioma conforme o locale (en)', () {
      expect(paletteColorName('Petroleo', en), en.palettePetrol);
      expect(paletteColorName('Slate', en), en.paletteSlate);
      // O texto em en difere do rótulo do catálogo (pt).
      expect(paletteColorName('Petroleo', en), isNot(pt.palettePetrol));
    });
  });
}

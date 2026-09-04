import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/l10n/generated/app_localizations_en.dart';
import 'package:tareqo/l10n/generated/app_localizations_pt.dart';
import 'package:tareqo/presentation/widgets/color_palette.dart';

/// Trava a paleta profissional usada pelas facturas personalizadas e
/// cotações: as 8 chaves estáveis (pt) com os hexadecimais do design
/// system e a resolução localizada do nome exibido ([paletteColorName]).
void main() {
  group('kColorPalettes', () {
    test('expõe as 8 cores estáveis da paleta profissional', () {
      expect(kColorPalettes, hasLength(8));
    });

    test('chaves estáveis mapeiam para os hexadecimais do design system', () {
      expect(kColorPalettes['Azul'], const Color(0xFF2563EB));
      expect(kColorPalettes['Verde'], const Color(0xFF16A34A));
      expect(kColorPalettes['Vermelho'], const Color(0xFFDC2626));
      expect(kColorPalettes['Âmbar'], const Color(0xFFD97706));
      expect(kColorPalettes['Slate'], const Color(0xFF475569));
      expect(kColorPalettes['Violeta'], const Color(0xFF7C3AED));
      expect(kColorPalettes['Teal'], const Color(0xFF0D9488));
      expect(kColorPalettes['Indigo'], const Color(0xFF4338CA));
    });
  });

  group('paletteColorName', () {
    final pt = AppLocalizationsPt();
    final en = AppLocalizationsEn();

    test('resolve cada chave da paleta para o nome localizado (pt)', () {
      expect(paletteColorName('Azul', pt), pt.paletteBlue);
      expect(paletteColorName('Verde', pt), pt.paletteGreen);
      expect(paletteColorName('Vermelho', pt), pt.paletteRed);
      expect(paletteColorName('Âmbar', pt), pt.paletteAmber);
      expect(paletteColorName('Slate', pt), pt.paletteSlate);
      expect(paletteColorName('Violeta', pt), pt.paletteViolet);
      expect(paletteColorName('Teal', pt), pt.paletteTeal);
    });

    test('Indigo (na paleta, fora do switch) cai no rótulo de Indigo', () {
      expect(paletteColorName('Indigo', pt), pt.paletteIndigo);
      expect(paletteColorName('Indigo', en), en.paletteIndigo);
    });

    test('chave desconhecida cai no rótulo padrão (Indigo)', () {
      expect(paletteColorName('Magenta', pt), pt.paletteIndigo);
      expect(paletteColorName('', pt), pt.paletteIndigo);
    });

    test('nome troca de idioma conforme o locale (en)', () {
      expect(paletteColorName('Azul', en), en.paletteBlue);
      expect(paletteColorName('Slate', en), en.paletteSlate);
      // O texto em en difere do rótulo do catálogo (pt).
      expect(paletteColorName('Azul', en), isNot(pt.paletteBlue));
    });
  });
}

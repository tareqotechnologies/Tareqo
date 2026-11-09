import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_colors.dart';
import 'package:tareqo/l10n/generated/app_localizations_en.dart';
import 'package:tareqo/l10n/generated/app_localizations_pt.dart';
import 'package:tareqo/presentation/widgets/color_palette.dart';

/// Trava a paleta OFICIAL (4 cores) usada pelas facturas personalizadas
/// e cotações: Laranja #FF6A2A, Cinza de superfície #F0F0F0,
/// Branco suave #F9F9F9, Preto #0C0B0A.
void main() {
  group('kColorPalettes', () {
    test('expõe as 4 cores oficiais', () {
      expect(kColorPalettes, hasLength(4));
    });

    test('valores são exatamente a paleta oficial', () {
      expect(kColorPalettes['Preto'], AppColors.brandBlack);
      expect(kColorPalettes['Cinza'], AppColors.surfaceGray);
      expect(kColorPalettes['Terracota'], AppColors.brandOrange);
      expect(kColorPalettes['Branco gelo'], AppColors.softWhite);
    });

    test('nenhuma cor fora da paleta oficial é permitida', () {
      final allowed = {
        AppColors.brandOrange,
        AppColors.surfaceGray,
        AppColors.softWhite,
        AppColors.brandBlack,
      };
      for (final color in kColorPalettes.values) {
        expect(allowed, contains(color));
      }
    });
  });

  group('paletteColorName', () {
    final pt = AppLocalizationsPt();
    final en = AppLocalizationsEn();

    test('resolve as 4 chaves oficiais', () {
      expect(paletteColorName('Preto', pt), pt.paletteSoftBlack);
      expect(paletteColorName('Cinza', pt), pt.paletteWarmGray);
      expect(paletteColorName('Terracota', pt), pt.paletteTerracotta);
      expect(paletteColorName('Branco gelo', pt), pt.paletteBeige);
    });

    test('chave desconhecida cai no rótulo padrão (Preto)', () {
      expect(paletteColorName('Magenta', pt), pt.paletteSoftBlack);
      expect(paletteColorName('', pt), pt.paletteSoftBlack);
    });

    test('nome troca de idioma conforme o locale (en)', () {
      expect(paletteColorName('Preto', en), en.paletteSoftBlack);
      expect(paletteColorName('Terracota', en), en.paletteTerracotta);
    });
  });
}

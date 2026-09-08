import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_colors.dart';

/// Trava as cores semânticas fora do [ColorScheme]: resolução estática por
/// brilho ([AppColors.of]/`errorOf`/`successOf`/`warningOf`), o
/// [ThemeExtension] [AppStatusColors] (pares claro/escuro, `copyWith`,
/// `lerp`) e os acessores ergonómicos `Theme.of(context).income/expense/
/// warning/accent` com fallback para a resolução estática.
void main() {
  group('AppColors — resolução por brilho', () {
    const dark = Color(0xFF111111);
    const light = Color(0xFFEEEEEE);

    test('of devolve a variante conforme o brilho', () {
      expect(AppColors.of(Brightness.dark, dark, light), dark);
      expect(AppColors.of(Brightness.light, dark, light), light);
    });

    test('errorOf: vermelho claro no modo claro, luminoso no escuro', () {
      expect(AppColors.errorOf(Brightness.light), AppColors.statusError);
      expect(AppColors.errorOf(Brightness.dark), const Color(0xFFF87171));
    });

    test('successOf: verde médio (AA) no claro, verde vivo no escuro', () {
      expect(AppColors.successOf(Brightness.light), AppColors.successLight);
      expect(AppColors.successOf(Brightness.dark), AppColors.success);
    });

    test('warningOf: âmbar escuro no claro, luminoso no escuro', () {
      expect(AppColors.warningOf(Brightness.light), AppColors.warningLight);
      expect(AppColors.warningOf(Brightness.dark), const Color(0xFFFBBF24));
    });
  });

  group('AppStatusColors (ThemeExtension)', () {
    test('variantes claro e escuro usam os pares semânticos', () {
      expect(AppStatusColors.dark.income, AppColors.income);
      expect(AppStatusColors.dark.expense, AppColors.expense);
      expect(AppStatusColors.dark.warning, AppColors.warning);
      expect(AppStatusColors.dark.accent, AppColors.accent);

      expect(AppStatusColors.light.income, AppColors.incomeLight);
      expect(AppStatusColors.light.expense, AppColors.expenseLight);
      expect(AppStatusColors.light.warning, AppColors.warningLight);
      expect(AppStatusColors.light.accent, AppColors.accentLight);
    });

    test('copyWith sem argumentos devolve cópia idêntica', () {
      final copy = AppStatusColors.dark.copyWith();
      expect(copy.income, AppStatusColors.dark.income);
      expect(copy.expense, AppStatusColors.dark.expense);
      expect(copy.warning, AppStatusColors.dark.warning);
      expect(copy.accent, AppStatusColors.dark.accent);
    });

    test('copyWith troca apenas o campo informado', () {
      const newIncome = Color(0xFF000000);
      final copy = AppStatusColors.dark.copyWith(income: newIncome);
      expect(copy.income, newIncome);
      expect(copy.expense, AppStatusColors.dark.expense);
      expect(copy.warning, AppStatusColors.dark.warning);
      expect(copy.accent, AppStatusColors.dark.accent);
    });

    test('lerp com outro null devolve a própria instância', () {
      final result = AppStatusColors.dark.lerp(null, 0.5);
      expect(result, same(AppStatusColors.dark));
    });

    test('lerp interpola cada campo entre as duas variantes', () {
      final result = AppStatusColors.dark.lerp(AppStatusColors.light, 0.5);
      expect(
        result.income,
        Color.lerp(AppColors.income, AppColors.incomeLight, 0.5),
      );
      expect(
        result.expense,
        Color.lerp(AppColors.expense, AppColors.expenseLight, 0.5),
      );
      expect(
        result.warning,
        Color.lerp(AppColors.warning, AppColors.warningLight, 0.5),
      );
      expect(
        result.accent,
        Color.lerp(AppColors.accent, AppColors.accentLight, 0.5),
      );
    });

    test('lerp nos extremos devolve a variante correspondente', () {
      expect(
        AppStatusColors.dark.lerp(AppStatusColors.light, 0).income,
        AppColors.income,
      );
      expect(
        AppStatusColors.dark.lerp(AppStatusColors.light, 1).income,
        AppColors.incomeLight,
      );
    });
  });

  group('AppColorsTheme (acessores no ThemeData)', () {
    test('usa o AppStatusColors registado no tema', () {
      final theme = ThemeData(
        brightness: Brightness.dark,
        extensions: const [AppStatusColors.dark],
      );
      expect(theme.income, AppColors.income);
      expect(theme.expense, AppColors.expense);
      expect(theme.warning, AppColors.warning);
      expect(theme.accent, AppColors.accent);
    });

    test('sem extensão registada cai na resolução estática por brilho', () {
      final lightTheme = ThemeData(brightness: Brightness.light);
      expect(lightTheme.income, AppColors.incomeLight);
      expect(lightTheme.expense, AppColors.expenseLight);
      expect(lightTheme.warning, AppColors.warningLight);
      expect(lightTheme.accent, AppColors.accentLight);

      final darkTheme = ThemeData(brightness: Brightness.dark);
      expect(darkTheme.income, AppColors.income);
      expect(darkTheme.expense, AppColors.expense);
      expect(darkTheme.warning, AppColors.warning);
      expect(darkTheme.accent, AppColors.accent);
    });
  });
}

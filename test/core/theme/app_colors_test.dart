import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_colors.dart';

void main() {
  group('AppColors — semantic pairs', () {
    test('light and dark variants use the semantic pairs', () {
      expect(AppStatusColors.dark.income, AppColors.incomeDark);
      expect(AppStatusColors.dark.expense, AppColors.expenseDark);
      expect(AppStatusColors.dark.warning, AppColors.darkWarningText);
      expect(AppStatusColors.dark.accent, AppColors.accentDark);
      // modo claro: income/expense entram no par Light (leitura sobre a superfície)
      expect(AppStatusColors.light.income, AppColors.incomeLight);
      expect(AppStatusColors.light.expense, AppColors.expenseLight);
      expect(AppStatusColors.light.warning, AppColors.warningText);
      expect(AppStatusColors.light.accent, AppColors.accentOrange);
    });

    test('incomeLight/expenseLight sao a variante legivel (sucesso/erro) no modo claro', () {
      expect(AppColors.incomeLight, AppColors.successText);
      expect(AppColors.expenseLight, AppColors.errorNeutral);
    });

    test('lerp with null returns the same instance', () {
      final result = AppStatusColors.dark.lerp(null, 0.5);
      expect(result, same(AppStatusColors.dark));
    });

    test('lerp interpolates each field between the two variants', () {
      final result = AppStatusColors.dark.lerp(AppStatusColors.light, 0.5);
      expect(result.income, Color.lerp(AppStatusColors.dark.income, AppStatusColors.light.income, 0.5));
      expect(result.expense, Color.lerp(AppStatusColors.dark.expense, AppStatusColors.light.expense, 0.5));
      expect(result.warning, Color.lerp(AppStatusColors.dark.warning, AppStatusColors.light.warning, 0.5));
      expect(result.accent, Color.lerp(AppStatusColors.dark.accent, AppStatusColors.light.accent, 0.5));
      expect(result.incomeLight, Color.lerp(AppStatusColors.dark.incomeLight, AppStatusColors.light.incomeLight, 0.5));
      expect(result.expenseLight, Color.lerp(AppStatusColors.dark.expenseLight, AppStatusColors.light.expenseLight, 0.5));
      expect(result.warningLight, Color.lerp(AppStatusColors.dark.warningLight, AppStatusColors.light.warningLight, 0.5));
      expect(result.accentLight, Color.lerp(AppStatusColors.dark.accentLight, AppStatusColors.light.accentLight, 0.5));
    });

    test('lerp at extremes returns first/last variant', () {
      final t0 = AppStatusColors.dark.lerp(AppStatusColors.light, 0);
      final t1 = AppStatusColors.dark.lerp(AppStatusColors.light, 1);
      expect(t0.income, AppStatusColors.dark.income);
      expect(t0.expense, AppStatusColors.dark.expense);
      expect(t0.warning, AppStatusColors.dark.warning);
      expect(t0.accent, AppStatusColors.dark.accent);
      expect(t1.income, AppStatusColors.light.income);
      expect(t1.expense, AppStatusColors.light.expense);
      expect(t1.warningLight, AppStatusColors.light.warningLight);
      expect(t1.accentLight, AppStatusColors.light.accentLight);
    });
  });
}

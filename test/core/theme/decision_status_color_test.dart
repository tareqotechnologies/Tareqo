import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_colors.dart';

/// Trava o mapeamento compartilhado de cor por status de decisão
/// (`AppColors.decisionStatusColor`) — fonte única usada pelas telas admin
/// (tenants, auditoria e dashboard) em vez dos switches duplicados.
void main() {
  group('AppColors.decisionStatusColor', () {
    test('approved mapeia para a cor de sucesso', () {
      expect(AppColors.decisionStatusColor('approved'), AppColors.success);
    });

    test('rejected mapeia para statusError', () {
      expect(AppColors.decisionStatusColor('rejected'), AppColors.statusError);
    });

    test('pending mapeia para statusWarning', () {
      expect(AppColors.decisionStatusColor('pending'), AppColors.statusWarning);
    });

    test('desconhecido ou null cai no cinza neutro (sem papel de cor)', () {
      expect(AppColors.decisionStatusColor(null), Colors.grey);
      expect(AppColors.decisionStatusColor('anything-else'), Colors.grey);
      expect(AppColors.decisionStatusColor(''), Colors.grey);
    });
  });
}

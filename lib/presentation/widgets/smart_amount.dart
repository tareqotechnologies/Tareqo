import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Exibição de moeda com AUTO-SIZE (design system ultra-clean).
///
/// O valor em CENTAVOS ([cents], convenção W4) é formatado com a moeda do
/// tenant ([Formatters.currency]) e o texto ENCOLHE ([FittedBox] scaleDown)
/// para SEMPRE caber na largura disponível — nunca trunca nem estoura,
/// mesmo com valores grandes (ex.: "MZN 12.345.678,90") ou escala de texto
/// alta. Um único ponto de renderização de valores monetários: os KPIs,
/// totais de carrinho e resumos usam o mesmo componente.
class SmartAmount extends StatelessWidget {
  const SmartAmount({
    super.key,
    required this.cents,
    this.prefix = '',
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  /// Valor em CENTAVOS inteiros (W4 — soma exata, sem double).
  final int cents;

  /// Prefixo opcional ANTES do valor (ex.: `'+ '`/`'- '` para o sinal das
  /// movimentações do Financeiro) — o auto-size cobre o texto completo.
  final String prefix;

  /// Estilo do valor (ex.: `headlineSmall`, `titleLarge`).
  final TextStyle? style;

  /// Alinhamento quando o texto encolhe além do espaço disponível.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        '$prefix${Formatters.currency(cents)}',
        maxLines: 1,
        style: style,
      ),
    );
  }
}

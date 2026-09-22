import 'package:flutter/material.dart';

/// Texto NUMÉRICO do design system — `tabularFigures` embutido.
///
/// A auditoria tipográfica (P1) identificou 21+ cópias manuais de
/// `fontFeatures: [FontFeature.tabularFigures()]` espalhadas porque os
/// papéis de label (`titleSmall`, `labelLarge/Medium/Small`) não carregam
/// tabular no tema — e quantidades, percentagens, contagens e números de
/// documento alinham dígito a dígito igual aos valores monetários.
///
/// Regra prática (mesma do SmartAmount para dinheiro):
/// * o texto É um número (quantidade, %, nº sequencial, contagem, data em
///   tabela) → [NumText];
/// * o texto É dinheiro → [SmartAmount] (formata + tabular + auto-size);
/// * outro texto → `Text` normal (o tabular em texto corrido é inócuo,
///   mas não ajuda — não force).
///
/// O merge preserva o tabular mesmo quando o chamador passa um estilo que
/// já tenha `fontFeatures` próprio (os do tema vencem; o tabular é
/// re-aplicado por último — este widget é a autoridade numérica).
class NumText extends StatelessWidget {
  const NumText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  /// Rótulo para leitores de ecrã (ex.: "3 unidades" em vez de "3").
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    TextStyle? effective = style;
    if (effective != null) {
      effective = effective.copyWith(
        fontFeatures: [
          ...?effective.fontFeatures,
          const FontFeature.tabularFigures(),
        ],
      );
    } else {
      effective = const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      );
    }
    return Text(
      text,
      style: effective,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}

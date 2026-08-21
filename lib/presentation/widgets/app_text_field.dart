import 'package:flutter/material.dart';

/// Campo de texto padrão do design system ultra-clean — minimalista, sem
/// rótulo pesado: borda sutil em repouso (`#222E35`) que muda para o acento
/// suavemente no foco (o [InputDecorationTheme] global anima a cor da borda
/// — o InputDecorator interpola os estados). Sem contorno pesado, com fundo
/// preenchido discreto.
///
/// Envolve um [TextFormField] — `validator` incluso para formulários.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.errorText,
    this.validator,
    this.autofocus = false,
    this.maxLength,
    this.maxLines,
    this.autofillHints,
    this.hintText,
    this.suffixText,
    this.isDense = false,
    this.borderRadius,
    this.style,
    this.labelStyle,
    this.floatingLabelStyle,
    this.decorationHintStyle,
  });

  /// Rótulo do campo (estilo leve — sem peso visual). Nulo para campos
  /// sem rótulo (ex.: busca, que usa apenas o [hintText]).
  final String? label;

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final int? maxLength;

  /// Máximo de linhas (ex.: motivo de rejeição com 3 linhas). `null` =
  /// linha única (padrão do TextFormField).
  final int? maxLines;

  /// Sugestões de preenchimento automático do SO (ex.: email, senha).
  final Iterable<String>? autofillHints;
  final String? hintText;

  /// Texto fixo ao fim do campo (ex.: unidade `kg` no diálogo de
  /// quantidade decimal).
  final String? suffixText;
  final bool isDense;

  /// Cantos do campo — telas "premium" passam raios maiores (ex.: 14)
  /// para o visual Apple; `null` segue o InputDecorationTheme global (12).
  final BorderRadius? borderRadius;

  /// Estilo do texto digitado — permite reduzir o fontSize nos
  /// formulários densos (ex.: adicionar/editar produto).
  final TextStyle? style;

  /// Estilo do rótulo (label) — sobrepõe o tema global quando fornecido.
  final TextStyle? labelStyle;

  /// Estilo do rótulo flutuante — sobrepõe o tema global quando fornecido.
  final TextStyle? floatingLabelStyle;

  /// Estilo do hintText — sobrepõe o tema global quando fornecido.
  final TextStyle? decorationHintStyle;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: style,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLength: maxLength,
      // `?? 1` explícito: o TextFormField faz `assert(!obscureText ||
      // maxLines == 1)` e `null` quebra a asserção em campos de senha.
      maxLines: maxLines ?? 1,
      autofillHints: autofillHints,
      validator: validator,
      decoration: InputDecoration(
        isDense: isDense,
        labelText: label,
        hintText: hintText,
        labelStyle: labelStyle,
        floatingLabelStyle: floatingLabelStyle,
        hintStyle: decorationHintStyle,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        helperText: helperText,
        errorText: errorText,
        // Cantos customizados (Apple): os 4 borders (repouso, foco, erro)
        // herdam o raio pedido — mesma borda do tema, só o shape muda.
        border: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
        enabledBorder: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
        focusedBorder: radius == null
            ? null
            : OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
      ),
    );
  }
}

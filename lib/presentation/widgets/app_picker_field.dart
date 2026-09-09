import 'package:flutter/material.dart';

/// Campo de seleção do design system — wrapper minimalista e REAL sobre
/// [DropdownButtonFormField], para todos os pickers de formulário.
///
/// Padrão:
///  - texto do campo e dos itens em `bodySmall` (13) — a voz do corpo,
///    sem a escala exagerada do padrão M3 (14/w500);
///  - seta M3 pesada substituída pelo chevron fino (18px,
///    `onSurfaceVariant`) usado nas pílulas de período da Home;
///  - menu segue o `popupMenuTheme` global (raio 12, itens 44px,
///    overlay chapado);
///  - sem borda própria: herda o `inputDecorationTheme` global — a mesma
///    cara do [AppTextField].
class AppPickerField<T> extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    this.isExpanded = false,
    this.validator,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  /// Valor ativo (nulo = campo vazio — o hint aparece).
  final T? value;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isExpanded;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: isExpanded,
      items: items,
      onChanged: onChanged,
      validator: validator,
      // Chevron fino (mesmo glifo das pílulas "Hoje ▾") no lugar da seta
      // M3 com fundo cinza.
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurface,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}

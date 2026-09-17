import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import 'app_text_field.dart';

/// Campo de busca minimalista do design system ultra-clean — construído
/// sobre [AppTextField] (mesma borda sutil que acende no foco dos demais
/// campos), com lupa e sem rótulo pesado.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Enter/ ação do teclado (ex.: PDV usa o Enter para dar quick-add por
  /// PLU/código digitado). `null` = sem ação no submit.
  final ValueChanged<String>? onSubmitted;

  /// Dica do campo; se nulo, usa a tradução padrão ("Buscar..."/"Search...").
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      hintText: hintText ?? context.l10n.commonSearch,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      // Cantos 14 (Apple): campo de busca mais arredondado que o padrão.
      borderRadius: BorderRadius.circular(AppRadius.md + 2),
    );
  }
}

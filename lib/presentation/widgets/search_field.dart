import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import 'app_text_field.dart';

/// Campo de busca minimalista do design system ultra-clean — construído
/// sobre [AppTextField] (mesma borda sutil que acende no foco dos demais
/// campos), com lupa e sem rótulo pesado.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Dica do campo; se nulo, usa a tradução padrão ("Buscar..."/"Search...").
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      onChanged: onChanged,
      hintText: hintText ?? context.l10n.commonSearch,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
    );
  }
}

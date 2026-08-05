import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';

/// Campo de busca minimalista (preenchido, arredondado, com lupa).
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText ?? context.l10n.commonSearch,
        prefixIcon: const Icon(Icons.search),
        // Sem borda: o tema já deixa o campo preenchido e arredondado.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

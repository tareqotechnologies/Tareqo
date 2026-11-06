import 'package:flutter/material.dart';

/// Rótulo de seção — padrão único do app.
///
/// Consolida as variantes privadas `_SectionLabel` eliminadas de
/// `custom_invoice_screen`, `quotation_screen` e `store_transfers_screen`
/// (idênticas por hash de 12 linhas). As variantes com ícone (formulário de
/// produto) e uppercase (mensagens admin) têm um design distinto e seguem
/// locais às suas próprias telas.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

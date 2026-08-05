import 'package:flutter/material.dart';

import 'store_selector_bar.dart';

/// Coluna com o seletor de loja ativa no topo e o conteúdo [child] abaixo.
///
/// Usado tanto no `AppShell` (topo de todas as abas) quanto nas telas
/// **empurradas** por cima da casca (Compras, Relatórios, Lojas) — o
/// seletor de loja fica visível e funcional em todas elas, e os providers
/// de módulo reagem à troca de loja automaticamente.
class StoreScopedContent extends StatelessWidget {
  const StoreScopedContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StoreSelectorBar(),
        Expanded(child: child),
      ],
    );
  }
}

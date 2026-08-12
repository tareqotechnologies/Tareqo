import 'package:flutter/material.dart';

/// Contentor do conteúdo do app — consome o SafeArea TOP (Android 15+/16
/// edge-to-edge obrigatório) para que os AppBars das telas não colidam com
/// a barra de status (relógio/notificações).
///
/// Usado tanto no `AppShell` (topo de todas as abas) quanto nas telas
/// **empurradas** por cima da casca (Compras, Relatórios, Lojas). A escolha
/// da loja ativa NÃO mora mais aqui: foi migrada para **Lojas → Ajustes**
/// (seção "Loja ativa") — o banner no topo foi removido do design.
class StoreScopedContent extends StatelessWidget {
  const StoreScopedContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // SafeArea TOP no topo do shell (Android 15+/16 — edge-to-edge
    // obrigatório): sem o consumo do padding, os AppBars colidem com a
    // barra de status (texto por cima do relógio/notificações). O SafeArea
    // aqui também remove o padding do MediaQuery para os descendentes — os
    // AppBars das telas NÃO aplicam padding duplo.
    return SafeArea(bottom: false, child: child);
  }
}

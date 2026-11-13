import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Selo da forma de pagamento — círculo de 40 px com fundo TINTA sólido e
/// ícone BRANCO, o mesmo idioma [IconTone] usado no feed da Home, no painel
/// de Vendas, no menu e nos cabeçalhos de página.
///
/// A identidade do método (cash, cartão, M-Pesa, E-Mola, transferência) fica
/// no ÍCONE; a cor do método é decorativa e não entra no selo — o padrão da
/// app é neutro e monocromático (paleta oficial: só a escala de cinzas).
class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A11y (plano UI/UX — Fase 3.1): o selo é PURAMENTE DECORATIVO — o
    // método é anunciado em texto no card ("M-Pesa · C-00001"). Marcado como
    // tal para o leitor de ecrã NÃO anunciar um círculo vazio antes do
    // conteúdo do card.
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: IconTone.darkBackground(scheme.onSurface),
        ),
        child: Icon(
          icon,
          size: 18,
          color: IconTone.lightForeground(scheme.onSurface),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Selo da forma de pagamento — círculo pleno tintado na cor do método +
/// ícone colorido (estilo feed da Home). Compartilhado pelos cards de Venda
/// e de Compra (dashboard + listas), dando identidade visual a cada método
/// (cash, cartão, M-Pesa, E-Mola, transferência) e tornando a lista
/// escaneável à primeira vista.
///
/// A cor vem de [PaymentMethodAccent] (cores escolhidas para ≥ 3:1 sobre o
/// card nos dois temas — ver auditoria em test/core/theme/theme_contrast_test.dart).
class PaymentMethodBadge extends StatelessWidget {
 const PaymentMethodBadge({
 super.key,
 required this.accent,
 required this.icon,
 });

 final Color accent;
 final IconData icon;

 @override
 Widget build(BuildContext context) {
 return Container(
 width: 42,
 height: 42,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: accent.withValues(alpha: 0.14),
 border: Border.all(color: accent.withValues(alpha: 0.25)),
 ),
 child: Icon(icon, size: 20, color: accent),
 );
 }
}

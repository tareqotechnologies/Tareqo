import 'package:flutter/material.dart';

/// Selo da forma de pagamento — gradiente suave na cor do método + ícone
/// colorido. Compartilhado pelos cards de Venda e de Compra (dashboard +
/// listas), dando identidade visual a cada método (cash, cartão, M-Pesa,
/// E-Mola, transferência) e tornando a lista escaneável à primeira vista.
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Icon(icon, size: 22, color: accent),
    );
  }
}

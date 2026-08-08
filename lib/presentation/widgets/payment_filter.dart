import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/sale.dart';
import '../../l10n/generated/app_localizations.dart';

/// Ícone inteligente por forma de pagamento (dinheiro, cartão, M-Pesa,
/// E-Mola e transferência/bancário) — compartilhado pelos cards de Venda e
/// de Compra.
extension PaymentMethodIcon on PaymentMethod {
  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.debitCard || PaymentMethod.creditCard => Icons.credit_card,
        // Dinheiro móvel: ícones de celular (M-Pesa e E-Mola são carteiras
        // de telemóvel).
        PaymentMethod.mPesa => Icons.phone_android,
        PaymentMethod.eMola => Icons.smartphone,
        PaymentMethod.transfer => Icons.account_balance,
      };
}

/// Cor de destaque por forma de pagamento — usada no selo do card de Venda
/// e de Compra (cash, cartão, M-Pesa, E-Mola e transferência cada um com
/// sua identidade). Tons calibrados para contrastar ≥ 3:1 (ícones) sobre os
/// cards nos DOIS temas: as cores base (escuro) são tons luminosos sobre as
/// superfícies escuras; as variantes `*Light` são tons mais escuros que
/// atingem AA sobre as superfícies claras (mesmo padrão de [AppColors]).
extension PaymentMethodAccent on PaymentMethod {
  Color accent(ThemeData theme) => switch (this) {
        PaymentMethod.cash => theme.income,
        PaymentMethod.debitCard || PaymentMethod.creditCard =>
          theme.colorScheme.primary,
        // Dinheiro móvel de Moçambique: M-Pesa em azul, E-Mola em violeta
        // (distintos entre si e dos demais métodos — escaneabilidade).
        PaymentMethod.mPesa => AppColors.of(
          theme.brightness,
          const Color(0xFF4C9AFF),
          const Color(0xFF1B6AD6),
        ),
        PaymentMethod.eMola => AppColors.of(
          theme.brightness,
          const Color(0xFFB79CFF),
          const Color(0xFF6D4FC4),
        ),
        PaymentMethod.transfer => theme.warning,
      };
}

/// Filtro de forma de pagamento — compartilhado entre as telas de Vendas e
/// Compras.
///
/// Puramente de apresentação: a lista completa vem do provider e o filtro é
/// uma projeção client-side — nenhuma regra de negócio é alterada.
enum PaymentFilter {
  all,
  cash,

  /// Agrupa débito e crédito num único filtro "Cartão".
  card,

  /// Dinheiro móvel de Moçambique (M-Pesa e E-Mola).
  mPesa,
  eMola,
  transfer;

  String label(AppLocalizations l10n) => switch (this) {
        PaymentFilter.all => l10n.periodAll,
        PaymentFilter.cash => l10n.paymentCash,
        PaymentFilter.card => l10n.paymentFilterCard,
        PaymentFilter.mPesa => l10n.paymentMPesa,
        PaymentFilter.eMola => l10n.paymentEMola,
        PaymentFilter.transfer => l10n.paymentTransfer,
      };

  IconData get icon => switch (this) {
        PaymentFilter.all => Icons.apps,
        PaymentFilter.cash => Icons.payments_outlined,
        PaymentFilter.card => Icons.credit_card,
        PaymentFilter.mPesa => Icons.phone_android,
        PaymentFilter.eMola => Icons.smartphone,
        PaymentFilter.transfer => Icons.account_balance,
      };

  bool matches(PaymentMethod method) => switch (this) {
        PaymentFilter.all => true,
        PaymentFilter.cash => method == PaymentMethod.cash,
        PaymentFilter.card =>
          method == PaymentMethod.debitCard || method == PaymentMethod.creditCard,
        PaymentFilter.mPesa => method == PaymentMethod.mPesa,
        PaymentFilter.eMola => method == PaymentMethod.eMola,
        PaymentFilter.transfer => method == PaymentMethod.transfer,
      };
}

/// Chips de forma de pagamento (Material 3) — `Wrap` para quebrar linha em
/// telas estreitas / escala de texto alta, sem overflow.
class PaymentFilterBar extends StatelessWidget {
  const PaymentFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PaymentFilter value;
  final ValueChanged<PaymentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in PaymentFilter.values)
          FilterChip(
            showCheckmark: false,
            avatar: Icon(
              filter.icon,
              size: 16,
              color: value == filter
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(filter.label(l10n)),
            selected: value == filter,
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

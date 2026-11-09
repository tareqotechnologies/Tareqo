import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/sale.dart';
import '../../l10n/generated/app_localizations.dart';
import 'filter_dropdown.dart';

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
    // Cartão: no escuro usa o BEGE da paleta (o primary do tema escuro é
    // o próprio bege — mas o selo do card precisa de um tom mais luminoso
    // para ≥ 3:1 sobre a sobreposição de 22%; calibrado no teste de
    // contraste). No claro, o slate do primário.
    PaymentMethod.debitCard || PaymentMethod.creditCard =>
      theme.brightness == Brightness.light
          ? AppColors.warningText
          : AppColors.darkAccentOrange,
    // Dinheiro móvel de Moçambique: M-Pesa em vermelho de erro, E-Mola
    // em terracota — paleta oficial (alertas são componentes semânticos,
    // nunca decoração geral).
    PaymentMethod.mPesa => AppColors.alertError,
    PaymentMethod.eMola => AppColors.brandOrange,
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
    // Rótulo PRÓPRIO ("Todas") — não reutiliza o "Tudo" do período:
    // a linha de pagamento fica distinta da de período (duas chips
    // "Tudo" empilhadas confundiam a leitura).
    PaymentFilter.all => l10n.paymentFilterAll,
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

/// Seletor de forma de pagamento MINIMALISTA (canvas V3) — um único chip
/// compacto com a forma ativa + chevron ("Todas ▾"); tocar abre o menu.
/// O chip acende (primaryContainer) quando um método não-default está
/// ativo.
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
    final l10n = context.l10n;

    return FilterDropdown<PaymentFilter>(
      icon: Icons.payments_outlined,
      options: PaymentFilter.values,
      selected: value,
      labelOf: (filter) => filter.label(l10n),
      onChanged: onChanged,
    );
  }
}

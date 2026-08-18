import '../../domain/entities/sale.dart';
import '../../l10n/generated/app_localizations.dart';

/// Rótulo localizado da forma de pagamento. O enum [PaymentMethod] mantém um
/// `label` em português para persistência/serialização (descrição de
/// transação no domínio); a tradução exibida na UI vive aqui, na camada de
/// apresentação/i18n.
extension PaymentMethodL10n on PaymentMethod {
 String labelFor(AppLocalizations l10n) => switch (this) {
 PaymentMethod.cash => l10n.paymentCash,
 PaymentMethod.debitCard => l10n.paymentDebitCard,
 PaymentMethod.creditCard => l10n.paymentCreditCard,
 PaymentMethod.mPesa => l10n.paymentMPesa,
 PaymentMethod.eMola => l10n.paymentEMola,
 PaymentMethod.transfer => l10n.paymentTransfer,
 };
}

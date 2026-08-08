import '../../domain/entities/sale.dart';

/// Descrições e categorias de movimentações financeiras **gravadas no
/// banco**, no idioma ativo no momento do registro (escolha do dono do
/// tenant — lido via [Formatters.currentLanguage] pelos casos de uso).
///
/// As RPCs do Supabase (`process_sale`, `register_debt`, `settle_debt`,
/// `process_purchase`) reproduzem **exatamente** estas strings (lendo a
/// coluna `tenants.language`), para os modos local (SQLite/memória) e SaaS
/// gravarem o mesmo texto. Se um lado mudar, o outro deve mudar junto —
/// manter em paralelo com `supabase/schema.sql` (seção 1.11).
abstract final class TransactionDescriptions {
  // ---- Descrições ---------------------------------------------------------

  /// `Venda Dinheiro` (pt) / `Sale — Cash` (en).
  static String sale({
    required String language,
    required PaymentMethod paymentMethod,
  }) {
    final method = paymentMethodName(language, paymentMethod);
    return language == 'en' ? 'Sale — $method' : 'Venda $method';
  }

  /// `Fiado a receber — João` / `Credit to pay — João` (direção pela dívida).
  static String debt({
    required String language,
    required bool isCustomerDebt,
    required String personName,
  }) {
    final prefix = switch ((language, isCustomerDebt)) {
      ('en', true) => 'Credit to receive — ',
      ('en', false) => 'Credit to pay — ',
      (_, true) => 'Fiado a receber — ',
      _ => 'Fiado a pagar — ',
    };
    return '$prefix$personName';
  }

  /// `Recebimento de fiado — João` (pt) / `Credit received — João` (en).
  static String settleDebt({
    required String language,
    required String personName,
  }) {
    final prefix = language == 'en' ? 'Credit received — ' : 'Recebimento de fiado — ';
    return '$prefix$personName';
  }

  /// `Compra — ACME` (pt) / `Purchase — ACME` (en).
  static String purchase({
    required String language,
    required String supplierName,
  }) {
    final prefix = language == 'en' ? 'Purchase — ' : 'Compra — ';
    return '$prefix$supplierName';
  }

  /// Nome localizado da forma de pagamento (espelha a extensão
  /// `PaymentMethodL10n.labelFor`, sem depender de AppLocalizations — o
  /// domínio não pode importar a UI).
  static String paymentMethodName(String language, PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => language == 'en' ? 'Cash' : 'Dinheiro',
      PaymentMethod.debitCard =>
        language == 'en' ? 'Debit card' : 'Cartão de débito',
      PaymentMethod.creditCard =>
        language == 'en' ? 'Credit card' : 'Cartão de crédito',
      // Dinheiro móvel de Moçambique — mesmo nome em pt e en (marca).
      PaymentMethod.mPesa => 'M-Pesa',
      PaymentMethod.eMola => 'E-Mola',
      PaymentMethod.transfer =>
        language == 'en' ? 'Bank transfer' : 'Transferência',
    };
  }

  // ---- Categorias (agrupamento exibido no Financeiro) ---------------------

  /// `Vendas` (pt) / `Sales` (en) — entradas de venda.
  static String saleCategory(String language) =>
      language == 'en' ? 'Sales' : 'Vendas';

  /// `Fiado` (pt) / `Credit` (en) — pendência e quitação de fiado.
  static String debtCategory(String language) =>
      language == 'en' ? 'Credit' : 'Fiado';

  /// `Compras` (pt) / `Purchases` (en) — saídas de compra.
  static String purchaseCategory(String language) =>
      language == 'en' ? 'Purchases' : 'Compras';
}

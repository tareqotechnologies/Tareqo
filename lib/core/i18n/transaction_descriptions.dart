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

 /// `Venda Dinheiro` (pt) / `Sale — Cash` (en) / `Vente — Espèces` (fr).
 static String sale({
 required String language,
 required PaymentMethod paymentMethod,
 }) {
 final method = paymentMethodName(language, paymentMethod);
 return switch (language) {
 'en' => 'Sale — $method',
 'fr' => 'Vente — $method',
 _ => 'Venda $method',
 };
 }

 /// `Fiado a receber — João` / `Credit to pay — João` / `Crédit à
 /// recevoir — João` (direção pela dívida).
 static String debt({
 required String language,
 required bool isCustomerDebt,
 required String personName,
 }) {
 final prefix = switch ((language, isCustomerDebt)) {
 ('en', true) => 'Credit to receive — ',
 ('en', false) => 'Credit to pay — ',
 ('fr', true) => 'Crédit à recevoir — ',
 ('fr', false) => 'Crédit à payer — ',
 (_, true) => 'Fiado a receber — ',
 _ => 'Fiado a pagar — ',
 };
 return '$prefix$personName';
 }

 /// `Recebimento de fiado — João` (pt) / `Credit received — João` (en) /
 /// `Crédit reçu — João` (fr).
 static String settleDebt({
 required String language,
 required String personName,
 }) {
 final prefix = switch (language) {
 'en' => 'Credit received — ',
 'fr' => 'Crédit reçu — ',
 _ => 'Recebimento de fiado — ',
 };
 return '$prefix$personName';
 }

 /// `Compra — ACME` (pt) / `Purchase — ACME` (en) / `Achat — ACME` (fr).
 static String purchase({
 required String language,
 required String supplierName,
 }) {
 final prefix = switch (language) {
 'en' => 'Purchase — ',
 'fr' => 'Achat — ',
 _ => 'Compra — ',
 };
 return '$prefix$supplierName';
 }

 /// `Estorno de venda — Dinheiro` (pt) / `Sale reversal — Cash` (en) /
 /// `Annulation de vente — Espèces` (fr).
 ///
 /// Movimento de SAÍDA criado na anulação de uma venda — compensa a
 /// entrada original no caixa (a categoria continua a mesma de vendas,
 /// então o subtotal por categoria fecha em zero).
 static String saleReversal({
 required String language,
 required PaymentMethod paymentMethod,
 }) {
 final method = paymentMethodName(language, paymentMethod);
 return switch (language) {
 'en' => 'Sale reversal — $method',
 'fr' => 'Annulation de vente — $method',
 _ => 'Estorno de venda — $method',
 };
 }

 /// Nome localizado da forma de pagamento (espelha a extensão
 /// `PaymentMethodL10n.labelFor`, sem depender de AppLocalizations — o
 /// domínio não pode importar a UI).
 static String paymentMethodName(String language, PaymentMethod method) {
 return switch (method) {
 PaymentMethod.cash => switch (language) {
 'en' => 'Cash',
 'fr' => 'Espèces',
 _ => 'Dinheiro',
 },
 PaymentMethod.debitCard => switch (language) {
 'en' => 'Debit card',
 'fr' => 'Carte de débit',
 _ => 'Cartão de débito',
 },
 PaymentMethod.creditCard => switch (language) {
 'en' => 'Credit card',
 'fr' => 'Carte de crédit',
 _ => 'Cartão de crédito',
 },
 // Dinheiro móvel de Moçambique — mesmo nome em pt, en e fr (marca).
 PaymentMethod.mPesa => 'M-Pesa',
 PaymentMethod.eMola => 'E-Mola',
 PaymentMethod.transfer => switch (language) {
 'en' => 'Bank transfer',
 'fr' => 'Virement',
 _ => 'Transferência',
 },
 };
 }

 // ---- Categorias (agrupamento exibido no Financeiro) ---------------------

 /// `Vendas` (pt) / `Sales` (en) / `Ventes` (fr) — entradas de venda.
 static String saleCategory(String language) => switch (language) {
 'en' => 'Sales',
 'fr' => 'Ventes',
 _ => 'Vendas',
 };

 /// `Fiado` (pt) / `Credit` (en) / `Crédit` (fr) — pendência e quitação de fiado.
 static String debtCategory(String language) => switch (language) {
 'en' => 'Credit',
 'fr' => 'Crédit',
 _ => 'Fiado',
 };

 /// `Compras` (pt) / `Purchases` (en) / `Achats` (fr) — saídas de compra.
 static String purchaseCategory(String language) => switch (language) {
 'en' => 'Purchases',
 'fr' => 'Achats',
 _ => 'Compras',
 };
}

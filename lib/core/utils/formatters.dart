import 'package:intl/intl.dart';

/// Formatação para a UI (moeda, datas e dias relativos).
///
/// A moeda e o idioma são configurados pelo **dono do tenant** (Ajustes)
/// via [applySettings] — o [AppSettings] é aplicado no `DumbhanengueApp`
/// sempre que o tenant carrega/altera (novos tenants nascem com **MZN** —
/// mercado-alvo Moçambique). Sem configuração (testes, antes do login), o
/// padrão ESTÁTICO continua BRL + pt-BR — o `DumbhanengueApp` sempre
/// aplica os ajustes, então esse default só vale em testes/edge cases;
/// o onboarding usa [currencyFor] com a moeda selecionada ao vivo.
///
/// Desde a migração W4, todo dinheiro vive em **centavos inteiros** —
/// [currency] recebe centavos (`123456` → `R$ 1.234,56`).
abstract final class Formatters {
 static String _currencyCode = 'BRL';
 static String _language = 'pt';

 /// Símbolo por moeda suportada (escolha do dono).
 static const Map<String, String> _currencySymbols = {
 'BRL': r'R$',
 'USD': r'US$',
 'EUR': '€',
 'MZN': 'MZN',
 };

 /// Aplica as preferências do tenant à formatação (moeda + idioma).
 static void applySettings({
 required String currencyCode,
 required String language,
 }) {
 _currencyCode = currencyCode;
 _language = language;
 }

 /// Código da moeda atualmente ativa (default `BRL`).
 static String get currentCurrencyCode => _currencyCode;

 /// Símbolo da moeda ativa (ex.: `MZN` para o metical) — para exibições
 /// onde o valor e a moeda aparecem separados (ex.: o card do Financeiro).
 static String get currencySymbol =>
 _currencySymbols[_currencyCode] ?? '$_currencyCode ';

 /// Idioma atualmente ativo (default `pt`).
 static String get currentLanguage => _language;

 /// Formata um valor em CENTAVOS numa moeda EXPLÍCITA — usado no
 /// onboarding, onde o preço do plano acompanha a moeda (e o idioma) que
 /// o dono está escolhendo ao vivo, antes do tenant existir (o Formatters
 /// global ainda segue o padrão estático). [language] opcional: sem ele,
 /// usa o idioma ativo global.
 static String currencyFor(
 String currencyCode,
 int cents, {
 String? language,
 }) {
 final symbol = _currencySymbols[currencyCode] ?? '$currencyCode ';
 final locale = switch (language ?? _language) {
 'en' => 'en_US',
 'fr' => 'fr_FR',
 _ => 'pt_BR',
 };
 final value = cents / 100;
 final formatted = NumberFormat('#,##0.00', locale).format(value);
 return '$symbol $formatted';
 }

 /// Formata um valor em CENTAVOS na moeda e idioma ativos:
 /// `R$ 1.234,56` (pt) ou `US$ 1,234.56` (en).
 static String currency(int cents) => currencyFor(_currencyCode, cents);

 /// Formata como `04/08/2026`.
 static String date(DateTime date) =>
 '${_two(date.day)}/${_two(date.month)}/${date.year}';

 /// Formata como `17 ago` (dia + mês abreviado no idioma ativo) — o
 /// cabeçalho do dashboard (canvas V3: "Segunda, 17 ago").
 static String shortDate(DateTime date) {
 const months = {
 'pt': [
 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
 'jul', 'ago', 'set', 'out', 'nov', 'dez',
 ],
 'en': [
 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
 ],
 'fr': [
 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
 ],
 };
 final list = months[_language] ?? months['pt']!;
 return '${date.day} ${list[date.month - 1]}';
 }

 /// Formata um valor em UNIDADES de forma COMPACTA (canvas V3 dos cards
 /// de métrica): `12.400` → `12,4k`, `1.250.000` → `1,3M`, `890` → `890`.
 /// Usa o separador decimal do idioma ativo (vírgula no pt, ponto no en).
 static String compact(num value) {
 final locale = switch (_language) {
 'en' => 'en_US',
 'fr' => 'fr_FR',
 _ => 'pt_BR',
 };
 final abs = value.abs();
 if (abs >= 1000000) {
 return '${NumberFormat('#,##0.0', locale).format(value / 1000000)}M';
 }
 if (abs >= 1000) {
 return '${NumberFormat('#,##0.0', locale).format(value / 1000)}k';
 }
 return NumberFormat('#,##0', locale).format(value);
 }

 /// Valor em CENTAVOS com sinal EXPLÍCITO e SEM símbolo — o feed de
 /// atividade do dashboard (canvas V3): `+500,00`, `-890,00`, `+1.200`.
 static String signedAmount(int cents) {
 final sign = cents < 0 ? '-' : '+';
 final locale = switch (_language) {
 'en' => 'en_US',
 'fr' => 'fr_FR',
 _ => 'pt_BR',
 };
 final formatted = NumberFormat('#,##0.00', locale).format(cents.abs() / 100);
 return '$sign$formatted';
 }

 /// Valor em UNIDADES com 2 casas decimais + o CÓDIGO da moeda ativa no
 /// final — os cards de métrica da Home (canvas: `1.000,00 MTN`):
 /// `1.234,56 MZN` no pt, `1,234.56 MZN` no en, `1 234,56 MZN` no fr.
 static String amountWithCode(double units) {
 final locale = switch (_language) {
 'en' => 'en_US',
 'fr' => 'fr_FR',
 _ => 'pt_BR',
 };
 final formatted = NumberFormat('#,##0.00', locale).format(units);
 return '$formatted $_currencyCode';
 }

 /// Formata como `04/08/2026 14:30`.
 static String dateTime(DateTime date) =>
 '${Formatters.date(date)} ${_two(date.hour)}:${_two(date.minute)}';

 /// Formata apenas a hora como `14:30` — usado com [day] para datas
 /// inteligentes do tipo `Ontem • 11:04`.
 static String time(DateTime date) =>
 '${_two(date.hour)}:${_two(date.minute)}';

 /// Número amigável e estável de qualquer entidade (venda, compra,
 /// dívida, movimentação) para exibição (ex.: `#000123`).
 ///
 /// O id interno (`shl34bebegm_bdd308`) é a chave primária única; este
 /// número é apenas uma representação curta **derivada dele** (hash FNV-1a
 /// de 32 bits) para não expor o id cru na UI. Propriedades:
 /// - determinístico: a mesma entidade mostra o mesmo número em qualquer
 /// aparelho e a cada abertura (função pura do id);
 /// - vale para registros antigos e novos, sem migração de banco;
 /// - **não é sequencial** (não segue a ordem de criação — isso exigiria
 /// uma coluna nova no SQLite e no Supabase); colisões são possíveis em
 /// lojas com muitos registros, mas o id interno continua único.
 static String entityNumber(String id) {
 // FNV-1a 32-bit, sem dependências. 6 dígitos = espaço de 1 milhão.
 var hash = 0x811c9dc5;
 for (final unit in id.codeUnits) {
 hash ^= unit;
 // Multiplicação em duas metades de 16 bits: o produto direto
 // (hash * 0x01000193) ultrapassa 2^53, e o dart2js (web) representa
 // int como double — perderia precisão e divergiria do nativo. Esta
 // forma produz o mesmo resultado de (hash * 0x01000193) & 0xFFFFFFFF
 // com todos os intermediários abaixo de 2^53 (idêntico em VM/web).
 hash = _fnvPrime32(hash);
 }
 return '#${(hash % 1000000).toString().padLeft(6, '0')}';
 }

 /// `(hash * 0x01000193) & 0xFFFFFFFF` sem estourar 2^53 (web-safe).
 ///
 /// Decompõe o hash em duas metades de 16 bits: os produtos parciais ficam
 /// abaixo de 2^41 (exatos em double do dart2js) e a soma é mascarada no
 /// final — mesmo resultado do produto direto com `& 0xFFFFFFFF`.
 static int _fnvPrime32(int hash) {
 final low = (hash & 0xFFFF) * 0x01000193; // < 2^41
 final high = ((hash >> 16) & 0xFFFF) * 0x01000193; // < 2^41
 // low*prime mod 2^32 + ((high*prime mod 2^16) << 16), tudo mod 2^32.
 return ((low & 0xFFFFFFFF) + ((high & 0xFFFF) << 16)) & 0xFFFFFFFF;
 }

 /// Rótulo sequencial de uma venda (ex.: `S-00001`, `S-00042`).
 ///
 /// O [number] é o número SEQUENCIAL atribuído pelo banco dentro da loja
 /// (SQLite: MAX+1 na transação; Supabase: RPC `process_sale` com advisory
 /// lock por loja) — diferente do [entityNumber], que deriva um número
 /// estável do id quando não há numeração persistida (fiado e
 /// movimentações ainda usam a forma derivada).
 static String saleLabel(int number) =>
 'S-${number.toString().padLeft(5, '0')}';

 /// Rótulo sequencial de uma compra (ex.: `C-00001`, `C-00042`).
 ///
 /// O [number] é o número SEQUENCIAL atribuído pelo banco dentro da loja
 /// (SQLite: MAX+1 na transação; Supabase: RPC `process_purchase` com
 /// advisory lock por loja).
 static String purchaseLabel(int number) =>
 'C-${number.toString().padLeft(5, '0')}';

 /// Rótulo sequencial de uma dívida/fiado (ex.: `D-00001`, `D-00042`).
 ///
 /// O [number] é o número SEQUENCIAL atribuído pelo banco dentro da loja
 /// (SQLite: MAX+1 na transação; Supabase: RPC `register_debt` com
 /// advisory lock por loja).
 static String debtLabel(int number) =>
 'D-${number.toString().padLeft(5, '0')}';

 /// Dia relativo: `Hoje`/`Today`, `Ontem`/`Yesterday` ou `04/08` — ideal
 /// para listas (segue o idioma ativo).
 static String day(DateTime date) {
 final now = DateTime.now();
 final today = DateTime(now.year, now.month, now.day);
 final that = DateTime(date.year, date.month, date.day);
 final difference = today.difference(that).inDays;

 if (difference == 0) {
 return switch (_language) {
 'en' => 'Today',
 'fr' => "Aujourd'hui",
 _ => 'Hoje',
 };
 }
 if (difference == 1) {
 return switch (_language) {
 'en' => 'Yesterday',
 'fr' => 'Hier',
 _ => 'Ontem',
 };
 }
 return '${_two(date.day)}/${_two(date.month)}';
 }

 static String _two(int value) => value.toString().padLeft(2, '0');
}

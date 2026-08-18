import 'quantity.dart';

/// Resultado do parse de um código de barras de balança etiquetadora.
final class ScaleBarcodeData {
 const ScaleBarcodeData({
 required this.productCode,
 required this.totalValueCents,
 });

 /// Código do produto (PPPPP — 5 dígitos; o PLU cadastrado no produto).
 final String productCode;

 /// Valor monetário TOTAL da pesagem (WWWWW — 5 dígitos, em CENTAVOS).
 ///
 /// Padrão das balanças etiquetadoras: os 5 dígitos finais são o preço
 /// total da pesagem em centavos (ex.: `00175` = 1,75 da moeda local).
 final int totalValueCents;

 @override
 String toString() =>
 'ScaleBarcodeData(productCode: $productCode, totalValueCents: $totalValueCents)';
}

/// Parser do formato de código de barras de balanças etiquetadoras.
///
/// Formato suportado: **`20PPPPPWWWWW`** (11 dígitos):
/// - `20` — prefixo que identifica leitura de balança (peso/fracionado);
/// - `PPPPP` — código do produto (5 dígitos — o campo `code` do Product);
/// - `WWWWW` — valor monetário total da pesagem (5 dígitos, em centavos).
///
/// Uso no PDV: interceptar leituras iniciadas por `20`, extrair o código do
/// produto e derivar a fração de peso correta a partir do valor total ÷
/// preço unitário (a balança imprime o PREÇO, não o peso — a quantidade é
/// derivada matematicamente, ex.: 20000 centavos ÷ 8000 centavos/kg =
/// 2,5 kg = 2500 milésimos).
abstract final class ScaleBarcode {
 static final RegExp _pattern = RegExp(r'^20(\d{5})(\d{5})$');

 /// Interpreta [raw] como código de balança. Retorna `null` quando o
 /// código não começa com `20` ou não tem o formato exato de 11 dígitos
 /// (ex.: EAN-13 comum, que deve seguir o fluxo normal por código).
 ///
 /// Tolerante a sujeira de leitura: remove espaços e não-dígitos antes de
 /// casar (scanners tipo teclado costumam enviar \r\n/control chars).
 static ScaleBarcodeData? tryParse(String raw) {
 final digits = raw.trim().replaceAll(RegExp(r'\D'), '');
 final match = _pattern.firstMatch(digits);
 if (match == null) return null;
 return ScaleBarcodeData(
 productCode: match.group(1)!,
 totalValueCents: int.parse(match.group(2)!),
 );
 }

 /// Deriva a QUANTIDADE da pesagem em milésimos de unidade.
 ///
 /// `qtd = valor_total_centavos × 1000 ~/ preço_unitário_centavos` —
 /// ex.: 20000 centavos a 8000 centavos/kg → 2500 milésimos (2,5 kg).
 /// Divisão inteira (chão) garante nunca cobrar a mais por arredondamento.
 /// Retorna 0 se o preço unitário for inválido (≤ 0).
 static int weightMilliUnits(ScaleBarcodeData data, int unitPriceCents) {
 if (unitPriceCents <= 0) return 0;
 return data.totalValueCents * Quantity.milliFactor ~/ unitPriceCents;
 }

 /// Normaliza um código de produto para a BUSCA no catálogo.
 ///
 /// A balança imprime o PLU com 5 dígitos (`00123`), mas o cadastro aceita
 /// o código como o usuário digita (`123`). A busca precisa comparar a
 /// MESMA forma: remove zeros à esquerda de códigos numéricos — `00123` e
 /// `123` resolvem para a mesma chave (`123`). Códigos não-numéricos são
 /// retornados sem alteração (comparação exata).
 static String lookupKey(String code) {
 final trimmed = code.trim();
 final numeric = int.tryParse(trimmed);
 if (numeric == null) return trimmed;
 return numeric.toString();
 }
}

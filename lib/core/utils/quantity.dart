import 'package:intl/intl.dart';

/// Helpers de QUANTIDADE em **milésimos de unidade** (W11 — FIFO/peso).
///
/// Após a migração W11, TODA quantidade vive em milésimos inteiros (`int`):
/// `1000` = 1 unidade (produtos normais) ou 1 kg/litro (produtos por peso).
/// Segue a mesma filosofia do dinheiro em centavos (W4): `int` exato, sem
/// artefatos de `double` (0.1 + 0.2 → 0.30000000000000004) em somas,
/// baixa de lotes FIFO e comparações.
///
/// Esta classe concentra as **bordas de conversão**:
/// 1. **Entrada da UI** — [parse] interpreta o texto digitado
///    ("1,75" ou "1.75") → milésimos (1750);
/// 2. **Total de item** — [lineTotal] calcula `quantidade × preço unitário`
///    sem perder exatidão (`qtd_milli × preço_centavos ~/ 1000`);
/// 3. **Saída da UI** — [format] formata milésimos ("1,75 kg", "12").
abstract final class Quantity {
  /// Fator de milésimos (10³): 1000 milésimos = 1 unidade.
  static const int milliFactor = 1000;

  /// Limiar de "estoque baixo" em UNIDADES (W8): produtos com estoque
  /// menor que este valor entram no alerta do dashboard. Nomeado e central
  /// para ajuste único — as telas comparam contra `milliFactor`
  /// (ex.: `stock < lowStockThresholdUnits * Quantity.milliFactor`).
  static const int lowStockThresholdUnits = 5;

  /// Converte unidades (double, ex.: 1.75) em milésimos inteiros (1750).
  static int fromUnits(num units) => (units * milliFactor).round();

  /// Interpreta [input] digitado na UI como milésimos inteiros.
  ///
  /// Aceita separador decimal vírgula (pt) ou ponto (en): "1,75" → 1750,
  /// "1.75" → 1750, "1750" → 1750000 (entrada direta em milésimos só para
  /// uso interno). Retorna 0 para entradas vazias/inválidas (a validação
  /// de "maior que zero" fica nos validators/use cases).
  static int parse(String input) {
    final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return 0;
    final value = double.tryParse(normalized);
    if (value == null) return 0;
    return (value * milliFactor).round();
  }

  /// Converte milésimos em unidades (double) — para plotar/formatar.
  static double toUnits(int milli) => milli / milliFactor;

  /// Total de um item em CENTAVOS: `qtd(milli) × preço unitário em
  /// centavos` dividido por 1000 — divisão inteira exata, mesmo contrato
  /// das RPCs do servidor (`qty * price / 1000` em SQL inteiro).
  ///
  /// Ex.: 1750 (1,75 kg) × 8000 centavos (80,00/kg) → 14000 centavos.
  static int lineTotal(int milli, int unitPriceCents) =>
      milli * unitPriceCents ~/ milliFactor;

  /// Formata milésimos para a UI: inteiros sem fração ("12"), fração com
  /// até 3 casas ("1,75"), sempre no idioma ativo. [unitLabel] é anexado
  /// quando o produto tem unidade (kg, g, l, ml); 'un' (padrão) não é
  /// exibido — o rótulo de "unidades" fica a cargo do chamador.
  static String format(int milli, {String? unitLabel, String language = 'pt'}) {
    final locale = language == 'en' ? 'en_US' : 'pt_BR';
    final units = toUnits(milli);
    final number = units == units.roundToDouble()
        ? NumberFormat('#,##0', locale).format(units.round())
        : NumberFormat('#,##0.###', locale).format(units);
    final label = (unitLabel == null || unitLabel.isEmpty || unitLabel == 'un')
        ? ''
        : ' $unitLabel';
    return '$number$label';
  }
}

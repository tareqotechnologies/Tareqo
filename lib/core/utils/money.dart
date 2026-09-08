/// Helpers de conversão/parse de DINHEIRO em CENTAVOS inteiros (W4).
///
/// Após a migração W4, o domínio representa todo dinheiro como
/// **centavos inteiros** (`int`) — elimina os artefatos de `double`
/// (0.1 + 0.2 → 0.30000000000000004) em somas, relatórios e comparações.
///
/// Esta classe concentra as **bordas de conversão**:
/// 1. **Entrada da UI** — [parse] interpreta o texto digitado
/// ("13,90" ou "13.90") → centavos;
/// 2. **Legado/JSON externo** — [fromReais] converte um `double` (ou
/// `NUMERIC` do banco antigo) em centavos.
///
/// Regra de arredondamento: padrão do Dart (`round()` — meio para longe
/// de zero), o mesmo comportamento do Postgres NUMERIC.
abstract final class Money {
  /// Fator de centavos (10²).
  static const int _centsFactor = 100;

  /// Interpreta [input] digitado na UI como centavos inteiros.
  ///
  /// Aceita separador decimal vírgula (pt) ou ponto (en), com ou sem
  /// milhares (`1.234,56` → 123456; `1,234.56` → 123456). Retorna 0
  /// para entradas vazias/inválidas (a validação de "maior que zero"
  /// fica no use case / validator do formulário).
  static int parse(String input) {
    var normalized = input.trim().replaceAll(' ', '');
    if (normalized.isEmpty) return 0;

    // Detecta o separador decimal pelo ÚLTIMO separador presente: o
    // texto com milhares tem DOIS separadores distintos ou um padrão
    // claro (grupos de 3); sem milhares, o único separador é o decimal.
    final comma = normalized.lastIndexOf(',');
    final dot = normalized.lastIndexOf('.');
    if (comma > dot) {
      // pt: vírgula decimal; pontos são milhares.
      normalized = normalized.replaceAll('.', '').replaceFirst(',', '.');
    } else if (dot > comma) {
      // en: ponto decimal; vírgulas são milhares.
      normalized = normalized.replaceAll(',', '');
    } else {
      // Sem separador algum (ex.: "1390") — nada a normalizar; o número
      // é lido como reais inteiros. (Um único separador é tratado como
      // decimal na heurística acima; milhar sem decimal é ambíguo e não
      // é distinguível de um decimal — comportamento documentado.)
      normalized = normalized.replaceAll(',', '').replaceAll('.', '');
    }

    final value = double.tryParse(normalized);
    if (value == null) return 0;
    return fromReais(value);
  }

  /// Converte [value] em reais (double) para centavos inteiros.
  ///
  /// Usado nas bordas: parse da UI e leitura de dados legados. Soma e
  /// comparação a partir daqui são SEMPRE em centavos (exatas).
  static int fromReais(double value) => (value * _centsFactor).round();

  /// Converte centavos inteiros em reais (double) — para formatar/plotar.
  static double toReais(int cents) => cents / _centsFactor;
}

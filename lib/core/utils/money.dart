/// Operações seguras com dinheiro representado como [double].
///
/// O domínio usa `double` para valores monetários (mesma convenção do
/// SQLite/UI). `double` não representa decimais exatamente, então toda
/// FRONTEIRA de cálculo precisa arredondar para centavos (auditoria H1):
///
/// 1. **Acúmulos** (fluxo de caixa, relatórios) — somar centavos em vez de
///    doubles: `sum([0.1, 0.2, 0.3]) == 0.6` exato;
/// 2. **Fronteiras de persistência** — o banco já usa NUMERIC(12,2);
/// 3. **Exibição** — [round2] antes de formatar.
///
/// Regra de arredondamento: arredondamento binário padrão do Dart
/// (`round()` — meio para longe de zero). Como `double` não representa
/// 2.675 exatamente (vira 2.67499…), `Money.round2(2.675) == 2.67` — o
/// mesmo comportamento de `(x * 100).round() / 100` e do `NUMERIC` do
/// Postgres. Valores com 2 casas vêm de entrada com máscara decimal ou do
/// banco (NUMERIC(12,2)), então o caso real de "meio centavo" não ocorre.
abstract final class Money {
  /// Fator de centavos (10²).
  static const int _centsFactor = 100;

  /// Arredonda [value] para 2 casas decimais (centavos).
  ///
  /// Aritmética em centavos: `(v × 100).round()` elimina os artefatos de
  /// `double` na segunda casa (ex.: `0.1 + 0.2 → 0.30000000000000004` vira
  /// `0.3` exato) e segue o arredondamento do Postgres NUMERIC.
  static double round2(double value) =>
      (value * _centsFactor).round() / _centsFactor;

  /// Soma [values] acumulando em CENTAVOS (inteiros) — exata para 2 casas.
  /// Retorna o total arredondado a centavos.
  static double sum(Iterable<num> values) {
    var cents = 0;
    for (final value in values) {
      cents += (round2(value.toDouble()) * _centsFactor).round();
    }
    return cents / _centsFactor;
  }

  /// Valor em centavos (int) — base para comparações exatas
  /// (`Money.cents(9.9) == 990`).
  static int cents(double value) => (round2(value) * _centsFactor).round();

  /// Multiplicação exata `[quantity] × [unitPrice]` arredondada a centavos —
  /// o preço unitário tem 2 casas; multiplicar por inteiro não introduz
  /// erro além do arredondamento do próprio preço.
  static double times(int quantity, double unitPrice) =>
      cents(unitPrice) * quantity / _centsFactor;
}

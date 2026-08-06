/// Helpers de períodos de análise partilhados entre módulos.
///
/// Centraliza a regra de "início do dia" usada pelo Financeiro e pelos
/// Relatórios — evita cópias divergentes da mesma semântica.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

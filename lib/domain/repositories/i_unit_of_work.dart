/// Contrato de unidade de trabalho (escopo de transação).
///
/// Permite que um caso de uso execute múltiplas operações de persistência
/// (repositórios diferentes) em uma **única transação** — ou tudo é
/// gravado, ou nada. Fecha janelas de concorrência (TOCTOU) entre
/// validações/leituras e gravações.
///
/// A implementação concreta vive na camada `data`: SQLite (transação real
/// via BEGIN/COMMIT/ROLLBACK) ou no-op (memória/web, onde a execução já é
/// sequencial).
abstract interface class IUnitOfWork {
  /// Executa [action] dentro de uma transação atômica.
  Future<T> run<T>(Future<T> Function() action);
}

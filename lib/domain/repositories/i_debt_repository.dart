import '../entities/debt.dart';

/// Contrato de persistência de dívidas ("fiado") — camada de domínio.
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// A implementação concreta (ex.: SQLite) vive na camada `data`.
abstract interface class IDebtRepository {
  /// Retorna todas as dívidas da loja [storeId] (sem ordenação garantida)
  /// — o fiado é por loja (Fase 2 do multi-tenancy).
  Future<List<Debt>> getAll({required String storeId});

  /// Registra uma nova dívida ("fiado").
  Future<void> add(Debt debt);

  /// Marca a dívida [id] da loja [storeId] como quitada
  /// ([Debt.isPaid] = `true`).
  ///
  /// ⚠️ Regra de negócio: a baixa deve passar pelo **SettleDebtUseCase**,
  /// que também registra a entrada no caixa correspondente. Evite chamar
  /// [markAsPaid] diretamente na UI — repositórios são portas burras de
  /// persistência; a orquestração vive no domínio.
  ///
  /// A baixa é escopada pela loja: uma dívida de outra loja não é
  /// alcançável por este caminho.
  ///
  /// Lança [StateError] se a dívida não existir — o caso de uso converte
  /// em erro de domínio amigável para a UI.
  Future<void> markAsPaid(String id, {required String storeId});
}

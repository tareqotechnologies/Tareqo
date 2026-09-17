import '../entities/addon.dart';

/// Repositório do CATÁLOGO de add-ons (definição/preço), não do estado
/// de activação por tenant (esse é o [AddOnLocalDataSource]).
///
/// O catálogo nasce do seed estático ([AddOnCatalog]) e pode ser
/// SOBRESCRITO no banco (`add_ons`) — por exemplo, o super admin editando
/// o preço mensal de um add-on. Em modo local (sem Supabase), as edições
/// vivem apenas em memória.
abstract interface class IAddOnRepository {
  /// Catálogo efectivo: seed estático mesclado com os overrides do banco
  /// (preço editado, disponibilidade, etc.). Nunca vazio — se o banco
  /// falhar, cai no seed.
  Future<List<AddOn>> all();

  /// Persiste o preço mensal (CENTAVOS) de um add-on do catálogo.
  ///
  /// Upsert: a linha é criada na primeira edição (o seed estático
  /// continua como fallback para os campos não editados).
  Future<void> updatePrice(String addOnId, int priceMonthlyCents);
}

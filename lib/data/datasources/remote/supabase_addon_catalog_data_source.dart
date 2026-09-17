import 'supabase_datasource_helpers.dart';

/// Persistência dos OVERRIDES do catálogo de add-ons (tabela `add_ons`).
///
/// A tabela guarda APENAS os campos editados pelo super admin (preço
/// mensal, disponibilidade) por `id` de add-on — o restante (nome,
/// descrição, categoria) continua vindo do seed estático [AddOnCatalog].
/// Assim o seed pode evoluir no app sem migração de dados.
///
/// RLS: leitura para logados; escrita só do super admin
/// (mesmo padrão de `plans`).
abstract interface class SupabaseAddOnCatalogDataSource {
  /// Linhas de override persistidas (id → preço em centavos/disponível).
  Future<Map<String, ({int priceMonthlyCents, bool isAvailable})>>
  fetchOverrides();

  /// Upsert da linha de override (preço mensal em CENTAVOS).
  Future<void> upsertOverride({
    required String addOnId,
    required int priceMonthlyCents,
  });
}

final class SupabaseAddOnCatalogDataSourceImpl
    implements SupabaseAddOnCatalogDataSource {
  const SupabaseAddOnCatalogDataSourceImpl();

  static const _table = 'add_ons';
  static const _columns = 'id, price_monthly, is_available';

  @override
  Future<Map<String, ({int priceMonthlyCents, bool isAvailable})>>
  fetchOverrides() async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .limit(SupabaseQueryLimits.pageSize);
    return {
      for (final row in rows)
        row['id'] as String: (
          priceMonthlyCents: (row['price_monthly'] as num).toInt(),
          isAvailable: (row['is_available'] as bool?) ?? true,
        ),
    };
  }

  @override
  Future<void> upsertOverride({
    required String addOnId,
    required int priceMonthlyCents,
  }) async {
    await supabaseClient.from(_table).upsert({
      'id': addOnId,
      'price_monthly': priceMonthlyCents,
      'is_available': true,
    });
  }
}

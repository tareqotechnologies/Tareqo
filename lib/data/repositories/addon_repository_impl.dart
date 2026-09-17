import '../../../domain/entities/addon.dart';
import '../../../domain/repositories/i_addon_repository.dart';
import '../datasources/local/addon_catalog.dart';
import '../datasources/remote/supabase_addon_catalog_data_source.dart';

/// Repositório do catálogo de add-ons: seed estático mesclado com os
/// overrides persistidos no banco (`add_ons`).
///
/// Leitura: `AddOnCatalog` (fallback garantido) sobrescrito campo a campo
/// pelas linhas do banco — hoje o único campo editável é o preço mensal
/// (editado pelo super admin). Escrita: somente o preço (upsert da linha
/// `add_ons`).
final class AddOnRepositoryImpl implements IAddOnRepository {
  AddOnRepositoryImpl({this.remote});

  final SupabaseAddOnCatalogDataSource? remote;

  @override
  Future<List<AddOn>> all() async {
    final seed = AddOnCatalog.addOns();
    final remote = this.remote;
    if (remote == null) return seed;

    try {
      final overrides = await remote.fetchOverrides();
      if (overrides.isEmpty) return seed;
      return [
        for (final addon in seed)
          overrides[addon.id] != null
              ? addon.copyWith(
                  priceMonthlyCents: overrides[addon.id]!.priceMonthlyCents,
                  isAvailable: overrides[addon.id]!.isAvailable,
                )
              : addon,
      ];
    } catch (_) {
      // Banco indisponível/sem tabela — catálogo padrão (nunca vazio).
      return seed;
    }
  }

  @override
  Future<void> updatePrice(String addOnId, int priceMonthlyCents) async {
    final remote = this.remote;
    if (remote == null) {
      // Modo local: nada persiste — a edição vale só para a sessão.
      return;
    }
    await remote.upsertOverride(
      addOnId: addOnId,
      priceMonthlyCents: priceMonthlyCents,
    );
  }
}

import '../entities/purchase.dart';

/// Contrato de persistência de compras (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// Implementações: memória, SQLite e Supabase (RLS por tenant).
abstract interface class IPurchaseRepository {
 /// Retorna todas as compras da loja [storeId] (sem ordenação garantida)
 /// — a entrada de estoque é por loja (Fase 2 do multi-tenancy).
 Future<List<Purchase>> getAll({required String storeId});

 /// Registra uma compra concluída (compra + itens).
 Future<void> add(Purchase purchase);
}

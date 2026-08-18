import '../entities/customer.dart';

/// Contrato de persistência de clientes (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// Implementações: memória, SQLite e Supabase (RLS por tenant).
abstract interface class ICustomerRepository {
 /// Retorna todos os clientes cadastrados da loja [storeId] (sem
 /// ordenação garantida) — clientes são por loja (Fase 2 do
 /// multi-tenancy).
 Future<List<Customer>> getAll({required String storeId});

 /// Registra um novo cliente.
 Future<void> add(Customer customer);
}

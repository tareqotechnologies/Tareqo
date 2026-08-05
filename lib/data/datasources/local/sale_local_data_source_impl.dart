import '../../../domain/entities/sale.dart';
import 'sale_local_data_source.dart';

/// Implementação em memória do [SaleLocalDataSource].
///
/// Simula a tabela de vendas com uma `List<Sale>`. Inicia vazia por
/// padrão (testes dependem disso); o [seed] de demonstração é injetado
/// pelo ServiceLocator. Para migrar a SQLite, basta criar uma
/// implementação com as mesmas assinaturas e trocá-la no registro.
final class SaleLocalDataSourceImpl implements SaleLocalDataSource {
  SaleLocalDataSourceImpl({List<Sale> seed = const []})
      : _sales = [...seed];

  final List<Sale> _sales;

  @override
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales.where((sale) => sale.storeId == storeId));

  @override
  Future<void> add(Sale sale) async {
    _sales.add(sale);
  }
}

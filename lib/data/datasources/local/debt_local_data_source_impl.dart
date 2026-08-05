import '../../../domain/entities/debt.dart';
import 'debt_local_data_source.dart';

/// Implementação em memória do [DebtLocalDataSource].
///
/// Simula a tabela de dívidas com uma `List<Debt>`. Inicia vazia por
/// padrão (testes dependem disso); o [seed] de demonstração é injetado
/// pelo ServiceLocator. Para migrar a SQLite, basta criar uma
/// implementação com as mesmas assinaturas e trocá-la no registro.
final class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  DebtLocalDataSourceImpl({List<Debt> seed = const []}) : _debts = [...seed];

  final List<Debt> _debts;

  @override
  Future<List<Debt>> getAll({required String storeId}) async =>
      List.unmodifiable(_debts.where((debt) => debt.storeId == storeId));

  @override
  Future<void> add(Debt debt) async {
    _debts.add(debt);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    // Escopo por loja: só a dívida da loja informada é mutável.
    final index = _debts.indexWhere(
      (debt) => debt.id == id && debt.storeId == storeId,
    );
    if (index == -1) {
      throw StateError('Dívida $id não encontrada para baixa.');
    }
    // Debt é imutável: substitui por uma nova instância com isPaid = true
    // e a data da baixa (alimenta o histórico de quitações).
    _debts[index] = _debts[index].copyWith(
      isPaid: true,
      paidAt: DateTime.now(),
    );
  }
}

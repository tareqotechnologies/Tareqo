import '../entities/debt.dart';
import '../repositories/i_debt_repository.dart';

/// Caso de uso: listar as dívidas de clientes **já quitadas** (histórico).
///
/// Complementa o [GetPendingDebtsUseCase]: mostra as baixas passadas —
/// quem pagou, quanto e quando ([Debt.paidAt]) — para auditoria e consulta.
/// Filtra apenas dívidas com [Debt.isCustomerDebt] `true` e [Debt.isPaid]
/// `true` (o mesmo recorte do restante da tela de Crédito).
class GetSettledDebtsUseCase {
 const GetSettledDebtsUseCase(this._repository);

 final IDebtRepository _repository;

 /// Retorna as dívidas a receber de clientes já quitadas da loja
 /// [storeId].
 Future<List<Debt>> call({required String storeId}) async {
 final debts = await _repository.getAll(storeId: storeId);
 return debts.where((debt) => debt.isCustomerDebt && debt.isPaid).toList();
 }
}

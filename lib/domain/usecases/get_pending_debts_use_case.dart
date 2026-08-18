import '../entities/debt.dart';
import '../repositories/i_debt_repository.dart';

/// Caso de uso: listar as dívidas **a receber de clientes** ("fiado").
///
/// Filtra apenas as dívidas com [Debt.isCustomerDebt] `true` e ainda
/// **não quitadas** ([Debt.isPaid] `false`) — ou seja, o que o
/// comerciante tem para receber. Dívidas a pagar a fornecedores
/// (`isCustomerDebt: false`) e já quitadas ficam de fora.
class GetPendingDebtsUseCase {
 const GetPendingDebtsUseCase(this._repository);

 final IDebtRepository _repository;

 /// Retorna as dívidas a receber de clientes ainda pendentes da loja
 /// [storeId].
 Future<List<Debt>> call({required String storeId}) async {
 final debts = await _repository.getAll(storeId: storeId);
 return debts.where((debt) => debt.isCustomerDebt && !debt.isPaid).toList();
 }
}

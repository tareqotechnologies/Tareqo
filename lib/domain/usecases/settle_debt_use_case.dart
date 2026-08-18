import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../entities/debt.dart';
import '../entities/financial_transaction.dart';
import '../repositories/i_debt_processor.dart';
import '../repositories/i_debt_repository.dart';
import '../repositories/i_financial_transaction_repository.dart';
import '../repositories/i_unit_of_work.dart';

/// Exceção de domínio: tentativa de quitar uma dívida inexistente.
final class DebtNotFoundException implements Exception {
 const DebtNotFoundException(this.debtId);

 final String debtId;

 @override
 String toString() => 'DebtNotFoundException: dívida $debtId não encontrada.';
}

/// Caso de uso: quitar uma dívida de "fiado" (baixa).
///
/// Orquestra [IDebtRepository] e [IFinancialTransactionRepository] —
/// depende apenas de abstrações, nunca de implementações concretas.
/// Executa **duas operações atômicas do ponto de vista do negócio** dentro
/// de um [IUnitOfWork]:
/// 1. marca a dívida como paga ([Debt.isPaid] = `true`); e
/// 2. registra a **entrada no caixa** correspondente ao recebimento.
///
/// Com o SQLite, as duas operações rodam em **uma única transação**
/// (rollback completo em qualquer falha — nunca um fiado baixado sem a
/// entrada no caixa nem uma entrada sem a baixa). Em memória (web) o unit
/// of work é um no-op.
///
/// Quando [processor] é fornecido (Supabase), a baixa inteira é delegada a
/// ele — o servidor executa tudo em UMA transação (RPC `settle_debt`,
/// idempotente, escopada por loja/tenant).
class SettleDebtUseCase {
 const SettleDebtUseCase(
 this._debtRepository,
 this._transactionRepository,
 this._unitOfWork, {
 this.processor,
 });

 final IDebtRepository _debtRepository;
 final IFinancialTransactionRepository _transactionRepository;
 final IUnitOfWork _unitOfWork;

 /// Processador atômico opcional (Supabase via RPC `settle_debt`).
 final IDebtAtomicProcessor? processor;

 /// Quita a dívida [debtId] da loja [storeId] e registra a entrada
 /// correspondente no caixa (o recebimento entra na loja da dívida).
 ///
 /// No caminho composto (SQLite/memória), lança [DebtNotFoundException] se
 /// a dívida não existir. Com [processor] (Supabase), a validação e a
 /// idempotência rodam no servidor — o erro do RPC propaga como exceção
 /// genérica. Nos dois caminhos, uma dívida já quitada não gera segunda
 /// entrada no caixa.
 Future<void> call(String debtId, {required String storeId}) async {
 // Caminho atômico (Supabase): o servidor baixa a dívida e resolve a
 // entrada no caixa em UMA transação (idempotente — dívida inexistente
 // ou já quitada não gera efeito colateral indevido).
 final atomicProcessor = processor;
 if (atomicProcessor != null) {
 await atomicProcessor.settle(debtId, storeId: storeId);
 return;
 }

 await _unitOfWork.run(() async {
 final debt = await _find(debtId, storeId);
 if (debt == null) {
 throw DebtNotFoundException(debtId);
 }

 // Idempotência: nunca duplica a entrada no caixa (proteção contra
 // duplo toque / chamadas repetidas).
 if (debt.isPaid) return;

 // 1. Baixa da dívida (o estoque de riscos do fiado encerra aqui).
 // Escopada pela loja: só a dívida da loja informada é alcançável.
 await _debtRepository.markAsPaid(debtId, storeId: storeId);

 // 2. Entrada no caixa — categoria própria para o recebimento de fiado
 // (o saldo do GetCashFlowUseCase passa a enxergar o dinheiro).
 //
 // Se a dívida tiver uma transação PENDENTE vinculada (debtId — ex.
 // dados demo ou pendência registrada na origem), marca a MESMA
 // transação como paga em vez de criar uma duplicata no caixa. Se
 // já estiver paga, nada é feito (idempotente).
 final linked = await _findLinkedTransaction(debt, storeId);
 if (linked != null) {
 if (linked.status == TransactionStatus.pending) {
 await _transactionRepository.markAsPaid(
 linked.id,
 storeId: storeId,
 );
 }
 return;
 }

 // Fiado antigo sem pendência vinculada: registra a entrada direto.
 await _transactionRepository.add(
 FinancialTransaction(
 id: AppIds.newId('t'),
 // O recebimento entra no caixa da MESMA loja da dívida.
 storeId: storeId,
 description: TransactionDescriptions.settleDebt(
 language: Formatters.currentLanguage,
 personName: debt.personName,
 ),
 amountCents: debt.amountCents,
 type: TransactionType.income,
 category:
 TransactionDescriptions.debtCategory(Formatters.currentLanguage),
 date: DateTime.now(),
 status: TransactionStatus.paid,
 debtId: debt.id,
 ),
 );
 });
 }

 /// Procura a transação financeira vinculada à dívida ([Debt.debtId]),
 /// se existir.
 Future<FinancialTransaction?> _findLinkedTransaction(
 Debt debt,
 String storeId,
 ) async {
 final transactions = await _transactionRepository.getAll(storeId: storeId);
 for (final transaction in transactions) {
 if (transaction.debtId == debt.id) return transaction;
 }
 return null;
 }

 Future<Debt?> _find(String debtId, String storeId) async {
 final debts = await _debtRepository.getAll(storeId: storeId);
 for (final debt in debts) {
 if (debt.id == debtId) return debt;
 }
 return null;
 }
}

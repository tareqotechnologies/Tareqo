import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_debt_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/settle_debt_use_case.dart';

class _FakeDebtRepository implements IDebtRepository {
  _FakeDebtRepository(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> getAll({required String storeId}) async =>
      List.unmodifiable(_debts);

  @override
  Future<void> add(Debt debt) async {
    _debts.add(debt);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = _debts.indexWhere((debt) => debt.id == id);
    _debts[index] = _debts[index].copyWith(isPaid: true);
  }
}

class _FakeTransactionRepository implements IFinancialTransactionRepository {
  final List<FinancialTransaction> transactions = [];

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(transactions);

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => List.unmodifiable(transactions);

  @override
  Future<void> add(FinancialTransaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = transactions.indexWhere((t) => t.id == id);
    transactions[index] = transactions[index].copyWith(
      status: TransactionStatus.paid,
    );
  }
}

/// Unit of work no-op para os fakes em memória.
class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

/// Unit of work que conta execuções — verifica que a baixa roda no escopo
/// da transação.
class _RecordingUnitOfWork implements IUnitOfWork {
  int runs = 0;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    runs++;
    return action();
  }
}

/// Fake do processador atômico (Supabase via RPC) — conta as chamadas.
class _FakeDebtProcessor implements IDebtAtomicProcessor {
  int settleCalls = 0;
  String? lastDebtId;
  String? lastStoreId;

  @override
  Future<void> register(Debt debt) async {
    // Não usado nos testes de quitação.
  }

  @override
  Future<void> settle(String debtId, {required String storeId}) async {
    settleCalls++;
    lastDebtId = debtId;
    lastStoreId = storeId;
  }
}

Debt _debt(String id, {bool isPaid = false}) => Debt(
  id: id,
  personName: 'João da Silva',
  amountCents: 2500,
  dueDate: DateTime(2026, 8, 15),
  isCustomerDebt: true,
  isPaid: isPaid,
);

void main() {
  test('quita a dívida e registra a entrada no caixa', () async {
    final debts = _FakeDebtRepository([_debt('d1')]);
    final transactions = _FakeTransactionRepository();
    final useCase = SettleDebtUseCase(
      debts,
      transactions,
      const _DirectUnitOfWork(),
    );

    await useCase('d1', storeId: 'st1');

    // Dívida marcada como paga.
    expect((await debts.getAll(storeId: 'st1')).first.isPaid, isTrue);

    // Entrada no caixa: recebimento de fiado, valor exato da dívida.
    expect(transactions.transactions, hasLength(1));
    final entry = transactions.transactions.first;
    expect(entry.amountCents, 2500);
    expect(entry.type, TransactionType.income);
    expect(entry.status, TransactionStatus.paid);
    expect(entry.category, 'Fiado');
    expect(entry.description, contains('João da Silva'));
    // A nova entrada fica vinculada à dívida (rastreabilidade).
    expect(entry.debtId, 'd1');
  });

  test('dívida já quitada não gera nova entrada (idempotente)', () async {
    final debts = _FakeDebtRepository([_debt('d1', isPaid: true)]);
    final transactions = _FakeTransactionRepository();
    final useCase = SettleDebtUseCase(
      debts,
      transactions,
      const _DirectUnitOfWork(),
    );

    await useCase('d1', storeId: 'st1');

    expect(transactions.transactions, isEmpty);
  });

  test(
    'dívida inexistente lança DebtNotFoundException sem transação',
    () async {
      final debts = _FakeDebtRepository([_debt('d1')]);
      final transactions = _FakeTransactionRepository();
      final useCase = SettleDebtUseCase(
        debts,
        transactions,
        const _DirectUnitOfWork(),
      );

      await expectLater(
        useCase('d999', storeId: 'st1'),
        throwsA(isA<DebtNotFoundException>()),
      );

      expect(transactions.transactions, isEmpty);
    },
  );

  test(
    'marca a pendência vinculada como paga em vez de criar duplicata',
    () async {
      final debts = _FakeDebtRepository([_debt('d1')]);
      final transactions = _FakeTransactionRepository()
        ..transactions.add(
          FinancialTransaction(
            id: 't4',
            description: 'Venda fiado (João)',
            amountCents: 2500,
            type: TransactionType.income,
            category: 'Fiado',
            date: DateTime(2026, 8, 1),
            status: TransactionStatus.pending,
            debtId: 'd1',
          ),
        );
      final useCase = SettleDebtUseCase(
        debts,
        transactions,
        const _DirectUnitOfWork(),
      );

      await useCase('d1', storeId: 'st1');

      // A MESMA transação virou paga — nenhuma duplicata foi criada.
      expect(transactions.transactions, hasLength(1));
      expect(transactions.transactions.first.status, TransactionStatus.paid);
      expect(transactions.transactions.first.debtId, 'd1');
      expect((await debts.getAll(storeId: 'st1')).first.isPaid, isTrue);
    },
  );

  test(
    'não duplica entrada se a pendência vinculada já foi recebida',
    () async {
      final debts = _FakeDebtRepository([_debt('d1')]);
      final transactions = _FakeTransactionRepository()
        ..transactions.add(
          FinancialTransaction(
            id: 't4',
            description: 'Venda fiado (João)',
            amountCents: 2500,
            type: TransactionType.income,
            category: 'Fiado',
            date: DateTime(2026, 8, 1),
            status: TransactionStatus.paid, // já recebida manualmente
            debtId: 'd1',
          ),
        );
      final useCase = SettleDebtUseCase(
        debts,
        transactions,
        const _DirectUnitOfWork(),
      );

      await useCase('d1', storeId: 'st1');

      // Sem nova entrada: o recebimento já existia.
      expect(transactions.transactions, hasLength(1));
      expect((await debts.getAll(storeId: 'st1')).first.isPaid, isTrue);
    },
  );

  test(
    'executa a baixa dentro do unit of work (escopo de transação)',
    () async {
      final debts = _FakeDebtRepository([_debt('d1')]);
      final transactions = _FakeTransactionRepository();
      final unitOfWork = _RecordingUnitOfWork();
      final useCase = SettleDebtUseCase(debts, transactions, unitOfWork);

      await useCase('d1', storeId: 'st1');

      // Baixa + entrada rodaram dentro de UMA execução do UoW.
      expect(unitOfWork.runs, 1);
      expect((await debts.getAll(storeId: 'st1')).first.isPaid, isTrue);
      expect(transactions.transactions, hasLength(1));
    },
  );

  test(
    'delega para o processador atômico quando fornecido (Supabase)',
    () async {
      final processor = _FakeDebtProcessor();
      final debts = _FakeDebtRepository([_debt('d1')]);
      final transactions = _FakeTransactionRepository();
      final useCase = SettleDebtUseCase(
        debts,
        transactions,
        const _DirectUnitOfWork(),
        processor: processor,
      );

      await useCase('d1', storeId: 'st1');

      // O caminho composto NÃO roda — o servidor baixa + resolve a entrada
      // em UMA transação (validações e idempotência no banco).
      expect(processor.settleCalls, 1);
      expect(processor.lastDebtId, 'd1');
      expect(processor.lastStoreId, 'st1');
      expect((await debts.getAll(storeId: 'st1')).first.isPaid, isFalse);
      expect(transactions.transactions, isEmpty);
    },
  );

  test('caminho atômico não executa o unit of work composto', () async {
    final processor = _FakeDebtProcessor();
    final unitOfWork = _RecordingUnitOfWork();
    final useCase = SettleDebtUseCase(
      _FakeDebtRepository([_debt('d1')]),
      _FakeTransactionRepository(),
      unitOfWork,
      processor: processor,
    );

    await useCase('d1', storeId: 'st1');

    expect(processor.settleCalls, 1);
    expect(unitOfWork.runs, 0);
  });
}

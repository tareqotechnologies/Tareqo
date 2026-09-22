import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/controllers/finance_providers.dart';

/// Contratos dos providers de FINANÇAS que não exigem backend:
///
/// - o seletor de período (estado puro do notifier);
/// - as GUARDAS de sessão/loja dos providers de leitura (sem utilizador
///   logado, devolvem estado vazio/null sem tocar no ServiceLocator —
///   os caminhos com sessão são exercitados pelos testes de tela, que
///   sobrescrevem os use cases).
void main() {
  group('CashFlowPeriodNotifier — seletor de período', () {
    test('o período default é o MÊS corrente (semântica do app)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cashFlowPeriodProvider), CashFlowPeriod.month);
    });

    test('select troca o período e notifica os observadores', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final seen = <CashFlowPeriod>[];
      container.listen<CashFlowPeriod>(
        cashFlowPeriodProvider,
        (_, next) => seen.add(next),
      );

      container
          .read(cashFlowPeriodProvider.notifier)
          .select(CashFlowPeriod.today);
      container
          .read(cashFlowPeriodProvider.notifier)
          .select(CashFlowPeriod.week);
      container
          .read(cashFlowPeriodProvider.notifier)
          .select(CashFlowPeriod.all);

      expect(container.read(cashFlowPeriodProvider), CashFlowPeriod.all);
      // Uma emissão por seleção — sem duplicatas (contrato do notifier).
      expect(seen, [
        CashFlowPeriod.today,
        CashFlowPeriod.week,
        CashFlowPeriod.all,
      ]);
    });
  });

  group('cashFlowProvider — guarda sem utilizador logado', () {
    test('saldo zerado sem consulta ao repositório (sessão ausente)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flow = await container.read(cashFlowProvider.future);

      expect(flow.incomeCents, 0);
      expect(flow.expenseCents, 0);
      expect(flow.balanceCents, 0);
    });
  });

  group('transactionsProvider — guarda sem utilizador logado', () {
    test('lista vazia sem consulta ao repositório', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(transactionsProvider.future), isEmpty);
    });
  });

  group('cashClosingHistoryProvider — guarda sem utilizador logado', () {
    test('histórico null (sem sessão não há acesso ao fecho)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(cashClosingHistoryProvider.future), isNull);
    });
  });
}

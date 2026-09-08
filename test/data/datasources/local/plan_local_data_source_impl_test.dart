import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/plan_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/plan.dart';

void main() {
  group('PlanLocalDataSourceImpl', () {
    test('add cria o plano e getAllPlans retorna ordenado por preço', () async {
      final dataSource = PlanLocalDataSourceImpl(
        seed: const [
          Plan(id: 'pl2', name: 'B', priceMonthlyCents: 2000),
          Plan(id: 'pl1', name: 'A', priceMonthlyCents: 1000),
        ],
      );

      await dataSource.add(
        const Plan(id: 'pl3', name: 'C', priceMonthlyCents: 1500),
      );

      final all = await dataSource.getAllPlans();
      expect(all.map((p) => p.id), ['pl1', 'pl3', 'pl2']);
    });

    test('add com id duplicado lança (espelha a PK do banco)', () async {
      final dataSource = PlanLocalDataSourceImpl(
        seed: const [Plan(id: 'pl1', name: 'A')],
      );

      await expectLater(
        dataSource.add(const Plan(id: 'pl1', name: 'A duplicado')),
        throwsA(isA<StateError>()),
      );
      // A lista permanece intacta (sem duplicação silenciosa).
      expect(await dataSource.getAllPlans(), hasLength(1));
    });

    test('update substitui o plano existente', () async {
      final dataSource = PlanLocalDataSourceImpl(
        seed: const [Plan(id: 'pl1', name: 'A')],
      );

      await dataSource.update(
        const Plan(id: 'pl1', name: 'B', maxStores: 5, maxEmployees: 10),
      );

      final updated = await dataSource.getById('pl1');
      expect(updated!.name, 'B');
      expect(updated.maxStores, 5);
      expect(await dataSource.getAllPlans(), hasLength(1));
    });

    test('getById retorna null para id inexistente', () async {
      final dataSource = PlanLocalDataSourceImpl(
        seed: const [Plan(id: 'pl1', name: 'A')],
      );

      expect(await dataSource.getById('pl-x'), isNull);
    });
  });
}

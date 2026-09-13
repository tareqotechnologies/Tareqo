import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/plan_catalog.dart';
import 'package:tareqo/domain/entities/plan.dart';

/// Contrato do catálogo local de planos: é a TABELA DE PREÇOS REAL do
/// produto — os ids pl1/pl2/pl3 precisam permanecer alinhados com
/// `supabase/schema.sql`, porque o onboarding do dono e os limites
/// (AddStoreUseCase/AddEmployeeUseCase) leem daqui em modo local.
void main() {
  group('PlanCatalog.plans', () {
    test('deve expor exatamente os três planos de assinatura do schema', () {
      // when
      final plans = PlanCatalog.plans();

      // then — pl1/pl2/pl3 (mesmos ids do banco de produção).
      expect(plans.map((p) => p.id), ['pl1', 'pl2', 'pl3']);
    });

    test('deve manter os preços reais em meticais (centavos inteiros)', () {
      // when
      final plans = PlanCatalog.plans();

      // then — MZN 500/1000/2000 por mês, sem arredondamento de double.
      expect(plans[0].priceMonthlyCents, 50000);
      expect(plans[1].priceMonthlyCents, 100000);
      expect(plans[2].priceMonthlyCents, 200000);
    });

    test(
      'deve crescer limites de lojas e funcionários de forma monotônica',
      () {
        // given — pl3 nunca pode ser mais restritivo que pl1 (regra de
        // negócio do upsell: plano superior inclui capacidades inferiores).
        final plans = PlanCatalog.plans();

        // when / then
        expect(plans[0].maxStores, lessThan(plans[1].maxStores));
        expect(plans[1].maxStores, lessThan(plans[2].maxStores));
        expect(plans[0].maxEmployees, lessThan(plans[1].maxEmployees));
        expect(plans[1].maxEmployees, lessThan(plans[2].maxEmployees));
      },
    );

    test('deve retornar planos ativos com descrição preenchida', () {
      // given — um plano inativo ou sem descrição quebraria o onboarding.
      final plans = PlanCatalog.plans();

      // when / then
      for (final plan in plans) {
        expect(plan.isActive, isTrue, reason: '${plan.id} deve estar ativo');
        expect(
          plan.description,
          isNotEmpty,
          reason: '${plan.id} precisa de descrição',
        );
        expect(plan.name, isNotEmpty);
      }
    });

    test(
      'deve devolver lista const imutável (mutação de estado global é impossível)',
      () {
        // given — o catálogo é compartilhado por todo o app; se a lista
        // fosse mutável, qualquer caller poderia corromper a tabela de preços.
        final a = PlanCatalog.plans();
        final b = PlanCatalog.plans();

        // when / then — valores estáveis e lista que rejeita mutação.
        expect(a, equals(b));
        expect(
          () => a.add(const Plan(id: 'plX', name: 'Fake')),
          throwsUnsupportedError,
        );
      },
    );

    test('deve desserializar cada plano do catálogo (round-trip JSON)', () {
      // given — o catálogo alimenta widgets que recebem Plan via JSON
      // (cache local); qualquer campo ausente/tipo errado explodiria.
      final plans = PlanCatalog.plans();

      // when / then
      for (final plan in plans) {
        final json = plan.toJson();
        final restored = Plan.fromJson(json);
        expect(restored, equals(plan), reason: '${plan.id} round-trip');
      }
    });
  });
}

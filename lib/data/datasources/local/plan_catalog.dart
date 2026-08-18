import '../../../domain/entities/plan.dart';

/// Catálogo real de planos de assinatura do produto.
///
/// São os MESMOS planos criados pelo super admin no banco de produção
/// (`supabase/schema.sql` — pl1/pl2/pl3). Em modo local (sem Supabase) o
/// ServiceLocator injeta este catálogo fixo para que o onboarding do dono
/// tenha o que oferecer; em produção os planos vêm da tabela
/// `public.plans`. Não é dado de demonstração: é a tabela de preços real.
abstract final class PlanCatalog {
 static List<Plan> plans() {
 return const [
 Plan(
 id: 'pl1',
 name: 'Essencial',
 description: 'Para começar: 1 loja e até 3 funcionários.',
 // MZN 500,00/mês (preços em METICAIS — mercado-alvo Moçambique).
 priceMonthlyCents: 50000,
 maxStores: 1,
 maxEmployees: 3,
 ),
 Plan(
 id: 'pl2',
 name: 'Profissional',
 description: 'Para crescer: 3 lojas e até 10 funcionários.',
 priceMonthlyCents: 100000,
 maxStores: 3,
 maxEmployees: 10,
 ),
 Plan(
 id: 'pl3',
 name: 'Empresa',
 description: 'Para expandir: 10 lojas e até 50 funcionários.',
 priceMonthlyCents: 200000,
 maxStores: 10,
 maxEmployees: 50,
 ),
 ];
 }
}

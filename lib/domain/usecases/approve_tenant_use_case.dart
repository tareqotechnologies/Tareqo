import '../repositories/i_tenant_repository.dart';

/// Constantes do ciclo de facturacao.
const int kTrialDays = 14;
const int kBillingCycleDays = 30;
const int kInvoiceAdvanceDays = 7;

/// Caso de uso: aprovar a solicitação de acesso de um tenant (super admin).
///
/// O tenant passa a `approved` e o dono ganha acesso à área de gestão.
/// Na primeira subscricao, o tenant tem **14 dias grátis** (trial). Após
/// esse período, o ciclo mensal de facturacao começa:
///
/// 1. Tenant aprovado → `planExpiresAt` = now + 14 dias (trial)
/// 2. `nextInvoiceAt` = planExpiresAt (factura gerada ao fim do trial)
/// 3. Após 14 dias, primeira factura é gerada
/// 4. Ciclo mensal: planExpiresAt += 30 dias, nextInvoiceAt = planExpiresAt - 7
class ApproveTenantUseCase {
  const ApproveTenantUseCase(this._repository);

  final ITenantRepository _repository;

  Future<void> call(String tenantId) async {
    await _repository.approve(tenantId);

    // Configura o billing: 14 dias de trial grátis, depois ciclo mensal.
    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: kTrialDays));
    final nextInvoice = trialEnd; // factura gerada ao fim do trial

    await _repository.updateBilling(
      tenantId,
      planExpiresAt: trialEnd,
      nextInvoiceAt: nextInvoice,
    );
  }
}

import '../entities/invoice.dart';
import '../entities/tenant.dart';
import '../repositories/i_tenant_repository.dart';
import 'approve_tenant_use_case.dart';
import 'generate_invoice_use_case.dart';
import 'notify_invoice_generated_use_case.dart';

/// Caso de uso: verificar quais tenants precisam de factura e gerar.
///
/// Executado periodicamente (ex.: no arranque do app ou por um cronJob).
/// Para cada tenant aprovado cujo `nextInvoiceAt` já foi atingido,
/// gera uma factura de renovação mensal e notifica o dono.
///
/// **Ciclo de facturacao com trial de 14 dias:**
///
/// 1. Tenant aprovado → `planExpiresAt` = now + 14 dias (trial grátis)
/// 2. `nextInvoiceAt` = planExpiresAt (factura gerada ao fim do trial)
/// 3. Após 14 dias, primeira factura é gerada
/// 4. Ciclo mensal: planExpiresAt += 30 dias, nextInvoiceAt = planExpiresAt - 7
class CheckTenantsForInvoicesUseCase {
  const CheckTenantsForInvoicesUseCase(
    this._generateInvoice,
    this._tenantRepository, {
    this._notifyInvoiceGenerated,
  });

  final GenerateInvoiceUseCase _generateInvoice;
  final ITenantRepository _tenantRepository;
  final NotifyInvoiceGeneratedUseCase? _notifyInvoiceGenerated;

  /// Verifica e gera facturas pendentes.
  ///
  /// Retorna a lista de facturas geradas (pode estar vazia se nenhum
  /// tenant precisar de factura neste momento).
  Future<List<Invoice>> call() async {
    final allTenants = await _tenantRepository.getAll();
    final now = DateTime.now();
    final generated = <Invoice>[];

    for (final tenant in allTenants) {
      // Apenas tenants aprovados.
      if (tenant.status != TenantStatus.approved) continue;

      // Verifica se o nextInvoiceAt já foi atingido.
      final nextInvoice = tenant.nextInvoiceAt;
      if (nextInvoice == null) continue;
      if (nextInvoice.isAfter(now)) continue;

      // Gera a factura.
      final invoice = await _generateInvoice(tenant.id);
      if (invoice != null) {
        generated.add(invoice);

        // Notifica o dono do tenant.
        if (_notifyInvoiceGenerated != null) {
          await _notifyInvoiceGenerated.call(invoice);
        }

        // Avança o ciclo: próximo plano expira em 30 dias, factura em 7.
        final newExpiresAt = now.add(const Duration(days: kBillingCycleDays));
        final newNextInvoice = newExpiresAt.subtract(
          const Duration(days: kInvoiceAdvanceDays),
        );

        await _tenantRepository.updateBilling(
          tenant.id,
          planExpiresAt: newExpiresAt,
          nextInvoiceAt: newNextInvoice,
        );
      }
    }

    return generated;
  }
}

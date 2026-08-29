import '../entities/invoice.dart';
import '../repositories/i_invoice_repository.dart';
import '../repositories/i_plan_repository.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: gerar factura de renovação mensal para um tenant.
///
/// Chamado quando o plano do tenant está para expirar (7 dias antes da
/// data de expiração). Verifica se já existe factura pendente para o
/// período (evita duplicação) e cria uma nova factura com o valor do
/// plano contratado.
///
/// O ciclo mensal funciona assim:
/// 1. Tenant é aprovado → `planExpiresAt` = approvedAt + 30 dias
/// 2. `nextInvoiceAt` = planExpiresAt - 7 dias
/// 3. Quando nextInvoiceAt é atingido, este use case é chamado
/// 4. Factura é criada e o dono é notificado
/// 5. Tenant renova → planExpiresAt += 30 dias, nextInvoiceAt atualizado
class GenerateInvoiceUseCase {
  const GenerateInvoiceUseCase(
    this._invoiceRepository,
    this._tenantRepository,
    this._planRepository,
  );

  final IInvoiceRepository _invoiceRepository;
  final ITenantRepository _tenantRepository;
  final IPlanRepository _planRepository;

  /// Gera factura para o tenant indicado, se aplicável.
  ///
  /// Retorna a factura criada, ou `null` se:
  /// - Já existe factura pendente para o período
  /// - O tenant não foi encontrado
  /// - O plano não foi encontrado
  Future<Invoice?> call(String tenantId) async {
    final tenant = await _tenantRepository.getById(tenantId);
    if (tenant == null) return null;

    final plan = await _planRepository.getById(tenant.planId);
    if (plan == null) return null;

    // Determina o período da factura (ex.: "Janeiro 2026").
    final now = DateTime.now();
    final period = _formatPeriod(now);

    // Verifica se já existe factura pendente para este período.
    final alreadyExists =
        await _invoiceRepository.hasPendingForPeriod(tenantId, period);
    if (alreadyExists) return null;

    // Data de vencimento = data de expiração do plano (ou 30 dias a partir
    // de agora se não houver planExpiresAt definido).
    final dueDate = tenant.planExpiresAt ?? now.add(const Duration(days: 30));

    final invoice = Invoice(
      id: '',
      tenantId: tenantId,
      planId: tenant.planId,
      amountCents: plan.priceMonthlyCents,
      status: InvoiceStatus.pending,
      dueDate: dueDate,
      period: period,
      createdAt: DateTime.now(),
    );

    return _invoiceRepository.create(invoice);
  }

  /// Formata o período como "Mês Ano" em português.
  String _formatPeriod(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

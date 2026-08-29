import '../entities/invoice.dart';
import '../entities/invoice_notification.dart';
import '../repositories/i_invoice_notification_repository.dart';
import '../repositories/i_plan_repository.dart';

/// Caso de uso: criar notificação quando uma factura é gerada.
///
/// Chamado pelo [CheckTenantsForInvoicesUseCase] após gerar uma factura.
/// Cria uma notificação in-app para o dono do tenant com os detalhes
/// da factura (valor, período, data de vencimento).
class NotifyInvoiceGeneratedUseCase {
  const NotifyInvoiceGeneratedUseCase(
    this._notificationRepository,
    this._planRepository,
  );

  final IInvoiceNotificationRepository _notificationRepository;
  final IPlanRepository _planRepository;

  /// Cria uma notificação para a factura gerada.
  ///
  /// Retorna a notificação criada, ou `null` se o plano não for encontrado.
  Future<InvoiceNotification?> call(Invoice invoice) async {
    final plan = await _planRepository.getById(invoice.planId);
    if (plan == null) return null;

    final amount = (invoice.amountCents / 100).toStringAsFixed(2);
    final currency = 'MZN'; // Moeda padrão

    final notification = InvoiceNotification(
      id: '',
      tenantId: invoice.tenantId,
      invoiceId: invoice.id,
      type: InvoiceNotificationType.invoiceGenerated,
      title: 'Nova factura gerada',
      body:
          'Factura ${invoice.period} no valor de $amount $currency. '
          'Vencimento: ${_formatDate(invoice.dueDate)}.',
      createdAt: DateTime.now(),
    );

    return _notificationRepository.create(notification);
  }

  /// Cria uma notificação quando a factura está para vencer (7 dias).
  Future<InvoiceNotification?> notifyDueSoon(Invoice invoice) async {
    final plan = await _planRepository.getById(invoice.planId);
    if (plan == null) return null;

    final amount = (invoice.amountCents / 100).toStringAsFixed(2);
    final daysLeft = invoice.dueDate.difference(DateTime.now()).inDays;

    final notification = InvoiceNotification(
      id: '',
      tenantId: invoice.tenantId,
      invoiceId: invoice.id,
      type: InvoiceNotificationType.invoiceDueSoon,
      title: 'Factura para vencer',
      body:
          'A factura ${invoice.period} no valor de $amount MZN '
          'vence em $daysLeft dia(s). Regularize o pagamento.',
      createdAt: DateTime.now(),
    );

    return _notificationRepository.create(notification);
  }

  /// Cria uma notificação quando a factura expira (não paga).
  Future<InvoiceNotification?> notifyExpired(Invoice invoice) async {
    final plan = await _planRepository.getById(invoice.planId);
    if (plan == null) return null;

    final amount = (invoice.amountCents / 100).toStringAsFixed(2);

    final notification = InvoiceNotification(
      id: '',
      tenantId: invoice.tenantId,
      invoiceId: invoice.id,
      type: InvoiceNotificationType.invoiceExpired,
      title: 'Factura expirada',
      body:
          'A factura ${invoice.period} no valor de $amount MZN '
          'expirou sem pagamento. O acesso pode ser suspenso.',
      createdAt: DateTime.now(),
    );

    return _notificationRepository.create(notification);
  }

  /// Cria uma notificação quando a factura é marcada como paga.
  Future<InvoiceNotification?> notifyPaid(Invoice invoice) async {
    final plan = await _planRepository.getById(invoice.planId);
    if (plan == null) return null;

    final amount = (invoice.amountCents / 100).toStringAsFixed(2);

    final notification = InvoiceNotification(
      id: '',
      tenantId: invoice.tenantId,
      invoiceId: invoice.id,
      type: InvoiceNotificationType.invoicePaid,
      title: 'Factura paga',
      body:
          'A factura ${invoice.period} no valor de $amount MZN '
          'foi registada como paga. Obrigado!',
      createdAt: DateTime.now(),
    );

    return _notificationRepository.create(notification);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

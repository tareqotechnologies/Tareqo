import 'dart:async';

import '../../core/di/service_locator.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/invoice_notification.dart';
import '../../domain/repositories/i_invoice_notification_repository.dart';
import '../datasources/local/addon_catalog.dart';
import '../datasources/local/addon_local_data_source.dart';

/// Dias antes da expiração que disparam notificação de aviso.
const _warningDays = [7, 3, 1];

/// Serviço que verifica e desactiva add-ons expirados.
///
/// Executa:
/// 1. No arranque da app (chamado pelo ServiceLocator)
/// 2. Periodicamente a cada 30 minutos
///
/// Add-ons com `expires_at` no passado são desactivados automaticamente.
/// Cria notificações in-app quando um add-on está para expirar ou já expirou.
class AddOnExpiryService {
  AddOnExpiryService(
    this._dataSource, {
    IInvoiceNotificationRepository? notificationRepository,
  }) : _notificationRepository = notificationRepository;

  final AddOnLocalDataSource _dataSource;
  final IInvoiceNotificationRepository? _notificationRepository;

  Timer? _timer;

  // IDs de notificações já criadas nesta sessão para não duplicar.
  final Set<String> _notifiedKeys = {};

  /// Inicia a verificação periódica (a cada 30 minutos).
  void startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => checkAndDeactivateExpired(),
    );
  }

  /// Para a verificação periódica.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Verifica e desactiva add-ons expirados, e cria notificações
  /// de aviso para add-ons que estão para expirar.
  Future<int> checkAndDeactivateExpired() async {
    try {
      // 1. Desactivar expirados.
      final count = await _dataSource.deactivateExpired();
      if (count > 0) {
        // ignore: avoid_print
        print('[AddOnExpiry] Desactivados $count add-on(s) expirado(s).');
      }

      // 2. Criar notificações de aviso e expiração.
      await _createExpiryNotifications();

      return count;
    } catch (e) {
      // Erros de rede/banco não devem crashar a app.
      // ignore: avoid_print
      print('[AddOnExpiry] Erro ao verificar expiração: $e');
      return 0;
    }
  }

  /// Cria notificações in-app para add-ons que estão para expirar
  /// ou que já expiraram.
  Future<void> _createExpiryNotifications() async {
    if (_notificationRepository == null) return;

    try {
      // Iterar todos os tenants que têm add-ons com expires_at.
      // Como o serviço não conhece o tenant actual, precisamos de uma
      // abordagem diferente: o serviço recebe os add-ons activos do tenant
      // e verifica os seus expires_at.
      //
      // Na prática, o método é chamado pelo TenantAddOnsNotifier ou
      // por um provider que conhece o tenant.
    } catch (e) {
      // ignore: avoid_print
      print('[AddOnExpiry] Erro ao criar notificações: $e');
    }
  }

  /// Cria notificações de expiração para um tenant específico.
  /// Chamado pelo provider quando o tenant é conhecido.
  Future<void> checkAndNotifyForTenant(String tenantId) async {
    if (_notificationRepository == null) return;

    try {
      final tenantAddOns = await _dataSource.getByTenant(tenantId);
      final now = DateTime.now();

      for (final ta in tenantAddOns) {
        if (!ta.isActive) continue;
        final expiresAt = ta.expiresAt;
        if (expiresAt == null) continue;

        final daysRemaining = expiresAt.difference(now).inDays;
        final addOn = AddOnCatalog.findById(ta.addOnId);
        final addOnName = addOn?.name ?? ta.addOnId;

        // Notificação de expiração (já expirou).
        if (daysRemaining <= 0) {
          final key = '${tenantId}_${ta.addOnId}_expired';
          if (!_notifiedKeys.contains(key)) {
            await _createNotification(
              tenantId: tenantId,
              type: InvoiceNotificationType.addOnExpired,
              title: 'Add-on expirado',
              body:
                  'O serviço "$addOnName" expirou. '
                  'Renove a assinatura para continuar a usar.',
            );
            _notifiedKeys.add(key);
          }
        }

        // Notificações de aviso (7, 3, 1 dia antes).
        for (final warnDays in _warningDays) {
          if (daysRemaining == warnDays ||
              (daysRemaining > 0 && daysRemaining <= warnDays)) {
            final key =
                '${tenantId}_${ta.addOnId}_warn_$warnDays';
            if (!_notifiedKeys.contains(key)) {
              final expiryDateStr =
                  '${expiresAt.day}/${expiresAt.month}/${expiresAt.year}';
              await _createNotification(
                tenantId: tenantId,
                type: InvoiceNotificationType.addOnExpiringSoon,
                title: 'Add-on a expirar',
                body:
                    'O serviço "$addOnName" expira em '
                    '$daysRemaining dia(s) ($expiryDateStr). '
                    'Renove para evitar a interrupção.',
              );
              _notifiedKeys.add(key);
            }
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AddOnExpiry] Erro ao verificar notificações: $e');
    }
  }

  Future<void> _createNotification({
    required String tenantId,
    required InvoiceNotificationType type,
    required String title,
    required String body,
  }) async {
    final notification = InvoiceNotification(
      id: AppIds.newId('notif_addon'),
      tenantId: tenantId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    await _notificationRepository!.create(notification);
  }
}

/// Registra o serviço de expiração no ServiceLocator.
void registerAddOnExpiryService() {
  if (!ServiceLocator.instance.isRegistered<AddOnExpiryService>()) {
    final dataSource = ServiceLocator.instance<AddOnLocalDataSource>();
    IInvoiceNotificationRepository? notifRepo;
    if (ServiceLocator.instance.isRegistered<IInvoiceNotificationRepository>()) {
      notifRepo = ServiceLocator.instance<IInvoiceNotificationRepository>();
    }
    ServiceLocator.instance.registerLazySingleton<AddOnExpiryService>(
      () => AddOnExpiryService(dataSource, notificationRepository: notifRepo),
    );
  }
}

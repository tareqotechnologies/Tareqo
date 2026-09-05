import 'dart:async';

import '../../core/di/service_locator.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/invoice_notification.dart';
import '../../domain/repositories/i_invoice_notification_repository.dart';
import '../datasources/local/addon_catalog.dart';
import '../datasources/local/addon_local_data_source.dart';

/// Janelas (em dias) que disparam aviso de expiração — ordem ascendente:
/// dispara-se no máx. UMA notificação por janela (≤7, ≤3 e ≤1 dia) e por
/// ciclo de validade, nunca em duplicado no mesmo check.
const _warningDays = [1, 3, 7];

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
    this._notificationRepository,
  });

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

  /// Verifica e desactiva add-ons expirados (por tenant via RLS no SaaS;
  /// global no armazenamento local). Chamado no arranque e pelo provider
  /// do tenant.
  Future<int> checkAndDeactivateExpired() async {
    try {
      return await _dataSource.deactivateExpired();
    } catch (_) {
      // Erros de rede/banco não devem crashar a app — falha silenciosa.
      return 0;
    }
  }

  /// Cria notificações de expiração/aviso para um tenant específico.
  /// Chamado pelo provider quando o tenant é conhecido (login/refresh).
  ///
  /// Semântica anti-spam:
  /// * Já expirado mas ainda marcado activo → UMA notificação de
  ///   expiração (a desactivação em lote acontece depois, via
  ///   [checkAndDeactivateExpired]);
  /// * A expirar (≤7/≤3/≤1 dia) → no máximo UMA notificação por janela e
  ///   por ciclo de validade (a chave inclui a data de expiração, para uma
  ///   renovação gerar novos avisos sem duplicar o ciclo anterior).
  Future<void> checkAndNotifyForTenant(String tenantId) async {
    if (_notificationRepository == null) return;

    try {
      final tenantAddOns = await _dataSource.getByTenant(tenantId);
      final now = DateTime.now();

      for (final ta in tenantAddOns) {
        final expiresAt = ta.expiresAt;
        if (expiresAt == null) continue;

        final addOn = AddOnCatalog.findById(ta.addOnId);
        final addOnName = addOn?.name ?? ta.addOnId;
        final expiryKey = _dateKey(expiresAt);

        // Expirado (mas ainda activo): aviso único por ciclo de validade.
        if (ta.isActive && !now.isBefore(expiresAt)) {
          final key = '${tenantId}_${ta.addOnId}_expired_$expiryKey';
          if (_notifiedKeys.add(key)) {
            await _createNotification(
              tenantId: tenantId,
              type: InvoiceNotificationType.addOnExpired,
              title: 'Add-on expirado',
              body:
                  'O serviço "$addOnName" expirou em $expiryKey. '
                  'Renove a assinatura para continuar a usar.',
            );
          }
          continue;
        }
        if (!ta.isActive) continue;

        // A expirar: dias restantes arredondados PARA CIMA (20h = 1 dia;
        // nunca "0 dias" enquanto ainda não expirou).
        final secondsLeft = expiresAt.difference(now).inSeconds;
        if (secondsLeft <= 0) continue;
        final daysLeft = (secondsLeft / Duration.secondsPerDay).ceil();
        if (daysLeft > _warningDays.last) continue;

        // Janela = menor limiar que cobre os dias restantes (1, 3 ou 7).
        final window = _warningDays.firstWhere((d) => daysLeft <= d);
        final key =
            '${tenantId}_${ta.addOnId}_warn_${window}_$expiryKey';
        if (!_notifiedKeys.add(key)) continue;

        await _createNotification(
          tenantId: tenantId,
          type: InvoiceNotificationType.addOnExpiringSoon,
          title: 'Add-on a expirar',
          body:
              'O serviço "$addOnName" expira em $daysLeft dia(s) '
              '($expiryKey). Renove para evitar a interrupção.',
        );
      }
    } catch (_) {
      // Erros de rede/banco não devem derrubar o fluxo.
    }
  }

  static String _dateKey(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
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

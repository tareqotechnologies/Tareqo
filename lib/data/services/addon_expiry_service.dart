import 'dart:async';

import '../../core/di/service_locator.dart';
import '../datasources/local/addon_local_data_source.dart';

/// Serviço que verifica e desactiva add-ons expirados.
///
/// Executa:
/// 1. No arranque da app (chamado pelo ServiceLocator)
/// 2. Periodicamente a cada 30 minutos
///
/// Add-ons com `expires_at` no passado são desactivados automaticamente.
class AddOnExpiryService {
  AddOnExpiryService(this._dataSource);

  final AddOnLocalDataSource _dataSource;

  Timer? _timer;

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

  /// Verifica e desactiva add-ons expirados.
  /// Retorna o número de add-ons desactivados.
  Future<int> checkAndDeactivateExpired() async {
    try {
      final count = await _dataSource.deactivateExpired();
      if (count > 0) {
        // ignore: avoid_print
        print('[AddOnExpiry] Desactivados $count add-on(s) expirado(s).');
      }
      return count;
    } catch (e) {
      // Erros de rede/banco não devem crashar a app.
      // ignore: avoid_print
      print('[AddOnExpiry] Erro ao verificar expiração: $e');
      return 0;
    }
  }
}

/// Registra o serviço de expiração no ServiceLocator.
void registerAddOnExpiryService() {
  if (!ServiceLocator.instance.isRegistered<AddOnExpiryService>()) {
    final dataSource = ServiceLocator.instance<AddOnLocalDataSource>();
    ServiceLocator.instance.registerLazySingleton<AddOnExpiryService>(
      () => AddOnExpiryService(dataSource),
    );
  }
}

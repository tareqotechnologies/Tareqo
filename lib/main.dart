import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_flavor.dart';
import 'core/di/service_locator.dart';
import 'core/ui/haptics.dart';
import 'core/network/supabase_bootstrap.dart';
import 'core/observability/crash_reporting.dart';
import 'data/services/addon_expiry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No Windows o Flutter não injeta FLUTTER_APP_FLAVOR via --flavor, então a
  // detecção do flavor em runtime usa a variável de ambiente (definida em prod
  // pelo script de lançamento antes de rodar o .exe). Em Android/macOS/iOS o
  // --flavor define o define. Um build dev nunca pode ser publicado.
  if (kReleaseMode && !AppFlavorConfig.isProd) {
    debugPrint(
      'Aviso: build de release executado sem FLUTTER_APP_FLAVOR=prod detectado. '
      'Se este for um build de produção do Windows, defina FLUTTER_APP_FLAVOR=prod '
      'no ambiente antes de rodar o .exe.',
    );
  }

  // Observabilidade (auditoria H4): Sentry se SENTRY_DSN estiver no build;
  // no-op em dev/CI. Instala os handlers globais de erro não capturado.
  await CrashReporting.initialize();

  // Inicializa o Supabase (sessão persistida é restaurada aqui).
  await SupabaseBootstrap.initialize();

  // Inicializa o Service Locator (GetIt) com as dependências.
  await ServiceLocator.initialize();

  // Preferência de feedback tátil (Lojas → Ajustes → Geral). Antes do
  // runApp: qualquer haptic emitido na primeira interação já respeita a
  // escolha do utilizador.
  await Haptics.load();

  // Verificar add-ons expirados no arranque e iniciar verificação periódica.
  registerAddOnExpiryService();
  final expiryService = ServiceLocator.instance<AddOnExpiryService>();
  await expiryService.checkAndDeactivateExpired();
  expiryService.startPeriodicCheck();

  // ProviderScope expõe o estado gerenciado pelo Riverpod à árvore de widgets.
  runApp(const ProviderScope(child: TareqoApp()));
}

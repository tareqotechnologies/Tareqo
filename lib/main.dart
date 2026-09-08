import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_flavor.dart';
import 'core/di/service_locator.dart';
import 'core/network/supabase_bootstrap.dart';
import 'core/observability/crash_reporting.dart';
import 'data/services/addon_expiry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dart-defines OBRIGATÓRIOS em release (auditoria 2.4/S2): um build de
  // release tem de ser do flavor de PRODUÇÃO — um APK dev nunca pode ser
  // publicado. Além disso, o SupabaseBootstrap falha em release se os
  // defines de produção (SUPABASE_URL/SUPABASE_ANON_KEY) estiverem ausentes
  // (usa os defaults de desenvolvimento embutidos).
  if (kReleaseMode && !AppFlavorConfig.isProd) {
    throw StateError(
      'Build de release sem o flavor de produção: FLUTTER_APP_FLAVOR deve ser '
      '"prod" (ex.: flutter build appbundle --flavor prod '
      '--dart-define-from-file=env/prod.env). Um build dev nunca pode ser '
      'publicado no Google Play.',
    );
  }

  // Observabilidade (auditoria H4): Sentry se SENTRY_DSN estiver no build;
  // no-op em dev/CI. Instala os handlers globais de erro não capturado.
  await CrashReporting.initialize();

  // Inicializa o Supabase (sessão persistida é restaurada aqui).
  await SupabaseBootstrap.initialize();

  // Inicializa o Service Locator (GetIt) com as dependências.
  await ServiceLocator.initialize();

  // Verificar add-ons expirados no arranque e iniciar verificação periódica.
  registerAddOnExpiryService();
  final expiryService = ServiceLocator.instance<AddOnExpiryService>();
  await expiryService.checkAndDeactivateExpired();
  expiryService.startPeriodicCheck();

  // ProviderScope expõe o estado gerenciado pelo Riverpod à árvore de widgets.
  runApp(const ProviderScope(child: TareqoApp()));
}

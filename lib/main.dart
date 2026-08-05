import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/network/supabase_bootstrap.dart';
import 'core/observability/crash_reporting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Observabilidade (auditoria H4): Sentry se SENTRY_DSN estiver no build;
  // no-op em dev/CI. Instala os handlers globais de erro não capturado.
  await CrashReporting.initialize();

  // Inicializa o Supabase (sessão persistida é restaurada aqui).
  await SupabaseBootstrap.initialize();

  // Inicializa o Service Locator (GetIt) com as dependências.
  await ServiceLocator.initialize();

  // ProviderScope expõe o estado gerenciado pelo Riverpod à árvore de widgets.
  runApp(const ProviderScope(child: DumbhanengueApp()));
}

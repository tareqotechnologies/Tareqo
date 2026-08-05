import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/network/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase (sessão persistida é restaurada aqui).
  await SupabaseBootstrap.initialize();

  // Inicializa o Service Locator (GetIt) com as dependências.
  await ServiceLocator.initialize();

  // ProviderScope expõe o estado gerenciado pelo Riverpod à árvore de widgets.
  runApp(const ProviderScope(child: DumbhanengueApp()));
}

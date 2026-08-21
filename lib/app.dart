import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/controllers/account_providers.dart';
import 'presentation/screens/auth/auth_gate.dart';

/// Widget raiz da aplicação.
///
/// O [AuthGate] decide a tela inicial com base na sessão persistida:
/// login (deslogado) ou dashboard (logado).
///
/// **Idioma e moeda** (escolha do dono do tenant): o locale do
/// [MaterialApp] e a formatação de moeda seguem [tenantSettingsProvider]
/// — definidos no onboarding e alteráveis em Lojas → Ajustes. Sem tenant
/// (login / super admin) o padrão é pt + MZN (mercado-alvo Moçambique).
class DumbhanengueApp extends ConsumerWidget {
 const DumbhanengueApp({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final settings = ref.watch(tenantSettingsProvider);

 Formatters.applySettings(
 currencyCode: settings?.currencyCode ?? 'MZN',
 language: settings?.language ?? 'pt',
 );

 return MaterialApp(
 title: 'Dumbhanengue ERP',
 debugShowCheckedModeBanner: false,    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
 locale: settings?.locale ?? const Locale('pt'),
 localizationsDelegates: AppLocalizations.localizationsDelegates,
 supportedLocales: AppLocalizations.supportedLocales,
 home: const AuthGate(),
 );
 }
}

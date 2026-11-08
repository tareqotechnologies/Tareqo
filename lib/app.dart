import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/deep_link_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/controllers/account_providers.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/screens/auth/app_lock_overlay.dart';
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
class TareqoApp extends ConsumerWidget {
  const TareqoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tenantSettingsProvider);

    Formatters.applySettings(
      currencyCode: settings?.currencyCode ?? 'MZN',
      language: settings?.language ?? 'pt',
    );

    return MaterialApp(
      title: 'TAREQO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: settings?.locale ?? const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
      // U-09: rotas nomeadas para telas empurradas (Menu/Dashboard/
      // Marketplace/Suporte/…). As secções do shell continuam em
      // IndexedStack via `goTo(AppSection)` — sem rota.
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.unknownRoute,
      // O bloqueio biométrico vive no `builder` (acima do Navigator): cobre
      // também sheets/diálogos abertos quando o app é bloqueado em segundo
      // plano — ver app_lock_overlay.dart.
      builder: (context, child) {
        // U-09: regista o contexto para deep links internos
        // (`tareqo://go/<rota>`) — sem isto, links internos não navegam.
        DeepLinkHandler.attachNavigator(context);
        // A11y (U-03): a escala de texto do sistema é respeitada SEM
        // clamp global — WCAG 1.4.4 exige suportar 200%. Os componentes
        // críticos (PDV, cards, sheets, feed) usam Flexible/FittedBox/
        // maxLines para absorver texto ampliado sem overflow; regressões
        // são apanhadas pelos testes de escala (1,3 / 1,6 / 2,0). O
        // AppLockOverlay continua acima do Navigator.
        return AppLockOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

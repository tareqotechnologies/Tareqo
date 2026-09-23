import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/controllers/account_providers.dart';
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
      // O bloqueio biométrico vive no `builder` (acima do Navigator): cobre
      // também sheets/diálogos abertos quando o app é bloqueado em segundo
      // plano — ver app_lock_overlay.dart.
      builder: (context, child) {
        // A11y (plano UI/UX — Fase 3.2): teto global de 1.6× na escala de
        // texto — acessibilidade SEM layouts quebrados. Os componentes
        // críticos (PDV, cards, sheets) absorvem o texto ampliado até o
        // teto com Flexible/FittedBox/maxLines; acima disso o conteúdo
        // perde legibilidade estrutural (Row rígidas estouram).
        final mq = MediaQuery.of(context);
        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.6,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clampedScaler),
          child: AppLockOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

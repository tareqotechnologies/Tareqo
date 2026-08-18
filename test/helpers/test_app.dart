import 'package:flutter/material.dart';

import 'package:dumbhanengue/core/theme/app_theme.dart';
import 'package:dumbhanengue/l10n/generated/app_localizations.dart';

/// [MaterialApp] de teste com o delegate de localização do app e o locale
/// fixado em **pt** — as telas agora consomem `context.l10n` (AppLocalizations)
/// e, sem o delegate, quebrariam; e sem `locale` explícito o framework de
/// teste resolveria `en_US`, fazendo as asserções em português falharem.
///
/// O tema é o [AppTheme.dark] real do app (V3 — dark total): a suíte inteira
/// renderiza as telas sob o tema escuro de produção — teste visual
/// automatizado do modo escuro, incluindo as cores semânticas com variantes
/// por brilho (ver `theme_contrast_test.dart`, que valida as duas variantes).
///
/// Uso: `testApp(home: MinhaTela())` dentro do `ProviderScope`.
Widget testApp({
 required Widget home,
 Locale locale = const Locale('pt'),
}) {
 return MaterialApp(
 locale: locale,
 theme: AppTheme.dark,
 localizationsDelegates: AppLocalizations.localizationsDelegates,
 supportedLocales: AppLocalizations.supportedLocales,
 home: home,
 );
}

import 'package:flutter/material.dart';

import 'package:dumbhanengue/l10n/generated/app_localizations.dart';

/// [MaterialApp] de teste com o delegate de localização do app e o locale
/// fixado em **pt** — as telas agora consomem `context.l10n` (AppLocalizations)
/// e, sem o delegate, quebrariam; e sem `locale` explícito o framework de
/// teste resolveria `en_US`, fazendo as asserções em português falharem.
///
/// Uso: `testApp(home: MinhaTela())` dentro do `ProviderScope`.
Widget testApp({
  required Widget home,
  Locale locale = const Locale('pt'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

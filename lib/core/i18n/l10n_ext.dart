import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Atalho para as traduções geradas pelo gen-l10n:
/// `context.l10n.algumaChave` em vez de `AppLocalizations.of(context)!...`.
///
/// `nullable-getter: false` na l10n.yaml garante que [AppLocalizations.of]
/// nunca retorna null (crash explícito se o delegate faltar no widget tree —
/// os testes de widget devem incluir `AppLocalizations.localizationsDelegates`).
extension L10nBuildContext on BuildContext {
 AppLocalizations get l10n => AppLocalizations.of(this);
}

import 'package:flutter/foundation.dart' show kIsWeb;

/// URL de retorno dos links enviados por e-mail pelo Supabase
/// (confirmação de conta e recuperação de palavra-passe).
///
/// **Nativo:** `tareqo://callback` — scheme registado no `AndroidManifest.xml`
/// e no `Info.plist`, capturado pelo `DeepLinkHandler`, que entrega a URI ao
/// gotrue (`getSessionFromUrl`) para trocar o `code` PKCE.
///
/// **Web:** a origem da própria página (ex.:
/// `https://tareqotechnologies.github.io/Tareqo/app/`). O browser não abre um
/// scheme próprio, então o link tem de voltar para o app servido em HTTP.
/// Nesse caso o `supabase_flutter` lê o `?code=` no arranque, troca-o por
/// sessão (`exchangeCodeForSession` — que emite `passwordRecovery` quando o
/// verifier foi gerado por `resetPasswordForEmail`) e limpa a URL.
///
/// [isWeb] e [baseUri] existem para teste: em `flutter test` o `kIsWeb` é
/// sempre `false` e o `Uri.base` não é a página do app.
String authRedirectUrl({bool isWeb = kIsWeb, Uri? baseUri}) {
  if (!isWeb) return 'tareqo://callback';
  final base = baseUri ?? Uri.base;
  final path = base.path.isEmpty ? '/' : base.path;
  return '${base.origin}$path';
}

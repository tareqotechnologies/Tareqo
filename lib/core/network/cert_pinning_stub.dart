import 'package:http/http.dart' as http;

/// Stub da WEB: sem pinning (o navegador gerencia o TLS com o trust store do
/// SO; `dart:io` não existe). Retorna `null` — o [TimeoutRetryHttpClient]
/// usa o cliente padrão. Limitação documentada (mesma da sessão na web).
http.Client? buildPinnedHttpClient() => null;

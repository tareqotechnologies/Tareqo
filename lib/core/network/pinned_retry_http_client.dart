import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'cert_pinning.dart';
import 'timeout_retry_http_client.dart';

/// Cliente HTTP REAL do app: **cert pinning WE1 + timeout/retry** (P2).
///
/// Antes desta correção o pin existia (`cert_pinning_io.dart`) mas NUNCA
/// era injetado no caminho de rede — o `SupabaseBootstrap` passava apenas
/// o [TimeoutRetryHttpClient], com o trust store padrão do SO, e o job
/// `cert-pin-health` do CI monitorava um pin que não protegia nada.
///
/// Agora o cliente interno é o [buildPinnedHttpClient] (SecurityContext
/// com a ÚNICA âncora no intermediário WE1 — trust store do SO ignorado)
/// e o wrapper de timeout/retry fica POR CIMA, preservando o comportamento
/// de timeout 20s + retry de leituras idempotentes (W6).
///
/// WEB (`kIsWeb`): `dart:io`/`SecurityContext` não existem —
/// `buildPinnedHttpClient()` é o stub e devolve `null`; o wrapper usa o
/// cliente padrão do navegador (mesma limitação documentada da sessão).
/// O pin é fail-closed no nativo: se o PEM não compilar (impossível em
/// runtime — é constante) ou a cadeia não terminar no WE1, o handshake
/// falha e a chamada é rejeitada.
http.Client buildPinnedRetryHttpClient() {
  final pinned = kIsWeb ? null : buildPinnedHttpClient();
  return TimeoutRetryHttpClient(inner: pinned);
}

/// Certificate pinning do cliente HTTP (auditoria 2026-08 — V2).
///
/// Na plataforma nativa o cliente é construído com um [SecurityContext] que
/// confia APENAS no intermediário WE1 (Google Trust Services) — a cadeia do
/// Supabase (leaf → WE1 → GTS Root R4). Com `withTrustedRoots: false`, o
/// trust store do SO é ignorado: uma CA user-installed (proxy corporativo,
/// malware) NÃO valida a cadeia, e o handshake falha — o pin cobre o cenário
/// de MITM que o TLS padrão não cobre.
///
/// Por que ancorar no INTERMEDIÁRIO e não no leaf? O leaf do Supabase
/// rotaciona (o atual expira em set/2026); o WE1 é estável até 2028 — a
/// rotação normal do leaf continua funcionando sem quebrar o app.
///
/// Na WEB o módulo é um stub (sem pin — `dart:io` não existe): mesma
/// limitação documentada do armazenamento de sessão (localStorage).
library;

export 'cert_pinning_stub.dart' if (dart.library.io) 'cert_pinning_io.dart';

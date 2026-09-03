import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';

import 'package:tareqo/core/security/pending_op_payload_cipher.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';

/// Backend de armazenamento em memória (sem plataforma) — mesmo padrão dos
/// testes de `SecureStorageService`.
class _InMemorySecureBackend implements SecureStorageBackend {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  late _InMemorySecureBackend backend;
  late SecureStorageService secure;
  late PendingOpPayloadCipher cipher;

  setUp(() {
    backend = _InMemorySecureBackend();
    secure = SecureStorageService(backend: backend);
    cipher = PendingOpPayloadCipher(secure);
  });

  test('round-trip: cifrar e decifrar devolve o JSON original', () async {
    const payload =
        '{"sale":{"id":"s1","totalAmountCents":12500,'
        '"items":[{"productName":"Arroz","quantity":2}]}}';

    final encrypted = await cipher.encrypt(payload);
    final decrypted = await cipher.decrypt(encrypted);

    expect(decrypted, payload);
  });

  test('mesmo JSON cifrado duas vezes gera bytes DIFERENTES (nonce)', () async {
    const payload = '{"debt":{"personName":"João da Silva","amount":2500}}';

    final a = await cipher.encrypt(payload);
    final b = await cipher.encrypt(payload);

    expect(a, isNot(equals(b)));
    // E ambos decifram para o mesmo original.
    expect(await cipher.decrypt(a), payload);
    expect(await cipher.decrypt(b), payload);
  });

  test('o texto claro NUNCA aparece no valor persistido', () async {
    const payload = '{"sale":{"id":"s-secreta","personName":"Maria"}}';

    final encrypted = await cipher.encrypt(payload);

    expect(encrypted, isNot(contains('s-secreta')));
    expect(encrypted, isNot(contains('Maria')));
    expect(encrypted, isNot(contains('sale')));
  });

  test('a chave é gerada uma vez e persistida no secure storage', () async {
    await cipher.encrypt('{"a":1}');
    final stored = await secure.read(PendingOpPayloadCipher.keyStorageKey);

    expect(stored, isNotNull);
    expect(stored!.length, greaterThan(32)); // base64 de 32 bytes

    // Um SEGUNDO cipher lê a MESMA chave e decifra o que o primeiro cifrou.
    final second = PendingOpPayloadCipher(
      SecureStorageService(backend: backend),
    );
    final encrypted = await second.encrypt('{"persistido":true}');
    expect(await cipher.decrypt(encrypted), '{"persistido":true}');
  });

  test('dado adulterado lança erro de autenticação', () async {
    final encrypted = await cipher.encrypt('{"amountCents":100}');
    // Decodifica, corrompe um byte no ciphertext e re-encode — assim
    // o base64 é válido mas o MAC não bate (SecretBoxAuthenticationError)
    // OU o plaintext decodificado é inválido (FormatException).
    final bytes = base64Decode(encrypted);
    // Corrompe no MEIO do ciphertext (depois do nonce, antes do MAC).
    final nonceLen = 12; // AES-GCM nonce
    final macLen = 16;   // AES-GCM MAC
    final cipherEnd = bytes.length - macLen;
    final target = nonceLen + ((cipherEnd - nonceLen) ~/ 2);
    bytes[target] = (bytes[target] + 1) % 256;
    final tampered = base64Encode(bytes);

    expect(
      () => cipher.decrypt(tampered),
      throwsA(anyOf(
        isA<SecretBoxAuthenticationError>(),
        isA<FormatException>(),
      )),
    );
  });
}

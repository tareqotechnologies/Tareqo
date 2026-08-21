import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'secure_storage_service.dart';

/// Cifra os payloads JSON da fila offline (outbox) em repouso.
///
/// **Por que existe (auditoria de segurança 2026-08, V1):** o outbox
/// (`pending_ops`) guarda o comando ORIGINAL do caminho de dinheiro — venda
/// completa com itens/valores, fiado com nome do cliente, compras. Antes,
/// esse JSON ficava em TEXTO CLARO no SQLite local: qualquer leitura do
/// arquivo (root/JB, backup extraído, malware com acesso ao sandbox) expunha
/// dados financeiros e PII. Com este cipher, cada payload é cifrado com
/// **AES-256-GCM** e a chave vive no **Keystore/Keychain** (via
/// [SecureStorageService]) — copiar o banco não basta sem a chave do
/// hardware.
///
/// Formato persistido (coluna `payload`): `base64( nonce(12) || ciphertext
/// || mac(16) )` — o nonce aleatório por operação garante que o mesmo JSON
/// cifrado duas vezes gera bytes diferentes (sem vazamento por padrões).
///
/// Limitação documentada: na WEB (sem `flutter_secure_storage` 10.x) e na
/// fila em memória dos testes, o cipher não é aplicado — mesma limitação do
/// armazenamento de sessão na web (ver `SupabaseBootstrap`). A fila em
/// memória não persiste entre sessões.
final class PendingOpPayloadCipher {
  PendingOpPayloadCipher(this._secure, {AesGcm? gcm})
    : _gcm = gcm ?? AesGcm.with256bits();

  final SecureStorageService _secure;
  final AesGcm _gcm;

  /// Chave onde a chave mestra (32 bytes, base64) é guardada no
  /// Keystore/Keychain. Prefixo `v1` permite rotação futura (ler a antiga,
  /// migrar e gravar a nova).
  static const String keyStorageKey = 'pending_ops_key_v1';

  SecretKey? _cachedKey;

  /// Lê (ou gera na primeira vez) a chave mestra de 32 bytes.
  Future<SecretKey> _secretKey() async {
    final cached = _cachedKey;
    if (cached != null) return cached;

    final stored = await _secure.read(keyStorageKey);
    if (stored != null) {
      final key = SecretKey(base64Decode(stored));
      _cachedKey = key;
      return key;
    }

    // Primeira execução: gera 32 bytes criptograficamente aleatórios.
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final b64 = base64Encode(bytes);
    await _secure.write(keyStorageKey, b64);
    final key = SecretKey(bytes);
    _cachedKey = key;
    return key;
  }

  /// Cifra o JSON do payload. Saída: `base64(nonce || ciphertext || mac)`.
  Future<String> encrypt(String plaintextJson) async {
    final key = await _secretKey();
    final nonce = _gcm.newNonce();
    final box = await _gcm.encrypt(
      utf8.encode(plaintextJson),
      secretKey: key,
      nonce: nonce,
    );
    // SecretBox.concatenation monta exatamente nonce||cipherText||mac.
    return base64Encode(box.concatenation());
  }

  /// Decifra o payload persistido por [encrypt].
  ///
  /// Lança [SecretBoxAuthenticationError] se a chave não corresponder ou o
  /// dado estiver adulterado — o replay então falha de forma controlada
  /// (a operação é marcada com erro e a fila segue).
  Future<String> decrypt(String storedB64) async {
    final key = await _secretKey();
    final bytes = base64Decode(storedB64);
    final nonceLength = _gcm.nonceLength;
    final macLength = _gcm.macAlgorithm.macLength;
    final box = SecretBox(
      bytes.sublist(nonceLength, bytes.length - macLength),
      nonce: bytes.sublist(0, nonceLength),
      mac: Mac(bytes.sublist(bytes.length - macLength)),
    );
    final clear = await _gcm.decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }
}

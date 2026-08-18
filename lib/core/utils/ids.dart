import 'dart:math';

/// Gerador de IDs únicos para entidades criadas no cliente.
///
/// O padrão anterior (`'p${DateTime.now().microsecondsSinceEpoch}'`) podia
/// colidir quando duas entidades eram criadas no mesmo microssegundo (ou
/// com relógio ajustado), quebrando a chave primária. Este gerador combina
/// um carimbo de tempo (base 36) com 24 bits de entropia criptográfica
/// ([Random.secure]) — colisões tornam-se praticamente impossíveis sem
/// adicionar dependências.
abstract final class AppIds {
 static final Random _random = Random.secure();

 /// Gera um id único com o prefixo [prefix] (ex.: 'p', 's', 't', 'c',
 /// 'd', 'pc', 'st', 'e', 'emp').
 static String newId(String prefix) {
 final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
 final entropy =
 _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
 return '$prefix${micros}_$entropy';
 }
}

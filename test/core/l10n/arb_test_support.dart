import 'dart:io';

/// Suporte partilhado pelos testes que leem os ARBs de `lib/l10n/`.
///
/// O parser tem de ser único (um só sítio onde se decide o que conta como
/// "chave de nível superior") para que os testes nunca discordem entre si.

/// Conteúdo bruto de `lib/l10n/app_<locale>.arb`.
String readArb(String locale) => File('lib/l10n/app_$locale.arb').readAsStringSync();

/// Chaves de nível superior de um ARB, na ordem de aparição — incluindo a
/// metadata `@key` e `@@locale`, que também vivem no nível superior.
List<String> readArbTopLevelKeys(String locale) {
  final arb = readArb(locale);
  return RegExp(r'^  "([^"]+)":', multiLine: true)
      .allMatches(arb)
      .map((m) => m.group(1)!)
      .toList();
}

/// Apenas as chaves de tradução reais (sem `@` inicial).
Set<String> readArbKeys(String locale) => readArbTopLevelKeys(locale)
    .where((key) => !key.startsWith('@'))
    .toSet();

/// Chaves de tradução repetidas dentro do próprio ARB (ex.: blocos
/// históricos duplicados). JSON tolera duplicatas silenciosamente
/// (a última vence), por isso o teste precisa de as apanhar explicitamente.
List<String> duplicatedArbKeys(String locale) {
  final seen = <String, int>{};
  for (final key in readArbTopLevelKeys(locale)) {
    if (key.startsWith('@')) continue;
    seen.update(key, (count) => count + 1, ifAbsent: () => 1);
  }
  return seen.entries
      .where((e) => e.value > 1)
      .map((e) => e.key)
      .toList()
    ..sort();
}

/// Metadata `@foo` cuja chave real `foo` não existe no mesmo ARB.
/// `@@locale` (metadata de sistema) não é um bloco `@key` e é ignorado.
List<String> orphanMetadataKeys(String locale) {
  final keys = readArbKeys(locale);
  return readArbTopLevelKeys(locale)
      .where(
        (key) =>
            key.startsWith('@') &&
            !key.startsWith('@@') &&
            !keys.contains(key.substring(1)),
      )
      .toList()
    ..sort();
}

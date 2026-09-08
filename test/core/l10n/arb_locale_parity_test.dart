import 'package:flutter_test/flutter_test.dart';

import 'arb_test_support.dart';

/// Garantia de paridade entre os ARBs: nenhuma chave pode existir em só um
/// idioma. Quando uma chave muda no `app_pt.arb` (template do `l10n.yaml`),
/// o mesmo acrescento/remoção/rename tem de ser feito no `app_en.arb` e no
/// `app_fr.arb` — senão este teste falha e mostra exactamente as chaves em
/// falta e as que sobraram.
///
/// Complementa o `arb_keys_referenced_test.dart`: lá garante-se que nenhuma
/// chave está órfã no código; aqui garante-se que os três ARBs nunca
/// divergem entre si (chaves, duplicatas e metadata `@key`).
void main() {
  const locales = ['pt', 'en', 'fr'];

  test('en e fr têm exactamente as mesmas chaves que pt', () {
    final sets = {for (final locale in locales) locale: readArbKeys(locale)};
    final pt = sets['pt']!;
    expect(pt, isNotEmpty, reason: 'Nenhuma chave encontrada em app_pt.arb');

    for (final locale in locales.skip(1)) {
      final other = sets[locale]!;

      final missing = pt.difference(other).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            'Chaves presentes em app_pt.arb mas ausentes em '
            'app_$locale.arb (acrescente-as ou ajuste o rename também em '
            'app_$locale.arb):\n${missing.join('\n')}',
      );

      final extra = other.difference(pt).toList()..sort();
      expect(
        extra,
        isEmpty,
        reason:
            'Chaves presentes em app_$locale.arb mas ausentes em '
            'app_pt.arb (remova-as ou ajuste o rename também em '
            'app_$locale.arb):\n${extra.join('\n')}',
      );
    }
  });

  test('nenhuma chave real duplicada no mesmo ARB', () {
    for (final locale in locales) {
      final duplicated = duplicatedArbKeys(locale);
      expect(
        duplicated,
        isEmpty,
        reason:
            'Chaves duplicadas em app_$locale.arb '
            '(mantenha apenas a ocorrência canónica):\n'
            '${duplicated.join('\n')}',
      );
    }
  });

  test('nenhuma metadata @key órfã no mesmo ARB', () {
    for (final locale in locales) {
      final orphans = orphanMetadataKeys(locale);
      expect(
        orphans,
        isEmpty,
        reason:
            'Metadata @ sem chave correspondente em app_$locale.arb '
            '(remova-a ou recrie a chave):\n${orphans.join('\n')}',
      );
    }
  });

  test('@@locale corresponde ao ficheiro', () {
    for (final locale in locales) {
      final arb = readArb(locale);
      expect(
        arb,
        contains('"@@locale": "$locale"'),
        reason: 'app_$locale.arb deve declarar "@@locale": "$locale"',
      );
    }
  });
}

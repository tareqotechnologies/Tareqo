import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'arb_test_support.dart';

/// Garantia de que NENHUMA chave dos ARBs está órfã: toda chave de
/// `lib/l10n/app_*.arb` precisa ser referenciada por identificador no código
/// Dart (`l10n.key`, `context.l10n.key`, `AppLocalizations.of(...).key`...)
/// — em `lib/`, `test/`, `integration_test/` ou `tool/`.
///
/// Isto trava o crescimento de chaves mortas: se uma tela deixar de usar uma
/// chave, o teste falha e a chave deve ser removida dos ARBs (os 3 idiomas)
/// — nunca deixada para trás.
///
/// O escaneamento ignora a pasta `lib/l10n/` inteira — o `generated/` do
/// gen-l10n declara todas as chaves por construção e mascararia chaves
/// mortas. Comentários `//` e `/* */` também são descartados, para que uma
/// chave citada apenas num comentário não conte como uso real.
void main() {
  test('toda chave do ARB é referenciada no código', () {
    // A paridade de chaves entre pt/en/fr é garantida pelo teste dedicado
    // arb_locale_parity_test.dart; aqui basta o conjunto de pt (template).
    final keys = readArbKeys('pt');
    expect(keys, isNotEmpty, reason: 'Nenhuma chave encontrada nos ARBs');

    final code = _dartSources().join('\n');
    final missing = keys.where((key) => !_isReferenced(code, key)).toList()
      ..sort();

    expect(
      missing,
      isEmpty,
      reason: 'Chaves l10n sem referência no código '
          '(remova-as dos 3 ARBs):\n'
          '${missing.join('\n')}',
    );
  });
}

/// Conteúdo de todos os ficheiros `.dart` do projeto (lib, test,
/// integration_test e tool), exceto `lib/l10n/` — que só contém a saída do
/// gen-l10n, que declara todas as chaves.
List<String> _dartSources() {
  final result = <String>[];

  void walk(Directory dir) {
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is Directory) {
        if (entity.path.contains('l10n')) continue;
        walk(entity);
        continue;
      }
      final path = entity.path;
      if (!path.endsWith('.dart')) continue;
      result.add(File(path).readAsStringSync());
    }
  }

  walk(Directory('lib'));
  walk(Directory('test'));
  if (Directory('integration_test').existsSync()) {
    walk(Directory('integration_test'));
  }
  if (Directory('tool').existsSync()) {
    walk(Directory('tool'));
  }
  return result;
}

/// Procura o identificador da chave fora de comentários `//` e `/* */`.
bool _isReferenced(String code, String key) {
  final withoutComments = code
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
  return RegExp('\\b${RegExp.escape(key)}\\b').hasMatch(withoutComments);
}

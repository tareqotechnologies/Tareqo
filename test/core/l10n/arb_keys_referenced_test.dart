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

    final code = _dartSources().map(_stripCommentLines).join('\n');
    final missing = keys.where((key) => !_isReferenced(code, key)).toList()
      ..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'Chaves l10n sem referência no código '
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
///
/// A remoção de comentários é feita por ARQUIVO (via [stripDartComments]) —
/// nunca sobre as fontes concatenadas. Concatenar antes de remover faz um
/// `/*` dentro de um comentário de linha (ex.: `/// ... env/*.env`) engolir
/// tudo até um `*/` num arquivo posterior, escondendo referências reais e
/// falhando o teste de chaves órfãs com falso positivo.
bool _isReferenced(String code, String key) =>
    RegExp('\\b${RegExp.escape(key)}\\b').hasMatch(code);

/// Remove comentários `//…` (incluindo `///`) e blocos `/*…*/` de um único
/// fonte Dart, preservando strings e deixando um `\n` no lugar de cada linha
/// de comentário (as âncoras `^`/`$` e os números de linha permanecem
/// coerentes). Um `/*` ou `//` dentro de string/interpolação NÃO abre
/// comentário — e um `/*` dentro de comentário de linha é consumido com ele.
String stripDartComments(String source) {
  final out = StringBuffer();
  var i = 0;
  String? stringDelimiter; // ' ou "
  while (i < source.length) {
    final ch = source[i];
    final next = i + 1 < source.length ? source[i + 1] : '';

    // Dentro de string: consome até o delimitador fechante (ou escape).
    if (stringDelimiter != null) {
      if (ch == '\\') {
        out.write(ch);
        if (next != '') {
          out.write(next);
          i += 2;
          continue;
        }
      } else {
        if (ch == stringDelimiter) stringDelimiter = null;
        out.write(ch);
      }
      i++;
      continue;
    }

    // Abertura de string (prefixos r/R não mudam o delimitador de fecho;
    // triples ''' e """ fecham com 3 — tratadas como ' e " porque um
    // delimitador solto não abre comentário antes de fechar a string).
    if (ch == '"' || ch == "'") {
      stringDelimiter = ch;
      out.write(ch);
      i++;
      continue;
    }

    // Comentário de linha: consome até o fim da linha (deixa o \n).
    if (ch == '/' && next == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }

    // Comentário de bloco: consome até `*/` (ou o fim do arquivo).
    if (ch == '/' && next == '*') {
      i += 2;
      while (i < source.length &&
          !(source[i] == '*' &&
              i + 1 < source.length &&
              source[i + 1] == '/')) {
        // Preserva quebras de linha para manter a contagem de linhas.
        if (source[i] == '\n') out.write('\n');
        i++;
      }
      i = i + 2 < source.length + 1 ? i + 2 : source.length;
      continue;
    }

    out.write(ch);
    i++;
  }
  return out.toString();
}

/// Remove blocos /* */ e linhas de comentario // (sem seguir strings). Mais simples e
/// verificavel que a maquina de estados de stripDartComments, que desalinhava
/// codigo apos comentarios com aspas.
String _stripCommentLines(String source) {
  final noBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return noBlocks
      .split(RegExp(r'\r\n|\r|\n'))
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

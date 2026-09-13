"""Gera test/l10n/app_localizations_sweep_test.dart a partir do catálogo l10n.

Para cada locale (pt/en/fr) emite:
- um mapa `getters` nome -> valor, referenciando CADA getter da classe
  gerada (remover/renomear membro quebra a compilação do teste);
- um mapa `methods` nome -> lista de invocações com variantes de argumentos
  (exercita os ramos de plural =0 / =1 / other).

O teste compara os valores com os ARBs lidos em RUNTIME (dart:io), então o
teste continua válido quando as traduções mudam sem regeneração.
"""
import json
import re
import sys

SRC = 'lib/l10n/generated/app_localizations.dart'
OUT = 'test/l10n/app_localizations_sweep_test.dart'

src = open(SRC, encoding='utf-8').read()
abstract = re.search(
    r'abstract class AppLocalizations \{(.*?)\n\}\n\nclass _AppLocalizationsDelegate',
    src, re.S,
).group(1)

members = []  # (name, [(ptype, pname)])
for m in re.finditer(r'^  String (?:get (\w+)|(\w+)\(([^)]*)\));', abstract, re.M):
    if m.group(1):
        members.append((m.group(1), []))
    else:
        params = []
        for p in m.group(3).split(','):
            p = p.strip()
            if not p:
                sys.exit(f'param vazio em {m.group(2)}')
            ptype, pname = p.rsplit(' ', 1)
            params.append((ptype, pname))
        members.append((m.group(2), params))

getters = [(n, ps) for n, ps in members if not ps]
methods = [(n, ps) for n, ps in members if ps]
print(f'members={len(members)} getters={len(getters)} methods={len(methods)}')

LOCALES = [('Pt', 'pt'), ('En', 'en'), ('Fr', 'fr')]

# Valor padrão por tipo de parâmetro; para o 1º parâmetro numérico também
# emitimos 0 e 1 (ramos =0/=1 dos plurais).
DEFAULT_ARGS = {
    'int': '2',
    'num': '2',
    'String': "'X'",
    'Object': "'X'",
}
ZERO_ONE = {'int': ['0', '1'], 'num': ['0', '1']}


def invoke(name, params, first_override=None):
    args = []
    for i, (ptype, pname) in enumerate(params):
        if i == 0 and first_override is not None and ptype in ZERO_ONE:
            args.append(first_override)
        else:
            args.append(DEFAULT_ARGS.get(ptype, "'X'"))
    return f'l.{name}({", ".join(args)})'


w = open(OUT, 'w', encoding='utf-8')
P = w.write

P('// GENERATED-STYLE TEST — gerado por `tool/gen_l10n_test.py` a partir do\n')
P('// catálogo `app_localizations.dart` + ARBs. Reexecute o script após\n')
P('// adicionar/remover chaves (os mapas de membros são estáticos de\n')
P('// propósito: remover membro quebra a compilação, não silenciosamente).\n')
P('//\n')
P('// Contrato validado por locale (pt/en/fr):\n')
P('// - TODOS os getters devolvem EXATAMENTE o valor do ARB (sem vazio,\n')
P("//   sem chave ausente, sem divergência pt/en/fr);\n")
P('// - TODOS os métodos parametrizados executam os ramos de plural\n')
P('//   (=0, =1, other) e interpolam argumentos sem erro;\n')
P('// - paridade bidirecional ARB <-> classe (nenhum dos lados sobrando);\n')
P('// - núcleo: lookup por idioma, rejeição de locale não suportado,\n')
P('//   delegate (isSupported/shouldReload/load) e classe base.\n')
P("import 'dart:convert';\n")
P("import 'dart:io';\n")
P('')
P("import 'package:flutter/material.dart';\n")
P("import 'package:flutter_test/flutter_test.dart';\n")
P('')
P("import 'package:tareqo/l10n/generated/app_localizations.dart';\n")
P("import 'package:tareqo/l10n/generated/app_localizations_en.dart';\n")
P("import 'package:tareqo/l10n/generated/app_localizations_fr.dart';\n")
P("import 'package:tareqo/l10n/generated/app_localizations_pt.dart';\n")
P('')
P(f'/// Total de membros do catálogo: {len(members)} '
  f'({len(getters)} getters + {len(methods)} métodos).\n')
P(f'const int kTotalMembers = {len(members)};\n')
P(f'const int kTotalGetters = {len(getters)};\n')
P(f'const int kTotalMethods = {len(methods)};\n')
P('const Set<String> kMethodNames = <String>{')
for name, _ in methods:
    P(f"  '{name}',")
P('};')
P('')
P('/// Carrega os valores de string do ARB (chaves sem `@`).\n')
P('Map<String, String> _loadArb(String locale) {\n')
P("  final file = File('lib/l10n/app_$locale.arb');\n")
P('  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;\n')
P('  return {\n')
P('    for (final e in data.entries)\n')
P("      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,\n")
P('  };\n')
P('}\n')
P('')
P('void main() {\n')
P("  group('núcleo — lookup, delegates e classe base', () {\n")
P("    test('lookupAppLocalizations resolve pt/en/fr e rejeita não suportado', () {\n")
P("      expect(lookupAppLocalizations(const Locale('pt')), isA<AppLocalizationsPt>());\n")
P("      expect(lookupAppLocalizations(const Locale('en')), isA<AppLocalizationsEn>());\n")
P("      expect(lookupAppLocalizations(const Locale('fr')), isA<AppLocalizationsFr>());\n")
P("      // Subtag ignorada: resolve pelo languageCode.\n")
P("      expect(lookupAppLocalizations(const Locale('pt', 'BR')), isA<AppLocalizationsPt>());\n")
P('      expect(\n')
P("        () => lookupAppLocalizations(const Locale('es')),\n")
P('        throwsFlutterError,\n')
P('      );\n')
P('    });\n')
P('')
P("    test('delegate: isSupported, shouldReload e load', () {\n")
P('      const delegate = AppLocalizations.delegate;\n')
P("      expect(delegate.isSupported(const Locale('pt')), isTrue);\n")
P("      expect(delegate.isSupported(const Locale('en')), isTrue);\n")
P("      expect(delegate.isSupported(const Locale('fr')), isTrue);\n")
P("      expect(delegate.isSupported(const Locale('es')), isFalse);\n")
P('      expect(delegate.shouldReload(delegate), isFalse);\n')
P('      expect(\n')
P("        delegate.load(const Locale('pt')),\n")
P('        completion(isA<AppLocalizationsPt>()),\n')
P('      );\n')
P('    });\n')
P('')
P("    test('estáticos: supportedLocales e localizationsDelegates', () {\n")
P('      expect(\n')
P('        AppLocalizations.supportedLocales.map((l) => l.languageCode),\n')
P("        containsAll(['pt', 'en', 'fr']),\n")
P('      );\n')
P('      expect(\n')
P('        AppLocalizations.localizationsDelegates,\n')
P('        contains(AppLocalizations.delegate),\n')
P('      );\n')
P('    });\n')
P('')
P("    test('classe base: localeName', () {\n")
P('      final l = AppLocalizationsPt();\n')
P("      expect(l.localeName, 'pt');\n")
P('    });\n')
P('  });\n')

for suffix, loc in LOCALES:
    class_name = f'AppLocalizations{suffix}'
    P('\n')
    P(f"  group('{class_name} — varredura dos $kTotalMembers membros', () {{\n")
    # Getters vs ARB
    P("    test('getters: valor EXATAMENTE igual ao ARB e paridade de chaves', () {\n")
    P(f'      final l = {class_name}();\n')
    P('      final getters = <String, String>{\n')
    for name, _ in getters:
        P(f"        '{name}': l.{name},\n")
    P('      };\n')
    P('      expect(getters, hasLength(kTotalGetters));\n')
    P(f"      final arb = _loadArb('{loc}');\n")
    P('      // Paridade bidirecional: nenhum membro sobrando na classe nem\n')
    P('      // no ARB (chave adicionada sem regenerar falha aqui). As chaves\n')
    P('      // dos métodos parametrizados ficam no ARB mas não no mapa de\n')
    P('      // getters — são subtraídas via kMethodNames.\n')
    P('      expect(getters.keys.toSet(), equals(arb.keys.toSet().difference(kMethodNames)));\n')
    P('      getters.forEach((key, actual) {\n')
    P("        expect(actual, arb[key], reason: '$key divergiu do ARB " + loc + "');\n")
    P('      });\n')
    P('    });\n')
    # Methods
    P("    test('métodos: ramos de plural (=0, =1, other) e interpolação executam', () {\n")
    P(f'      final l = {class_name}();\n')
    P('      final methods = <String, List<String Function(AppLocalizations)>>{\n')
    for name, params in methods:
        invocations = [invoke(name, params)]
        if params and params[0][0] in ZERO_ONE:
            invocations.insert(0, invoke(name, params, first_override='0'))
            invocations.insert(1, invoke(name, params, first_override='1'))
        P(f"        '{name}': [")
        for inv in invocations:
            P(f'          (l) => {inv},')
        P('        ],')
    P('      };\n')
    P('      expect(methods, hasLength(kTotalMethods));\n')
    P('      methods.forEach((name, fns) {\n')
    P('        for (final fn in fns) {\n')
    P('          final result = fn(l);\n')
    P("          expect(result, isNotEmpty, reason: '$name devolveu string vazia');\n")
    P('        }\n')
    P('      });\n')
    P('    });\n')
    P('  });')

P('}\n')
w.close()
print('written', OUT)

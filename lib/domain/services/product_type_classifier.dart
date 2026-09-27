import '../entities/product.dart';

/// Classificador one-off de tipo estrutural do produto (backfill da Fase 1).
///
/// A coluna `products.type` nasceu com `DEFAULT 'resale'`: produtos antigos
/// continuaram compráveis e vendáveis sem reclassificação automática. Este
/// helper existe para o passo OPCIONAL de backfill (runbook 24, Passo 6.4):
/// dado o NOME do produto, sugere o [ProductType] mais provável por uma
/// tabela de palavras-chave ORDENADA.
///
/// É deliberadamente heurístico — o resultado é uma SUGESTÃO para revisão, não
/// uma verdade. A regra que casou fica sempre no [ProductTypeSuggestion.reason]
/// para o relatório do backfill. A ordem das regras é a precedência: a
/// primeira que casa vence (ex.: `pastel de carne` é produzido, não matéria-
/// prima, porque a regra de `manufactured` vem antes da de `rawMaterial`).
///
/// A comparação ignora MAIÚSCULAS/minúsculas e ACENTOS (`açúcar` = `acucar`) e
/// casa TOKENS inteiros (palavra ou frase delimitada) — `sal` NÃO casa
/// `salada`. Palavras-chave devem ser minúsculas e sem acento.
class ProductTypeClassifier {
  const ProductTypeClassifier({this.rules = defaultRules});

  /// Regra de classificação: um [ProductType] e as palavras-chave que o
  /// disparam. É dado (facilmente estendível) — não há lógica por regra.
  final List<ProductTypeRule> rules;

  /// Tabela padrão, na ordem de PRECEDÊNCIA (mais específico primeiro).
  static const List<ProductTypeRule> defaultRules = <ProductTypeRule>[
    // 1. Composto/montado — pratos prontos com nome de lanche completo.
    ProductTypeRule(ProductType.composite, <String>[
      'hamburguer',
      'hamburger',
      'cheeseburger',
      'sanduiche',
      'sandwich',
      'wrap',
      'kebab',
      'cachorro quente',
      'hot dog',
      'hotdog',
      'combo',
      'marmita',
      'refeicao',
      'prato feito',
      'pizza',
    ]),
    // 2. Embalagem/material de consumo — o que embala ou acompanha.
    ProductTypeRule(ProductType.packaging, <String>[
      'caixa',
      'caixas',
      'saco',
      'sacos',
      'sacola',
      'sacolas',
      'copo',
      'copos',
      'tampa',
      'tampas',
      'guardanapo',
      'guardanapos',
      'talher',
      'talheres',
      'garfo',
      'faca',
      'colher',
      'embalagem',
      'embalagens',
      'pacote',
      'pacotes',
      'filme',
      'aluminio',
      'canudo',
      'canudos',
      'prato',
      'pratos',
      'recipiente',
      'bandeja',
      'caixinha',
      'rotulo',
      'etiqueta',
      'etiquetas',
      'papel',
      'toalha',
      'palito',
      'espeto',
      'fita',
    ]),
    // 3. Revenda — comprado pronto (bebidas, snacks, embalados).
    ProductTypeRule(ProductType.resale, <String>[
      'agua',
      'refrigerante',
      'refrigerantes',
      'sumo',
      'sumos',
      'suco',
      'cerveja',
      'vinho',
      'lata',
      'latas',
      'garrafa',
      'garrafas',
      'chiclete',
      'rebucado',
      'gomas',
      'chips',
      'bolacha',
      'bolachas',
      'gelado',
      'sorvete',
      'energetico',
      'isotonico',
      'nectar',
      'refresco',
      'batata frita',
      'batatas fritas',
    ]),
    // 4. Produzido — fabricado internamente (padaria/pastelaria/doces).
    ProductTypeRule(ProductType.manufactured, <String>[
      'pao',
      'paes',
      'croissant',
      'croissants',
      'empada',
      'empadas',
      'bolo',
      'bolos',
      'pastel',
      'pasteis',
      'coxinha',
      'coxinhas',
      'quiche',
      'torta',
      'tortas',
      'donut',
      'rosquinha',
      'rosquinhas',
      'baguete',
      'brioche',
      'sonho',
      'sonhos',
      'rissol',
      'folhado',
      'folhados',
      'queque',
      'muffin',
      'cupcake',
      'cookie',
      'cookies',
      'biscoito',
      'biscoitos',
      'brownie',
      'tarte',
      'salgado',
      'salgados',
      'esfiha',
      'esfihas',
      'pudim',
      'mousse',
    ]),
    // 5. Matéria-prima — ingrediente consumido pela produção.
    ProductTypeRule(ProductType.rawMaterial, <String>[
      'farinha',
      'acucar',
      'sal',
      'ovo',
      'ovos',
      'leite',
      'manteiga',
      'margarina',
      'oleo',
      'azeite',
      'fermento',
      'carne',
      'frango',
      'peixe',
      'queijo',
      'presunto',
      'arroz',
      'massa',
      'chocolate',
      'cacau',
      'creme',
      'natas',
      'iogurte',
      'tomate',
      'cebola',
      'alho',
      'batata',
      'batatas',
      'banana',
      'maca',
      'laranja',
      'limao',
      'morango',
      'trigo',
      'milho',
      'amido',
      'corante',
      'essencia',
      'baunilha',
      'canela',
      'pimenta',
      'oregano',
      'tempero',
      'especiaria',
      'acai',
      'mel',
      'gelatina',
    ]),
  ];

  /// Sugere o tipo do produto pelo nome. Sem nenhuma regra casada, cai em
  /// [ProductType.resale] — o mesmo default da coluna no banco.
  ProductTypeSuggestion classify(String name) {
    final normalized = _normalize(name);
    final tokens = _tokenize(normalized);
    for (final rule in rules) {
      for (final keyword in rule.keywords) {
        if (_matches(keyword, normalized, tokens)) {
          return ProductTypeSuggestion(type: rule.type, reason: keyword);
        }
      }
    }
    return const ProductTypeSuggestion(
      type: ProductType.resale,
      reason: 'default',
    );
  }
}

/// Regra da tabela de classificação: um [ProductType] e as palavras-chave
/// que o disparam. Palavras-chave devem ser minúsculas e sem acento.
class ProductTypeRule {
  const ProductTypeRule(this.type, this.keywords);

  final ProductType type;
  final List<String> keywords;
}

/// Um produto lido do banco para o backfill.
class ProductTypeCandidate {
  const ProductTypeCandidate({
    required this.id,
    required this.name,
    required this.currentType,
  });

  final String id;
  final String name;
  final ProductType currentType;
}

/// Uma reclassificação PROPOSTA pelo backfill (não aplicada — `from` → `to`).
class ProductTypeBackfillEntry {
  const ProductTypeBackfillEntry({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.reason,
  });

  final String id;
  final String name;
  final ProductType from;
  final ProductType to;
  final String reason;

  /// Só verdadeiro quando o backfill realmente muda o tipo.
  bool get changes => from != to;
}

/// Resultado do classificador (sugestão + regra que a disparou).
class ProductTypeSuggestion {
  const ProductTypeSuggestion({required this.type, required this.reason});

  final ProductType type;

  /// Palavra-chave que casou, ou `default` quando nenhuma regra casou.
  final String reason;
}

/// Monta o plano de backfill a partir dos produtos lidos do banco.
///
/// Por padrão ([onlyResale] = true) só propõe mudanças para produtos que ainda
/// estão em [ProductType.resale] — o default legado da Fase 1. Quem já tem um
/// tipo não-revenda foi reclassificado de propósito (UI/backfill anterior) e
/// NÃO é tocado. Use [onlyResale] = false para reaplicar as regras a todos.
List<ProductTypeBackfillEntry> planProductTypeBackfill(
  Iterable<ProductTypeCandidate> candidates, {
  bool onlyResale = true,
  ProductTypeClassifier classifier = const ProductTypeClassifier(),
}) {
  final entries = <ProductTypeBackfillEntry>[];
  for (final candidate in candidates) {
    if (onlyResale && candidate.currentType != ProductType.resale) continue;
    final suggestion = classifier.classify(candidate.name);
    if (suggestion.type == candidate.currentType) continue;
    entries.add(
      ProductTypeBackfillEntry(
        id: candidate.id,
        name: candidate.name,
        from: candidate.currentType,
        to: suggestion.type,
        reason: suggestion.reason,
      ),
    );
  }
  return entries;
}

// ─── Normalização/casamento (pacote privado) ────────────────────────────────

const Map<String, String> _diacritics = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
};

String _normalize(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}

final RegExp _tokenPattern = RegExp(r'[a-z0-9]+');

Set<String> _tokenize(String normalized) =>
    _tokenPattern.allMatches(normalized).map((m) => m.group(0)!).toSet();

bool _matches(String keyword, String normalized, Set<String> tokens) {
  if (keyword.contains(' ')) {
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(keyword)}([^a-z0-9]|\$)',
    );
    return pattern.hasMatch(normalized);
  }
  return tokens.contains(keyword);
}

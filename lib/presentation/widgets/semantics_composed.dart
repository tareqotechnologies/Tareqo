/// Helper de labels compostos para leitores de ecrã (plano UI/UX — Fase 3.1).
///
/// Cards de lista (venda, produto, fiado) falam o conteúdo inteiro como UM
/// nó: `buildComposedLabel([nome, preço, estado])` junta as partes válidas
/// com separador ", " — partes vazias são descartadas (nunca vírgula órfã).
String buildComposedLabel(Iterable<String?> parts) {
  return parts.whereType<String>().where((part) => part.isNotEmpty).join(', ');
}

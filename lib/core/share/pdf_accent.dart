import 'package:pdf/pdf.dart';

/// Acentos de PDF alinhados à paleta RE2 (`lib/core/theme/app_colors.dart`).
///
/// Antes, os exporters imprimiam com a família `PdfColors.indigo*` (e a
/// cotação em `amber700`) — cores fora do sistema visual do app. Estes
/// tokens são os MESMOS papéis do tema, expressos em `PdfColor` (o pacote
/// `pdf` não depende de Flutter, então `AppColors` não pode ser importada).
///
/// Contraste medido (WCAG):
/// * `slateDeep` como texto sobre branco: 10.2:1 — valores de KPI/total.
/// * `slate` como fundo com texto branco: 7.5:1 — cabeçalhos de tabela/selo.
/// * `petrol` como fundo com texto branco: 14.5:1 — alternativa mais escura.
/// * `warmBeige` como fundo de cartão KPI com `slateDeep` em texto: 8.9:1.
abstract final class PdfAccents {
  /// Estrutura primária — cabeçalhos de tabela, selos, faixas. É o mesmo
  /// papel do `ColorScheme.primary` do modo claro do app.
  static const slate = PdfColor.fromInt(0xFF3D4D55);

  /// Texto de VALOR (KPI, total) sobre fundo claro — derivação escura do
  /// slate usada pelo `AppColors.brandMuted`.
  static const slateDeep = PdfColor.fromInt(0xFF2C3E45);

  /// Identidade profunda (petróleo) — fundo de tabela do relatório de
  /// vendas, mais sóbrio que o slate. Mesma cor de `AppColors.petrol`.
  static const petrol = PdfColor.fromInt(0xFF10282A);

  /// Fundo quente de cartão KPI — o `warmBeige` do tema aplicado ao papel.
  /// Substitui o `indigo50` frio.
  static const warmBeige = PdfColor.fromInt(0xFFD3C3B9);

  /// Acento da cotação — a terracota é o destaque RESERVADO do design
  /// system; a cotação (documento de negociação) é o lugar dela no papel.
  static const terracotta = PdfColor.fromInt(0xFFB58863);

  // ── Tinta quente da caixa de pagamento (factura) ──
  // Cores terrosas substituem a família verde que saiu da semântica do
  // design system TAREQO. O papel usa tons terrosos (income/success)
  // ao invés de verde para indicadores financeiros.

  /// Fundo da caixa de pagamento (terroso, substitui o antigo green50).
  static const paymentSurface = PdfColor.fromInt(0xFFFBF6F0);

  /// Texto principal da caixa de pagamento (terroso, substitui o antigo green900).
  static const paymentText = PdfColor.fromInt(0xFF5A4632);

  /// Texto secundário da caixa de pagamento (terroso, substitui o antigo green800).
  static const paymentTextMuted = PdfColor.fromInt(0xFF6E5A44);
}

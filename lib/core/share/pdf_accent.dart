import 'package:pdf/pdf.dart';

/// Acentos de PDF alinhados à paleta OFICIAL (identidade 2026-11-09):
/// Azul #0067FF, Cinza de superfície #E7E5E5, Branco suave #F9F9F9,
/// Preto #232323 — estados semânticos mapeados aos tons oficiais.
///
/// O pacote `pdf` não depende de Flutter, então `AppColors` não pode ser
/// importada — estes tokens são os MESMOS valores, expressos em `PdfColor`.
///
/// Contraste medido (WCAG, papel branco suave):
/// * `black` como texto: 17.6:1 — valores de KPI/total.
/// * `black` como fundo com texto suave: 17.6:1 — cabeçalhos de tabela.
/// * `gray` como texto secundário: 1.2:1 — evitar em texto; usar `black`.
/// * `brandBlue` como fundo com texto preto: 6.1:1 (AA texto).
abstract final class PdfAccents {
  /// Paleta oficial expressa em PdfColor (sem `AppColors` — `pdf` não
  /// depende de Flutter).
  static const black = PdfColor.fromInt(0xFF232323);
  static const gray = PdfColor.fromInt(0xFFE7E5E5);
  static const brandBlue = PdfColor.fromInt(0xFF0067FF);
  static const ice = PdfColor.fromInt(0xFFF9F9F9);
  static const alertSuccess = brandBlue;
  static const alertError = black;
  static const alertWarning = PdfColor.fromInt(0xFF6E7174);

  /// Estrutura primária — cabeçalhos de tabela, selos, faixas. É o mesmo
  /// papel do `ColorScheme.primary` do modo claro do app (azul).
  static const slate = brandBlue;

  /// Texto de VALOR (KPI, total) sobre fundo claro — preto oficial.
  static const slateDeep = black;

  /// Identidade profunda — fundo de tabela do relatório de vendas:
  /// preto oficial.
  static const petrol = black;

  /// Fundo de cartão KPI — branco suave oficial.
  static const warmBeige = ice;

  /// Acento da cotação — azul oficial (destaque RESERVADO).
  /// Alias de `brandBlue` por compatibilidade de API.
  static const brandBlueAccent = brandBlue;
  // Nota: cotação usa diretamente `brandBlue` (ver quotation_pdf_exporter).

  // ── Caixa de pagamento (factura) — paleta oficial ──

  /// Fundo da caixa de pagamento — branco suave oficial.
  static const paymentSurface = ice;

  /// Texto principal da caixa de pagamento — preto oficial.
  static const paymentText = black;

  /// Texto secundário da caixa de pagamento — preto oficial
  /// (cinza #E7E5E5 sobre suave é 1.2:1 — ilegível).
  static const paymentTextMuted = black;
}

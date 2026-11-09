import 'package:pdf/pdf.dart';

/// Acentos de PDF alinhados à paleta OFICIAL (4 cores — nova identidade):
/// Preto #212121, Cinza #757575, Terracota #B7472A, Branco gelo #E0E0E0 —
/// mais os alertas semânticos (#2E7D32/#C62828/#F9A825) SÓ em componentes
/// de alerta no papel.
///
/// O pacote `pdf` não depende de Flutter, então `AppColors` não pode ser
/// importada — estes tokens são os MESMOS valores, expressos em `PdfColor`.
///
/// Contraste medido (WCAG, papel branco):
/// * `black` como texto: 15.9:1 — valores de KPI/total.
/// * `black` como fundo com texto gelo: 11.7:1 — cabeçalhos de tabela/selo.
/// * `gray` como texto secundário: 4.8:1 (AA).
/// * `terracotta` como fundo com gelo: 4.0:1 (AA texto grande).
abstract final class PdfAccents {
  /// Paleta oficial expressa em PdfColor (sem `AppColors` — `pdf` não
  /// depende de Flutter).
  static const black = PdfColor.fromInt(0xFF212121);
  static const gray = PdfColor.fromInt(0xFF757575);
  static const terracotta = PdfColor.fromInt(0xFFB7472A);
  static const ice = PdfColor.fromInt(0xFFE0E0E0);
  static const alertSuccess = PdfColor.fromInt(0xFF2E7D32);
  static const alertError = PdfColor.fromInt(0xFFC62828);
  static const alertWarning = PdfColor.fromInt(0xFFF9A825);

  /// Estrutura primária — cabeçalhos de tabela, selos, faixas. É o mesmo
  /// papel do `ColorScheme.primary` do modo claro do app (terracota).
  static const slate = terracotta;

  /// Texto de VALOR (KPI, total) sobre fundo claro — preto oficial.
  static const slateDeep = black;

  /// Identidade profunda — fundo de tabela do relatório de vendas:
  /// preto oficial.
  static const petrol = black;

  /// Fundo de cartão KPI — gelo oficial.
  static const warmBeige = ice;

  /// Acento da cotação — terracota oficial (destaque RESERVADO).
  /// Alias de `terracotta` por compatibilidade de API.
  static const terracottaAccent = terracotta;
  // Nota: cotação usa diretamente `terracotta` (ver quotation_pdf_exporter).

  // ── Caixa de pagamento (factura) — paleta oficial ──

  /// Fundo da caixa de pagamento — gelo oficial.
  static const paymentSurface = ice;

  /// Texto principal da caixa de pagamento — preto oficial.
  static const paymentText = black;

  /// Texto secundário da caixa de pagamento — cinza oficial.
  static const paymentTextMuted = gray;
}

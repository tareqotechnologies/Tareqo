import 'package:pdf/pdf.dart';

/// Acentos de PDF alinhados à paleta OFICIAL (identidade Tareqo 2026 —
/// "Shades of gray"): Preto 100 #0A0E15, Preto 60 #667085,
/// Branco 100 #FFFFFF e Branco 90 #F0F1F5 — estados semânticos com
/// verde/vermelho AA. Sem laranja.
///
/// O pacote `pdf` não depende de Flutter, então `AppColors` não pode ser
/// importada — estes tokens são os MESMOS valores, expressos em `PdfColor`.
///
/// Contraste medido (WCAG, papel branco):
/// * `black` como texto: 19:1 — valores de KPI/total.
/// * `black` como fundo com texto `ice`: 19:1 — cabeçalhos de tabela.
/// * `gray` como texto secundário: 1.2:1 — evitar em texto; usar `black`.
/// * `brandBlue` como fundo com texto `ice`: 19:1 (AA/AAA texto).
abstract final class PdfAccents {
  /// Paleta oficial expressa em PdfColor (sem `AppColors` — `pdf` não
  /// depende de Flutter).
  static const black = PdfColor.fromInt(0xFF0A0E15);
  static const gray = PdfColor.fromInt(0xFFE0E4EB);
  static const brandBlue = PdfColor.fromInt(0xFF0A0E15);
  static const ice = PdfColor.fromInt(0xFFFFFFFF);
  static const alertSuccess = PdfColor.fromInt(0xFF2E7D32);
  static const alertError = PdfColor.fromInt(0xFFC62828);
  static const alertWarning = PdfColor.fromInt(0xFF667085);

  /// Estrutura primária — cabeçalhos de tabela, selos, faixas. É o mesmo
  /// papel do `ColorScheme.primary` do modo claro do app (tinta).
  static const slate = brandBlue;

  /// Texto de VALOR (KPI, total) sobre fundo claro — preto oficial.
  static const slateDeep = black;

  /// Identidade profunda — fundo de tabela do relatório de vendas:
  /// preto oficial.
  static const petrol = black;

  /// Fundo de cartão KPI — branco suave oficial.
  static const warmBeige = ice;

  /// Acento da cotação — tinta oficial (destaque RESERVADO).
  /// Alias de `brandBlue` por compatibilidade de API.
  static const brandBlueAccent = brandBlue;
  // Nota: cotação usa diretamente `brandBlue` (ver quotation_pdf_exporter).

  // ── Caixa de pagamento (factura) — paleta oficial ──

  /// Fundo da caixa de pagamento — branco suave oficial.
  static const paymentSurface = ice;

  /// Texto principal da caixa de pagamento — preto oficial.
  static const paymentText = black;

  /// Texto secundário da caixa de pagamento — preto oficial
  /// (o cinza de superfície claríssimo sobre papel seria ilegível).
  static const paymentTextMuted = black;
}

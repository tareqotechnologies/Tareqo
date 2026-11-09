import 'package:pdf/pdf.dart';

/// Acentos de PDF alinhados à paleta OFICIAL (identidade 2026-11-09):
/// Laranja #FF6A2A, Cinza de superfície #F0F0F0, Branco suave #F9F9F9,
/// Preto #0C0B0A — mais os alertas semânticos (#2E7D32/#C62828/#F9A825)
/// SÓ em componentes de alerta no papel.
///
/// O pacote `pdf` não depende de Flutter, então `AppColors` não pode ser
/// importada — estes tokens são os MESMOS valores, expressos em `PdfColor`.
///
/// Contraste medido (WCAG, papel branco suave):
/// * `black` como texto: 17.6:1 — valores de KPI/total.
/// * `black` como fundo com texto suave: 17.6:1 — cabeçalhos de tabela.
/// * `gray` como texto secundário: 1.2:1 — evitar em texto; usar `black`.
/// * `terracotta` como fundo com texto preto: 6.1:1 (AA texto).
abstract final class PdfAccents {
  /// Paleta oficial expressa em PdfColor (sem `AppColors` — `pdf` não
  /// depende de Flutter).
  static const black = PdfColor.fromInt(0xFF0C0B0A);
  static const gray = PdfColor.fromInt(0xFFF0F0F0);
  static const terracotta = PdfColor.fromInt(0xFFFF6A2A);
  static const ice = PdfColor.fromInt(0xFFF9F9F9);
  static const alertSuccess = PdfColor.fromInt(0xFF2E7D32);
  static const alertError = PdfColor.fromInt(0xFFC62828);
  static const alertWarning = PdfColor.fromInt(0xFFF9A825);

  /// Estrutura primária — cabeçalhos de tabela, selos, faixas. É o mesmo
  /// papel do `ColorScheme.primary` do modo claro do app (laranja).
  static const slate = terracotta;

  /// Texto de VALOR (KPI, total) sobre fundo claro — preto oficial.
  static const slateDeep = black;

  /// Identidade profunda — fundo de tabela do relatório de vendas:
  /// preto oficial.
  static const petrol = black;

  /// Fundo de cartão KPI — branco suave oficial.
  static const warmBeige = ice;

  /// Acento da cotação — laranja oficial (destaque RESERVADO).
  /// Alias de `terracotta` por compatibilidade de API.
  static const terracottaAccent = terracotta;
  // Nota: cotação usa diretamente `terracotta` (ver quotation_pdf_exporter).

  // ── Caixa de pagamento (factura) — paleta oficial ──

  /// Fundo da caixa de pagamento — branco suave oficial.
  static const paymentSurface = ice;

  /// Texto principal da caixa de pagamento — preto oficial.
  static const paymentText = black;

  /// Texto secundário da caixa de pagamento — preto oficial
  /// (cinza #F0F0F0 sobre suave é 1.2:1 — ilegível).
  static const paymentTextMuted = black;
}

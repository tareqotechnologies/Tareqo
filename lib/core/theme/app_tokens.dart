import 'package:flutter/material.dart';

/// Design tokens V4 — espaçamento, raios, durações e tamanhos.
///
/// Grelha de 4px para consistência entre todas as telas e componentes.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Padding horizontal padrão de páginas (mobile).
  static const double pageHorizontal = lg;

  /// Padding horizontal em telas largas (tablet/web).
  static const double pageHorizontalWide = xxl;

  /// Resolve o padding horizontal conforme a largura do ecrã.
  static double pagePaddingForWidth(double width) =>
      width >= 720 ? pageHorizontalWide : pageHorizontal;
}

/// Raios de canto do design system V4.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
}

/// Durações de animação padronizadas.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
}

/// Tamanhos de componentes reutilizáveis.
abstract final class AppSizes {
  static const double touchTarget = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double avatarSm = 36;
  static const double avatarMd = 42;
  static const double navBarHeight = 72;
  static const double contentMaxWidth = 1040;
}

/// Curvas de animação naturais.
abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve emphasized = Curves.easeInOutCubic;
}

/// Borda tracejada circular — o traço do cupom térmico reaproveitado como
/// linguagem de "valor diferente do padrão" (ajuste manual no recibo, valor
/// recebido ≠ total no fiado) e como contorno de ícones dashed.
abstract final class DashedBorders {
  /// Espessura do traço (discreta: decoração, não alerta).
  static const double strokeWidth = 1.4;

  /// Número de tracejos ao redor do círculo completo.
  static const int dashCount = 12;

  /// Fração do arco ocupada por cada tracejo (o resto é intervalo).
  static const double dashFraction = 0.55;

  /// Recuo da borda em relação ao raio do container.
  static const double inset = 2;
}

/// Cores de módulo — conjunto fechado de 6 cores profissionais
/// para os módulos do Menu e ícones de navegação.
///
/// Cada cor tem uma versão escura (fundo circular) e uma versão
/// clara (ícone sobre fundo escuro) derivadas automaticamente.
/// ATENÇÃO: estas cores são pré-definidas e NÃO devem ser
/// substituídas por cores aleatórias nos ecrãs.
abstract final class ModuleColors {
  /// Produtos — azul confiável (estoque, inventário)
  static const Color products = Color(0xFF3B82F6);

  /// Clientes — teal profissional (relações, CRM)
  static const Color customers = Color(0xFF14B8A6);

  /// Crédito/Fiado — âmbar quente (atenção, pendências)
  static const Color credit = Color(0xFFD97706);

  /// Compras — violeta sofisticado (approvisionnement)
  static const Color purchases = Color(0xFF7C3AED);

  /// Relatórios — azul-profundo (análise, dados)
  static const Color reports = Color(0xFF2563EB);

  /// Lojas — slate profissional (administração)
  static const Color stores = Color(0xFF475569);
}

/// Padrão de ícones com fundo sólido escuro — replicado do feed
/// de atividade da Home. Cada ícone tem um container circular
/// com fundo escuro (mesma família de cor) e ícone CLARO que
/// contrasta bem sobre esse fundo.
abstract final class IconTone {
  /// Deriva um background sólido ESCURO a partir de uma cor.
  /// Converte para HSL, zera a lightness para ~12% e mantém a
  /// saturação — resultado: mesmo matiz, tom sólido escuro.
  static Color darkBackground(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.12).toColor();
  }

  /// Deriva uma cor CLARA para ícone sobre fundo escuro.
  /// Converte para HSL, aumenta a lightness para ~75% e reduz
  /// saturação para ~60% — garante contraste ≥ 4.5:1 sobre
  /// qualquer darkBackground derivado da mesma cor.
  static Color lightForeground(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(0.75)
        .withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0))
        .toColor();
  }

  // ── Cores pré-definidas (padrão do activity feed) ──
  static const Color green = Color(0xFF16A34A);
  static const Color greenDark = Color(0xFF123F26);
  static const Color amber = Color(0xFFD97706);
  static const Color amberDark = Color(0xFF3A2810);
  static const Color red = Color(0xFFDC2626);
  static const Color redDark = Color(0xFF3A1618);
  static const Color slate = Color(0xFF2A3034);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF0F1D3A);
  static const Color teal = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0A2E2B);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetDark = Color(0xFF1E1540);
}

import 'package:flutter/material.dart';

/// Design tokens TAREQO Signature — espaçamento, raios, elevação,
/// tamanhos, movimento e curvas.
///
/// Regra: nenhum ecrã deve declarar valores numéricos de layout que já
/// existam aqui. A grelha base é de **4 px**; os tokens de página são
/// 16 (mobile), 24 (tablet) e 32 (≥1024).
abstract final class AppSpacing {
  /// 2 px — ajuste ótico de ícone.
  static const double micro = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double gigantic = 64;

  /// Padding horizontal padrão de páginas (mobile).
  static const double pageHorizontal = md;

  /// Padding horizontal em tablet.
  static const double pageHorizontalTablet = xl;

  /// Padding horizontal em telas largas (web/desktop).
  static const double pageHorizontalWide = xxl;

  /// Resolve o padding horizontal conforme a largura do ecrã.
  static double pagePaddingForWidth(double width) {
    if (width >= 1024) return pageHorizontalWide;
    if (width >= 720) return pageHorizontalTablet;
    return pageHorizontal;
  }

  /// Padding de conteúdo de sheet: horizontal e bottom 24, top 0.
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(24, 0, 24, 24);

  /// Recuo inferior de listas/corpos com FAB sobreposto.
  static const double fabBottomClearance = 96;
}

/// Raios de canto do design system Signature.
abstract final class AppRadius {
  /// 6 — badge pequeno, checkbox.
  static const double xs = 6;

  /// 10 — chip compacto, container de ícone.
  static const double sm = 10;

  /// 14 — **campos e botões** (padrão).
  static const double md = 14;

  /// 18 — **cartões e listas agrupadas**.
  static const double lg = 18;

  /// 22 — diálogos e popovers.
  static const double xl = 22;

  /// 28 — sheets (topo) e painéis.
  static const double xxl = 28;

  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);

  /// Topo arredondado para sheets.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
}

/// Durações de animação padronizadas.
abstract final class AppDurations {
  /// 90 ms — resposta ao toque.
  static const Duration press = Duration(milliseconds: 90);

  /// 120 ms — hover, toggle, chip.
  static const Duration fast = Duration(milliseconds: 120);

  /// 180 ms — botão, campo, seleção.
  static const Duration base = Duration(milliseconds: 180);

  /// 240 ms — sheet, diálogo, expansão.
  static const Duration normal = Duration(milliseconds: 240);

  /// 320 ms — transição de página.
  static const Duration slow = Duration(milliseconds: 320);

  /// 400 ms — contagem de valor-herói (máximo).
  static const Duration deliberate = Duration(milliseconds: 400);
}

/// Tamanhos de componentes reutilizáveis.
abstract final class AppSizes {
  /// Alvo de toque padrão do ERP (48 dp).
  static const double touchTarget = 48;

  static const double controlHeight = 48;
  static const double controlHeightCompact = 40;
  static const double controlHeightHero = 56;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  /// Ícone da navegação inferior/rail — 22dp mantém a barra compacta.
  static const double navIcon = 22;
  static const double iconXl = 28;

  static const double avatarSm = 36;
  static const double avatarMd = 40;
  static const double avatarLg = 48;

  static const double navBarHeight = 64;
  static const double appBarHeight = 56;
  static const double listRowHeight = 64;
  static const double listRowDenseHeight = 56;
  static const double tableRowHeight = 44;

  static const double contentMaxWidth = 1040;
  static const double dialogMaxWidth = 400;
  static const double fabSize = 56;
}

/// Curvas de animação naturais.
abstract final class AppCurves {
  /// `cubic-bezier(0.2, 0, 0, 1)` — maioria dos estados.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// `cubic-bezier(0.32, 0.72, 0, 1)` — entradas (sheet, diálogo).
  static const Curve entrance = Cubic(0.32, 0.72, 0, 1);

  /// `cubic-bezier(0.4, 0, 1, 1)` — saídas.
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  static const Curve decelerate = Curves.decelerate;
  static const Curve emphasized = Curves.easeInOutCubic;
}

/// Elevação Signature — sombras neutras, nunca coloridas.
///
/// No escuro a elevação é sobretudo contorno; as sombras são mais fortes
/// para separar superfícies quase pretas. Os valores centrais ficam aqui
/// para que cartões, sheets, diálogos e menus partilhem a mesma física.
abstract final class AppElevation {
  static const double e0 = 0;
  static const double e1 = 1;
  static const double e2 = 4;
  static const double e3 = 12;
  static const double e4 = 24;

  static const List<BoxShadow> light1 = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> light2 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> light3 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> light4 = [
    BoxShadow(color: Color(0x29000000), blurRadius: 48, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> dark1 = [
    BoxShadow(color: Color(0x66000000), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> dark2 = [
    BoxShadow(color: Color(0x73000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> dark3 = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> dark4 = [
    BoxShadow(color: Color(0x99000000), blurRadius: 56, offset: Offset(0, 24)),
  ];
}

/// Borda tracejada circular — linguagem de "valor diferente do padrão"
/// (ajuste manual no recibo, valor recebido ≠ total no fiado).
abstract final class DashedBorders {
  static const double strokeWidth = 1.4;
  static const int dashCount = 12;
  static const double dashFraction = 0.55;
  static const double inset = 2;
}

/// Cores de módulo — conjunto fechado para tiles do Menu.
///
/// A diferenciação entre módulos vem de matiz **e** luminosidade dentro
/// da família Signature (azul, neutros e um acento quente reservado).
abstract final class ModuleColors {
  /// Produtos — azul-petróleo profundo.
  static const Color products = Color(0xFF0E3A5C);

  /// Clientes — azul-cinza.
  static const Color customers = Color(0xFF2E5A73);

  /// Crédito/Fiado — âmbar profundo (atenção).
  static const Color credit = Color(0xFF9A4A00);

  /// Compras — cinza quente.
  static const Color purchases = Color(0xFF6E6E73);

  /// Relatórios — azul de análise.
  static const Color reports = Color(0xFF0062CC);

  /// Lojas — petróleo-ardósia.
  static const Color stores = Color(0xFF223A41);

  /// Produção — terra queimada.
  static const Color production = Color(0xFF5A4632);
}

/// Ícones com fundo sólido escuro derivado de uma cor.
abstract final class IconTone {
  static Color darkBackground(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.12).toColor();
  }

  static Color lightForeground(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(0.75)
        .withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0))
        .toColor();
  }

  /// Laranja usado para indicar alertas estoque, pendências e destaques.
  static const Color accentOrange = Color(0xFFF28C00);
  /// Laranja escuro para gradiente do botão Confirmar no POS.
  static const Color accentOrangeDark = Color(0xFFB45309);

  /// Cinza neutro para ícones secundários.
  static const Color slate = Color(0xFF3D4D55);

  /// Cinza escuro para fundos de ícones.
  static const Color slateDark = Color(0xFF2A3038);

  /// Vermelho neutro para erros (sem verde dominante).
  static const Color errorNeutral = Color(0xFFB3261E);
  static const Color errorNeutralDark = Color(0xFF7A1E16);

  /// Laranja suave para estados de aviso.
  static const Color amber = Color(0xFFD97706);
  static const Color amberDark = Color(0xFF3A2810);

  /// Textos em modo claro/escuro sobre ícones.
  static const Color onBackgroundLight = Color(0xFF111111);
  static const Color onBackgroundDark = Color(0xFFF5F5F5);
}

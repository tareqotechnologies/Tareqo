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
  /// 2 — raio mínimo (handle de sheet, hairline). U-14: antes literal
  /// `BorderRadius.circular(2)` espalhado por 18 ficheiros.
  static const double microRadius = 2;

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

  static BorderRadius get microAll => BorderRadius.circular(microRadius);
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

/// Elevação — sombras discretas baseadas em #0C0B0A (preto do anexo),
/// nunca coloridas.
///
/// No escuro a elevação é sobretudo contorno; as sombras são mais fortes
/// para separar superfícies pretas. Os valores centrais ficam aqui para
/// que cartões, sheets, diálogos e menus partilhem a mesma física.
abstract final class AppElevation {
  static const double e0 = 0;
  static const double e1 = 1;
  static const double e2 = 4;
  static const double e3 = 12;
  static const double e4 = 24;

  static const List<BoxShadow> light1 = [
    BoxShadow(color: Color(0x0F0C0B0A), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> light2 = [
    BoxShadow(color: Color(0x140C0B0A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> light3 = [
    BoxShadow(color: Color(0x1F0C0B0A), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> light4 = [
    BoxShadow(color: Color(0x290C0B0A), blurRadius: 48, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> dark1 = [
    BoxShadow(color: Color(0x660C0B0A), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> dark2 = [
    BoxShadow(color: Color(0x730C0B0A), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> dark3 = [
    BoxShadow(color: Color(0x8C0C0B0A), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> dark4 = [
    BoxShadow(color: Color(0x990C0B0A), blurRadius: 56, offset: Offset(0, 24)),
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
/// A diferenciação entre módulos vem da paleta oficial: laranja
/// (#FF6A2A) para produtos/vendas, preto (#0C0B0A) para neutros,
/// cinza de superfície (#F0F0F0) e branco suave (#F9F9F9) para contraste.
abstract final class ModuleColors {
  /// Produtos — laranja oficial (destaque de módulo).
  static const Color products = Color(0xFFFF6A2A);

  /// Clientes — preto oficial.
  static const Color customers = Color(0xFF0C0B0A);

  /// Crédito/Fiado — laranja oficial (atenção).
  static const Color credit = Color(0xFFFF6A2A);

  /// Compras — cinza de superfície.
  static const Color purchases = Color(0xFFF0F0F0);

  /// Relatórios — preto oficial.
  static const Color reports = Color(0xFF0C0B0A);

  /// Lojas — cinza de superfície.
  static const Color stores = Color(0xFFF0F0F0);

  /// Produção — laranja oficial.
  static const Color production = Color(0xFFFF6A2A);
}

/// Ícones com fundo SOLID oficial — paleta nova (nunca HSL derivado).
///
/// **Regra (auditoria de ícones):** nenhum ícone pode usar cores fora da
/// paleta oficial como fundo. `darkBackground`/`lightForeground` com HSL
/// criavam tons roxos/azuis na UI. Agora ambos devolvem o par
/// oficial (laranja/preto/suave) sem mistura — sem HSL, sem tint.
abstract final class IconTone {
  /// Fundo do ícone: laranja oficial em módulo de destaque, preto em
  /// neutro — resolve por identidade do chamador (tokens por cor).
  static Color darkBackground(Color color) {
    // Gelo oficial sobre o fundo escuro — contraste 17.6:1.
    return const Color(0xFF0C0B0A);
  }

  /// Foreground do ícone: gelo oficial sobre fundo escuro.
  static Color lightForeground(Color color) {
    return const Color(0xFFF9F9F9);
  }

  /// Laranja oficial — fundo padrão de ícones de destaque (U-24).
  static const Color accentOrange = Color(0xFFFF6A2A);

  /// Laranja oficial (gradiente do botão Confirmar no POS).
  static const Color accentOrangeDark = Color(0xFFFF6A2A);

  /// Cinza de superfície para ícones secundários.
  static const Color slate = Color(0xFFF0F0F0);

  /// Preto oficial para fundos de ícones.
  static const Color slateDark = Color(0xFF0C0B0A);

  /// Erro semântico oficial (#C62828 — só em alertas de erro).
  static const Color errorNeutral = Color(0xFFC62828);
  static const Color errorNeutralDark = Color(0xFFC62828);

  /// Atenção na interface — laranja da marca (#FF6A2A), não um amarelo
  /// fora do anexo. Erro continua #C62828.
  static const Color amber = Color(0xFFFF6A2A);
  static const Color amberDark = Color(0xFFFF6A2A);

  /// Textos em modo claro/escuro sobre ícones (paleta oficial).
  static const Color onBackgroundLight = Color(0xFF0C0B0A);
  static const Color onBackgroundDark = Color(0xFFF9F9F9);
}

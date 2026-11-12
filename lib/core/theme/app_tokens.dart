import 'package:flutter/material.dart';

import 'app_colors.dart';

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

  /// Anel de foco visível (2 px) — padrão de teclado/leitor.
  static const double focusRingWidth = 2;
}

/// Breakpoints responsivos do ERP (largura lógica em dp).
///
/// A hierarquia **muda** em cada faixa — não é apenas redimensionar:
/// compacto = uma coluna + FAB; médio = mais densidade e sheet largo;
/// expandido = rail/sidebar persistente e conteúdo centrado.
abstract final class AppBreakpoints {
  /// Limite superior do telemóvel (0–599).
  static const double compactMax = 599;

  /// Início do tablet (600–1023).
  static const double mediumMin = 600;

  /// Início do desktop (≥1024).
  static const double expandedMin = 1024;

  /// Corte específico do painel admin: sidebar minimalista (≥880).
  static const double sidebarRail = 880;
}

/// Opacidades dos véus de estado (Material state layers).
///
/// Valores únicos para hover/pressed/focus/disabled; cada componente
/// compõe com `color.withValues(alpha: …)` — nunca inventa alfas.
abstract final class AppStateOpacity {
  static const double hover = 0.04;
  static const double pressed = 0.08;
  static const double focus = 0.12;
  static const double disabled = 0.38;
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

/// Elevação — sombras discretas baseadas em Preto 100 (#0A0E15), nunca
/// coloridas. No escuro a elevação é sobretudo contorno; as sombras são
/// mais fortes para separar superfícies Preto 90/80. Os valores centrais
/// ficam aqui para que cartões, sheets, diálogos e menus partilhem a mesma
/// física.
abstract final class AppElevation {
  static const double e0 = 0;
  static const double e1 = 1;
  static const double e2 = 4;
  static const double e3 = 12;
  static const double e4 = 24;

  static const List<BoxShadow> light1 = [
    BoxShadow(color: Color(0x0F0A0E15), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> light2 = [
    BoxShadow(color: Color(0x140A0E15), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> light3 = [
    BoxShadow(color: Color(0x1F0A0E15), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> light4 = [
    BoxShadow(color: Color(0x290A0E15), blurRadius: 48, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> dark1 = [
    BoxShadow(color: Color(0x660A0E15), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> dark2 = [
    BoxShadow(color: Color(0x730A0E15), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> dark3 = [
    BoxShadow(color: Color(0x8C0A0E15), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> dark4 = [
    BoxShadow(color: Color(0x990A0E15), blurRadius: 56, offset: Offset(0, 24)),
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
/// Monocromático por decisão de marca: a diferenciação entre módulos vem
/// da escala neutra (tinta e cinzas). O acento tinta não é usado como
/// decoração de módulo — fica para CTA, foco e selecção.
abstract final class ModuleColors {
  /// Produtos — tinta.
  static const Color products = AppColors.black100;

  /// Clientes — tinta.
  static const Color customers = AppColors.black100;

  /// Crédito/Fiado — Preto 70 (o cinza médio sinaliza "atenção").
  static const Color credit = AppColors.black70;

  /// Compras — tinta.
  static const Color purchases = AppColors.black100;

  /// Relatórios — tinta.
  static const Color reports = AppColors.black100;

  /// Lojas — tinta.
  static const Color stores = AppColors.black100;

  /// Produção — tinta.
  static const Color production = AppColors.black100;
}

/// Ícones com fundo SÓLIDO oficial — escala neutra (nunca HSL derivado).
///
/// **Regra (auditoria de ícones):** nenhum ícone usa cor fora da paleta
/// como fundo. Os círculos usam a tinta (Preto 100) com glifo Branco 100
/// — 19:1 nos dois temas; o acento fica reservado a CTA, foco e selecção.
abstract final class IconTone {
  /// Fundo do ícone — tinta (neutro) nos dois temas.
  static Color darkBackground(Color color) {
    return AppColors.black100;
  }

  /// Foreground do ícone: Branco 100 sobre tinta (19:1).
  static Color lightForeground(Color color) {
    return AppColors.white100;
  }

  /// Tinta — fundo de ícones de destaque (uso pontual, não decorativo).
  static const Color accentBlue = AppColors.accentBlue;

  /// Tinta no escuro (Branco 100) para ícones de destaque.
  static const Color accentBlueDark = AppColors.accentBlueDark;

  /// Branco 90 para ícones secundários.
  static const Color slate = AppColors.white90;

  /// Tinta para fundos de ícones.
  static const Color slateDark = AppColors.black100;

  /// Erro semântico, com ícone e rótulo para além da cor.
  static const Color errorNeutral = AppColors.alertError;
  static const Color errorNeutralDark = AppColors.darkErrorNeutral;

  /// Acento de atenção — tinta. Estados também têm ícone e rótulo para não
  /// depender apenas da cor; não existe laranja.
  static const Color blue = AppColors.accentBlue;
  static const Color blueDark = AppColors.accentBlueDark;

  /// Textos em modo claro/escuro sobre ícones (escala oficial).
  static const Color onBackgroundLight = AppColors.black100;
  static const Color onBackgroundDark = AppColors.white100;
}

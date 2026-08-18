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

import 'package:flutter/material.dart';

/// Tipografia **Thin** do painel do super admin.
///
/// Envolve qualquer subtree (tela inteira, sheet, lista) num [Theme]
/// derivado cuja escala tipográfica usa pesos LEVES (300/400 em vez de
/// 600/500) — o mesmo padrão "ultra-clean" do resto do app, um passo
/// mais etéreo para as telas administrativas densas:
///
/// * Títulos/headers: `w300` (antes `w600`) — a hierarquia vem do
///   TAMANHO e da cor, não do peso da fonte;
/// * Labels/rótulos de ação: `w400` (antes `w600`);
/// * Corpo: permanece `w400` (legibilidade);
/// * Números tabulares preservados (KPIs/preços alinham dígito a dígito).
///
/// Uso: `AdminThin(child: AdminDashboardScreen(...))` no shell — todas as
/// telas internas (AppBar, inputs, dropdowns, chips, botões de texto)
/// herdam automaticamente; nenhum widget precisa mudar.
class AdminThin extends StatelessWidget {
  const AdminThin({super.key, required this.child});

  final Widget child;

  /// Deriva o [TextTheme] com pesos leves a partir do tema atual.
  static TextTheme thinTextTheme(TextTheme base) {
    TextStyle fn(TextStyle? style, {FontWeight? weight, double? size}) {
      if (style == null) return const TextStyle();
      return style.copyWith(
        fontWeight: weight ?? FontWeight.w400,
        fontSize: size ?? style.fontSize,
      );
    }

    return base.copyWith(
      // Títulos — leve, tracking suave; hierarquia por tamanho/cor.
      titleLarge: fn(base.titleLarge, weight: FontWeight.w300),
      titleMedium: fn(base.titleMedium, weight: FontWeight.w300),
      titleSmall: fn(base.titleSmall, weight: FontWeight.w400),
      // Ações/rótulos — sem o peso pesado do M3.
      labelLarge: fn(base.labelLarge, weight: FontWeight.w400),
      labelMedium: fn(base.labelMedium, weight: FontWeight.w400),
      // Corpo e captions mantêm o peso (400/500) — densidade legível.
      bodyMedium: fn(base.bodyMedium),
      bodySmall: fn(base.bodySmall),
      labelSmall: fn(base.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thin = theme.copyWith(
      textTheme: thinTextTheme(theme.textTheme),
      // AppBar do painel: título fino (o shell desenha o próprio; este
      // cobre as telas internas — dashboard, tenants, plans...).
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.2,
        ),
        toolbarHeight: 52,
      ),
      // Inputs/dropdowns: texto digitado e rótulos leves.
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      // Menus/dropdowns herdam o popupMenuTheme global — apenas o estilo
      // de texto fica explícito aqui para o peso 400 já aplicado.
      chipTheme: theme.chipTheme.copyWith(
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurface,
        ),
      ),
      snackBarTheme: theme.snackBarTheme.copyWith(
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: theme.snackBarTheme.contentTextStyle?.color,
        ),
      ),
    );

    return Theme(data: thin, child: child);
  }
}

/// Rótulo de secção do painel — versão thin do `_SectionLabel` comum.
/// Uppercase leve com tracking largo: hierarquia sem peso.
class AdminSectionLabel extends StatelessWidget {
  const AdminSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
    );
  }
}

/// Célula de KPI thin — valor em headline leve, rótulo em caption.
/// (Usado pelo dashboard; tabularFigures preservado.)
class AdminStatValue extends StatelessWidget {
  const AdminStatValue({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.4,
            color: color ?? scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

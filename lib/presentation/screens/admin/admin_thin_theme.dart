import 'package:flutter/material.dart';

/// Tipografia **Thin** do painel do super admin.
///
/// Envolve qualquer subtree (tela inteira, sheet, lista) num [Theme]
/// derivado cuja escala tipográfica usa pesos LEVES (300/400 em vez de
/// 600/500) — o mesmo padrão "ultra-clean" do resto do app, um passo
/// mais etéreo para as telas administrativas densas:
///
/// * Títulos/headers: `w400` (antes `w600`) — a hierarquia vem do
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
      // Títulos — leve mas dentro da escala: w400 (nunca w300, U-10).
      titleLarge: fn(base.titleLarge, weight: FontWeight.w400),
      titleMedium: fn(base.titleMedium, weight: FontWeight.w400),
      titleSmall: fn(base.titleSmall, weight: FontWeight.w400),
      // Ações/rótulos — sem o peso pesado do M3.
      labelLarge: fn(base.labelLarge, weight: FontWeight.w400),
      labelMedium: fn(base.labelMedium, weight: FontWeight.w400),
      // Corpo e captions mantêm o peso (400/500) — densidade legível.
      // labelSmall preserva o peso ESTRUTURAL do base (w500): o default
      // w400 do fn() rebaixaria o caption silenciosamente, contradizendo
      // este contrato.
      bodyMedium: fn(base.bodyMedium),
      bodySmall: fn(base.bodySmall),
      labelSmall: fn(base.labelSmall, weight: base.labelSmall?.fontWeight),
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
        // Mantém identidade tipográfica do painel, sem criar tamanho/peso
        // paralelo: usa titleLarge do tema (U-10).
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
          color: theme.colorScheme.onSurface,
        ),
        toolbarHeight: 52,
      ),
      // Inputs/dropdowns: texto digitado e rótulos leves (U-10: sem
      // tamanhos 13 paralelos — herda labelMedium/bodyMedium do tema).
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      // Menus/dropdowns herdam o popupMenuTheme global — apenas o estilo
      // de texto fica explícito aqui para o peso 400 já aplicado.
      chipTheme: theme.chipTheme.copyWith(
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      snackBarTheme: theme.snackBarTheme.copyWith(
        contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
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
            fontWeight: FontWeight.w400,
            letterSpacing: -0.4,
            color: color ?? scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
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

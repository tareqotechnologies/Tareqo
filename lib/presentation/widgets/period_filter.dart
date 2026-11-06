import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';
import 'filter_dropdown.dart';

/// Filtro de período (Tudo/Hoje/Ontem/Esta semana) — compartilhado entre as
/// telas de Vendas e Compras.
///
/// Puramente de apresentação: a lista completa vem do provider e o filtro é
/// uma projeção client-side — nenhuma regra de negócio é alterada.
enum PeriodFilter {
  all,
  today,
  yesterday,
  week;

  String label(AppLocalizations l10n) => switch (this) {
    PeriodFilter.all => l10n.periodAll,
    PeriodFilter.today => l10n.periodToday,
    PeriodFilter.yesterday => l10n.periodYesterday,
    PeriodFilter.week => l10n.periodWeek,
  };

  /// Verifica se a [date] cai no período selecionado (dias corridos no fuso
  /// do dispositivo, como o resto da UI).
  ///
  /// A comparação é feita em DIAS DE CALENDÁRIO normalizados em UTC: somar ou
  /// subtrair `Duration(days:)` a uma meia-noite local erra nos dias de
  /// mudança de hora (23h/25h no fuso) — "ontem" deixava de casar com a
  /// venda de ontem. Em UTC o dia tem sempre 24h e o resultado é o mesmo em
  /// qualquer fuso.
  bool matches(DateTime date) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final that = DateTime.utc(date.year, date.month, date.day);
    return switch (this) {
      PeriodFilter.all => true,
      PeriodFilter.today => that == today,
      PeriodFilter.yesterday => that ==
          DateTime.utc(today.year, today.month, today.day - 1),
      PeriodFilter.week => !that.isBefore(
        DateTime.utc(today.year, today.month, today.day - 6),
      ),
    };
  }
}

/// Seletor de período MINIMALISTA (canvas V3) — um único chip compacto com
/// o período ativo + chevron ("Hoje ▾"); tocar abre o menu de opções. O
/// chip acende (primaryContainer) quando um período não-default está ativo.
class PeriodFilterBar extends StatelessWidget {
  const PeriodFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PeriodFilter value;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FilterDropdown<PeriodFilter>(
      icon: Icons.calendar_today_rounded,
      options: PeriodFilter.values,
      selected: value,
      labelOf: (filter) => filter.label(l10n),
      onChanged: onChanged,
    );
  }
}

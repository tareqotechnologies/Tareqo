import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../l10n/generated/app_localizations.dart';

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
  bool matches(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    return switch (this) {
      PeriodFilter.all => true,
      PeriodFilter.today => that == today,
      PeriodFilter.yesterday => that == today.subtract(const Duration(days: 1)),
      PeriodFilter.week =>
        !that.isBefore(today.subtract(const Duration(days: 6))),
    };
  }
}

/// Chips de período (Material 3) — `Wrap` para quebrar linha em telas
/// estreitas / escala de texto alta, sem overflow.
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in PeriodFilter.values)
          ChoiceChip(
            showCheckmark: false,
            label: Text(filter.label(l10n)),
            selected: value == filter,
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

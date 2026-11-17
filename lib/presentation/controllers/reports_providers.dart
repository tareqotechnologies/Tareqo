import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/share/report_exporter.dart';
import '../../core/utils/period_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/usecases/get_sales_report_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Período de análise do relatório de vendas (mesmos rótulos do Financeiro).
enum ReportPeriod { today, week, month, all }

extension ReportPeriodLabel on ReportPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    ReportPeriod.today => l10n.periodToday,
    ReportPeriod.week => l10n.periodWeek,
    ReportPeriod.month => l10n.periodMonth,
    ReportPeriod.all => l10n.periodAll,
  };
}

/// Período selecionado na tela de Relatórios.
final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
      ReportPeriodNotifier.new,
    );

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.month;

  void select(ReportPeriod period) => state = period;
}

/// Ponte com o ServiceLocator (GetIt).
final getSalesReportUseCaseProvider = Provider<GetSalesReportUseCase>(
  (ref) => ServiceLocator.instance<GetSalesReportUseCase>(),
);

/// Exportador do relatório (CSV/PDF) — mesma porta de saída do
/// [ReceiptSharer] ([receiptSharerProvider]): provider simples, substituível
/// por um fake nos testes de widget.
final reportExporterProvider = Provider<ReportExporter>(
  (ref) => const ReportExporter(),
);

/// Estado do relatório de vendas — reconstrói automaticamente quando o
/// período muda.
final salesReportProvider =
    AsyncNotifierProvider<SalesReportNotifier, SalesReport>(
      SalesReportNotifier.new,
    );

/// Sales metrics for the matching interval immediately before the selected
/// reporting period. The all-time view has no comparison interval.
final previousSalesReportProvider = FutureProvider.autoDispose
    .family<SalesReport?, String>((ref, storeId) async {
      final period = ref.watch(reportPeriodProvider);
      if (period == ReportPeriod.all) return null;

      final now = DateTime.now();
      final previousRange = _previousReportRange(period, now);
      return ref
          .read(getSalesReportUseCaseProvider)
          .call(
            storeId: storeId,
            start: previousRange.$1,
            end: previousRange.$2,
          );
    });

class SalesReportNotifier extends AsyncNotifier<SalesReport> {
  @override
  Future<SalesReport> build() {
    final period = ref.watch(reportPeriodProvider);
    final now = DateTime.now();
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));

    final start = _currentReportStart(period, now);

    if (storeId == null) {
      return Future.value(
        const SalesReport(
          totalRevenueCents: 0,
          totalProfitCents: 0,
          bestSellers: [],
          perDay: [],
        ),
      );
    }

    return ref
        .read(getSalesReportUseCaseProvider)
        .call(storeId: storeId, start: start, end: now);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

DateTime _currentReportStart(ReportPeriod period, DateTime now) =>
    switch (period) {
      ReportPeriod.today => startOfDay(now),
      // Seven calendar days including today (rather than eight dates).
      ReportPeriod.week => startOfDay(now.subtract(const Duration(days: 6))),
      ReportPeriod.month => DateTime(now.year, now.month, 1),
      ReportPeriod.all => DateTime(2000),
    };

(DateTime, DateTime) _previousReportRange(ReportPeriod period, DateTime now) {
  switch (period) {
    case ReportPeriod.today:
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      return (
        yesterday,
        yesterday.add(
          Duration(
            hours: now.hour,
            minutes: now.minute,
            seconds: now.second,
            milliseconds: now.millisecond,
            microseconds: now.microsecond,
          ),
        ),
      );
    case ReportPeriod.week:
      final currentStart = _currentReportStart(ReportPeriod.week, now);
      return (
        currentStart.subtract(const Duration(days: 7)),
        now.subtract(const Duration(days: 7)),
      );
    case ReportPeriod.month:
      final previousStart = DateTime(now.year, now.month - 1, 1);
      final lastDay = DateTime(now.year, now.month, 0).day;
      final matchingDay = now.day < lastDay ? now.day : lastDay;
      return (
        previousStart,
        DateTime(
          previousStart.year,
          previousStart.month,
          matchingDay,
          now.hour,
          now.minute,
          now.second,
          now.millisecond,
          now.microsecond,
        ),
      );
    case ReportPeriod.all:
      throw StateError('All-time reports do not have a previous period.');
  }
}

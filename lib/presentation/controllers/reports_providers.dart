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

class SalesReportNotifier extends AsyncNotifier<SalesReport> {
 @override
 Future<SalesReport> build() {
 final period = ref.watch(reportPeriodProvider);
 final now = DateTime.now();
 final user = ref.watch(authStateProvider).value;
 final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));

 final start = switch (period) {
 ReportPeriod.today => startOfDay(now),
 ReportPeriod.week => startOfDay(now.subtract(const Duration(days: 7))),
 ReportPeriod.month => DateTime(now.year, now.month, 1),
 ReportPeriod.all => DateTime(2000),
 };

 if (storeId == null) {
 return Future.value(const SalesReport(
 totalRevenueCents: 0,
 totalProfitCents: 0,
 bestSellers: [],
 perDay: [],
 ));
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

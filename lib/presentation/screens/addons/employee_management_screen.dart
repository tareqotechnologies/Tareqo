import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/employee_management.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/store_employee.dart';
import '../../../domain/usecases/employee_commission_calculator.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/employee_management_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

/// Ecra de gestão de funcionários — ponto, comissões e metas.
///
/// Add-on `ao_employee_mgmt`: os três pilares agora são REAIS e
/// persistidos por loja:
///  - **Ponto** — entrada/saída por funcionário por dia (uma linha por
///    dia; sair atualiza a mesma linha);
///  - **Comissões** — calculadas das VENDAS REAIS da loja no mês
///    (`sales.user_id` = caixa) × taxa cadastrada; nunca armazenadas;
///  - **Metas** — meta mensal de vendas por funcionário, com progresso
///    real (vendas do mês ÷ meta).
///
/// O roster vem de `store_employees` (o MESMO módulo Lojas — contas,
/// lojas e cargos reais).
class EmployeeManagementScreen extends ConsumerStatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  ConsumerState<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState
    extends ConsumerState<EmployeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loja activa — escopo de todos os dados do add-on (como nas demais
  /// telas de dados do app).
  String? _activeStoreId() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    if (storeId != null) return storeId;
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    return stores.isEmpty ? null : stores.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final storeId = _activeStoreId();

    return AppPage(
      title: l10n.employeeMgmtTitle,
      // Título 3 (20/w600) — rótulo longo ('Gestão de Funcionários')
      // truncava em titleLarge (22) no AppBar de 56px.
      titleStyle: theme.textTheme.titleMedium,
      useSafeArea: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            tabs: [
              Tab(text: l10n.employeeMgmtTabAttendance),
              Tab(text: l10n.employeeMgmtTabCommissions),
              Tab(text: l10n.employeeMgmtTabTargets),
            ],
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AttendanceTab(storeId: storeId),
                _CommissionsTab(storeId: storeId),
                _TargetsTab(storeId: storeId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolve o rótulo localizado de um papel de funcionário.
String _roleLabel(EmployeeRole role, AppLocalizations l10n) {
  return role == EmployeeRole.manager
      ? l10n.roleManager
      : l10n.employeeRoleSales;
}

// ═══════════════════════════════════════════════════════════════════════
// Ponto (Attendance)
// ═══════════════════════════════════════════════════════════════════════

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.storeId});

  /// Loja activa (null = sem loja/onboarding incompleto → vazio honesto).
  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;

    // Roster REAL da loja (store_employees — o mesmo módulo Lojas).
    final employees = tenant == null
        ? const <StoreEmployee>[]
        : (ref.watch(employeesProvider(tenant.id)).value ??
              const <StoreEmployee>[]);
    final storeEmployees = employees
        .where((e) => e.storeId == storeId)
        .where((e) => e.isActive)
        .toList();

    final now = DateTime.now();
    final workDate = _workDate(now);
    final attendanceAsync = storeId == null
        ? null
        : ref.watch(attendanceProvider(workDate));
    final records = attendanceAsync?.value ?? const <EmployeeAttendance>[];
    final openByUser = {
      for (final record in records)
        if (record.clockOut == null) record.userId: record,
    };

    if (storeId == null) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: l10n.employeeMgmtNoStoreTitle,
        subtitle: l10n.employeeMgmtNoStoreAttendance,
      );
    }
    if (attendanceAsync?.hasError ?? false) {
      return ErrorView(
        message: l10n.employeeMgmtLoadError,
        onRetry: () => ref.invalidate(attendanceProvider(workDate)),
      );
    }
    if (storeEmployees.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: l10n.employeesEmptyTitle,
        subtitle: l10n.employeeAttendanceEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo do dia ───
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: l10n.employeePresentCount,
                value: '${openByUser.length}',
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: l10n.employeeAbsentCount,
                value: '${storeEmployees.length - openByUser.length}',
                color: IconTone.red,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: l10n.commonTotal,
                value: '${storeEmployees.length}',
                color: ModuleColors.reports,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Botões de ponto rápido ───
        Text(
          l10n.employeeAttendanceSection,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...storeEmployees.map((employee) {
          final record = openByUser[employee.userId];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              elevated: true,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: record != null
                          ? IconTone.darkBackground(IconTone.green)
                          : scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      record != null
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      size: 16,
                      color: record != null
                          ? IconTone.lightForeground(IconTone.green)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _roleLabel(employee.role, context.l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (record != null)
                    AppButton.secondary(
                      label: l10n.employeeClockOutAction,
                      onPressed: () =>
                          _clockOut(context, ref, employee, workDate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IconTone.red,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        minimumSize: const Size(0, 32),
                      ),
                    )
                  else
                    AppButton.primary(
                      label: l10n.employeeClockInAction,
                      onPressed: () =>
                          _clockIn(context, ref, employee, workDate),
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: AppSpacing.lg),

        // ─── Registos de hoje ───
        if (records.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l10n.employeeRecordsSection,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${records.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                elevated: false,
                borderRadius: AppRadius.mdAll,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: record.clockOut == null
                            ? IconTone.green
                            : IconTone.red,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _employeeName(storeEmployees, record.userId) ??
                            record.userId,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_time(record.clockIn)} — '
                      '${record.clockOut == null ? l10n.employeeClockOutInProgress : _time(record.clockOut!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _time(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';

  String? _employeeName(List<StoreEmployee> employees, String userId) =>
      employees.where((e) => e.userId == userId).firstOrNull?.fullName;

  Future<void> _clockIn(
    BuildContext context,
    WidgetRef ref,
    StoreEmployee employee,
    String workDate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(employeeManagementRepositoryProvider)
          .clockIn(
            storeId: employee.storeId,
            userId: employee.userId,
            workDate: workDate,
            clockIn: DateTime.now(),
          );
      ref.invalidate(attendanceProvider(workDate));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.employeeClockInError)),
      );
    }
  }

  Future<void> _clockOut(
    BuildContext context,
    WidgetRef ref,
    StoreEmployee employee,
    String workDate,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(employeeManagementRepositoryProvider)
          .clockOut(
            storeId: employee.storeId,
            userId: employee.userId,
            workDate: workDate,
            clockOut: DateTime.now(),
          );
      ref.invalidate(attendanceProvider(workDate));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.employeeClockOutError)),
      );
    }
  }

  static String _workDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════════════════
// Comissões
// ═══════════════════════════════════════════════════════════════════════

class _CommissionsTab extends ConsumerWidget {
  const _CommissionsTab({required this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final employees = tenant == null
        ? const <StoreEmployee>[]
        : (ref.watch(employeesProvider(tenant.id)).value ??
              const <StoreEmployee>[]);
    final storeEmployees = employees
        .where((e) => e.storeId == storeId)
        .where((e) => e.isActive)
        .toList();

    final month = employeeMonthOf(DateTime.now());
    final summaryAsync = storeId == null
        ? null
        : ref.watch(commissionSummaryProvider(month));

    if (storeId == null) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: l10n.employeeMgmtNoStoreTitle,
        subtitle: l10n.employeeMgmtNoStoreCommissions,
      );
    }
    if (summaryAsync?.hasError ?? false) {
      return ErrorView(
        message: l10n.employeeMgmtLoadError,
        onRetry: () => ref.invalidate(commissionSummaryProvider(month)),
      );
    }
    if (storeEmployees.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: l10n.employeesEmptyTitle,
        subtitle: l10n.employeeAttendanceEmpty,
      );
    }

    final entries =
        summaryAsync?.value ?? const <EmployeeCommissionSummaryEntry>[];
    final totalSales = entries.fold<int>(0, (sum, e) => sum + e.salesCents);
    final totalCommission = entries.fold<int>(
      0,
      (sum, e) => sum + e.commissionCents,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo do mês ───
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.employeeSalesMonth,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(totalSales),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.employeeCommissionTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(totalCommission),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: IconTone.green,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Lista por funcionário ───
        Text(
          l10n.employeeCommissionPerEmployee,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final employee in storeEmployees) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              elevated: true,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: IconTone.darkBackground(ModuleColors.reports),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outlined,
                      size: 16,
                      color: IconTone.lightForeground(ModuleColors.reports),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _commissionSubtitle(entries, employee, l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openRateSheet(context, ref, employee),
                    child: Text(l10n.employeeCommissionSetRate),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _commissionSubtitle(
    List<EmployeeCommissionSummaryEntry> entries,
    StoreEmployee employee,
    AppLocalizations l10n,
  ) {
    final entry = entries.where((e) => e.userId == employee.userId).firstOrNull;
    if (entry == null) {
      return l10n.employeeCommissionNoRate;
    }
    if (entry.rateBps == 0) {
      return '${l10n.employeeCommissionNoRate} · '
          '${Formatters.currency(entry.salesCents)} vendas';
    }
    return l10n.employeeCommissionRate(
      entry.rateBps ~/ 100,
      Formatters.currency(entry.salesCents),
    );
  }

  Future<void> _openRateSheet(
    BuildContext context,
    WidgetRef ref,
    StoreEmployee employee,
  ) async {
    final l10n = context.l10n;
    final rates = await ref.read(commissionRatesProvider.future);
    if (!context.mounted) return;
    final existing = rates
        .where((rate) => rate.userId == employee.userId)
        .firstOrNull;
    final controller = TextEditingController(
      text: existing == null ? '' : '${existing.rateBps ~/ 100}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.employeeCommissionSetRate,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              employee.fullName,
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller,
              label: l10n.employeeCommissionRateLabel,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: l10n.commonConfirm,
              onPressed: () async {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < 0 || value > 100) {
                  return;
                }
                try {
                  await ref
                      .read(employeeManagementRepositoryProvider)
                      .setCommissionRate(
                        storeId: employee.storeId,
                        userId: employee.userId,
                        rateBps: value * 100,
                      );
                  ref.invalidate(commissionRatesProvider);
                  ref.invalidate(
                    commissionSummaryProvider(employeeMonthOf(DateTime.now())),
                  );
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(l10n.employeeCommissionRateSaved)),
                    );
                  }
                } catch (_) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(l10n.employeeCommissionRateError)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Metas (Targets)
// ═══════════════════════════════════════════════════════════════════════

class _TargetsTab extends ConsumerWidget {
  const _TargetsTab({required this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final employees = tenant == null
        ? const <StoreEmployee>[]
        : (ref.watch(employeesProvider(tenant.id)).value ??
              const <StoreEmployee>[]);
    final storeEmployees = employees
        .where((e) => e.storeId == storeId)
        .where((e) => e.isActive)
        .toList();

    final month = employeeMonthOf(DateTime.now());
    final targetsAsync = storeId == null ? null : ref.watch(targetsProvider);
    final summaryAsync = storeId == null
        ? null
        : ref.watch(commissionSummaryProvider(month));
    final targets = targetsAsync?.value ?? const <EmployeeTarget>[];
    final monthTargets = targets.where((t) => t.month == month).toList();
    final entries =
        summaryAsync?.value ?? const <EmployeeCommissionSummaryEntry>[];

    if (storeId == null) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: l10n.employeeMgmtNoStoreTitle,
        subtitle: l10n.employeeMgmtNoStoreTargets,
      );
    }
    if (targetsAsync?.hasError ?? false) {
      return ErrorView(
        message: l10n.employeeMgmtLoadError,
        onRetry: () => ref.invalidate(targetsProvider),
      );
    }
    if (storeEmployees.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: l10n.employeesEmptyTitle,
        subtitle: l10n.employeeAttendanceEmpty,
      );
    }

    final reached = monthTargets
        .where((target) => _progress(target, entries) >= 1.0)
        .length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo ───
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: l10n.employeeTargetsActive,
                value: '${monthTargets.length}',
                color: ModuleColors.credit,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: l10n.employeeTargetsReached,
                value: '$reached',
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: l10n.employeeTargetsPending,
                value: '${monthTargets.length - reached}',
                color: IconTone.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Lista de metas ───
        if (monthTargets.isEmpty)
          EmptyState(
            icon: Icons.flag_outlined,
            title: l10n.employeeTargetsEmptyTitle,
            subtitle: l10n.employeeTargetsEmptySubtitle,
          )
        else ...[
          Row(
            children: [
              Text(
                l10n.employeeTargetsMonth,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  month,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final target in monthTargets) ...[
            _TargetCard(
              target: target,
              employeeName:
                  storeEmployees
                      .where((e) => e.userId == target.userId)
                      .firstOrNull
                      ?.fullName ??
                  target.userId,
              progress: _progress(target, entries),
              onRemove: () => _removeTarget(context, ref, target),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(
          label: l10n.employeeTargetAdd,
          onPressed: () => _openAddTarget(context, ref, storeEmployees),
        ),
      ],
    );
  }

  double _progress(
    EmployeeTarget target,
    List<EmployeeCommissionSummaryEntry> entries,
  ) {
    final achieved = entries
        .where((e) => e.userId == target.userId)
        .fold<int>(0, (sum, e) => sum + e.salesCents);
    return target.targetCents > 0
        ? (achieved / target.targetCents).clamp(0.0, 1.0)
        : 0.0;
  }

  Future<void> _removeTarget(
    BuildContext context,
    WidgetRef ref,
    EmployeeTarget target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(employeeManagementRepositoryProvider)
          .removeTarget(target.id, storeId: target.storeId);
      ref.invalidate(targetsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.employeeTargetRemoved)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.employeeTargetError)));
    }
  }

  Future<void> _openAddTarget(
    BuildContext context,
    WidgetRef ref,
    List<StoreEmployee> employees,
  ) async {
    final l10n = context.l10n;
    final month = employeeMonthOf(DateTime.now());
    final targets =
        (ref.read(targetsProvider).value ?? const <EmployeeTarget>[]);
    final existingUserIds = {
      for (final target in targets)
        if (target.month == month) target.userId,
    };
    final available = employees
        .where((e) => !existingUserIds.contains(e.userId))
        .toList();

    if (available.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.employeeTargetAllHave)),
      );
      return;
    }

    String? selectedUserId = available.first.userId;
    final amountController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.employeeTargetNewTitle,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppPickerField<String>(
              value: selectedUserId,
              label: l10n.employeeTargetEmployee,
              items: [
                for (final employee in available)
                  DropdownMenuItem(
                    value: employee.userId,
                    child: Text(employee.fullName),
                  ),
              ],
              onChanged: (value) => selectedUserId = value,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: amountController,
              label: l10n.employeeTargetMonthly,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: l10n.employeeTargetSave,
              onPressed: () async {
                final cents = _parseCents(amountController.text.trim());
                final userId = selectedUserId;
                if (cents == null || cents < 0 || userId == null) return;
                try {
                  await ref
                      .read(employeeManagementRepositoryProvider)
                      .setTarget(
                        storeId: available.first.storeId,
                        userId: userId,
                        month: month,
                        targetCents: cents,
                      );
                  ref.invalidate(targetsProvider);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.employeeTargetSaved)),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.employeeTargetError)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
  }

  /// Converte "15000" ou "15000,00" em centavos (int).
  int? _parseCents(String raw) {
    final cleaned = raw.replaceAll(' ', '').replaceAll(',', '.');
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }
}

/// Card de meta mensal com progresso real (vendas do mês ÷ meta).
class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.target,
    required this.employeeName,
    required this.progress,
    required this.onRemove,
  });

  final EmployeeTarget target;
  final String employeeName;
  final double progress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final reached = progress >= 1.0;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  employeeName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: scheme.onSurfaceVariant,
                tooltip: l10n.commonDelete,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.employeeTargetMeta(Formatters.currency(target.targetCents)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: reached ? IconTone.green : scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.employeeTargetProgress((progress * 100).round()),
            style: theme.textTheme.labelSmall?.copyWith(
              color: reached ? IconTone.green : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Componentes partilhados
// ═══════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      elevated: false,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Rótulo COMPLETO — quebra quando necessário (nada de truncar).
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

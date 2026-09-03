import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de gestão de funcionários — ponto, comissões e metas.
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

  // ─── Estado partilhado ───
  final List<_Employee> _employees = [
    _Employee(id: '1', name: 'Carlos Silva', role: 'Vendedor'),
    _Employee(id: '2', name: 'Ana Santos', role: 'Gerente'),
    _Employee(id: '3', name: 'Miguel Costa', role: 'Vendedor'),
  ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Gestão de Funcionários',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ponto'),
            Tab(text: 'Comissões'),
            Tab(text: 'Metas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AttendanceTab(employees: _employees),
          _CommissionsTab(employees: _employees),
          _TargetsTab(employees: _employees),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Modelos
// ═══════════════════════════════════════════════════════════════════════════════

class _Employee {
  _Employee({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;
}

class _AttendanceRecord {
  _AttendanceRecord({
    required this.employeeId,
    required this.employeeName,
    required this.clockIn,
    this.clockOut,
    required this.isPresent,
  });

  final String employeeId;
  final String employeeName;
  final String clockIn;
  final String? clockOut;
  final bool isPresent;
}

class _Target {
  _Target({
    required this.employeeId,
    required this.employeeName,
    required this.targetCents,
    required this.achievedCents,
    required this.month,
  });

  final String employeeId;
  final String employeeName;
  final int targetCents;
  final int achievedCents;
  final String month;

  double get progress =>
      targetCents > 0 ? (achievedCents / targetCents).clamp(0.0, 1.0) : 0.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ponto (Attendance)
// ═══════════════════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab({required this.employees});

  final List<_Employee> employees;

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final List<_AttendanceRecord> _records = [];
  final Set<String> _clockedIn = {};

  void _clockIn(String employeeId) {
    final emp = widget.employees.firstWhere((e) => e.id == employeeId);
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _clockedIn.add(employeeId);
      _records.insert(
        0,
        _AttendanceRecord(
          employeeId: employeeId,
          employeeName: emp.name,
          clockIn: timeStr,
          clockOut: null,
          isPresent: true,
        ),
      );
    });
  }

  void _clockOut(String employeeId) {
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _clockedIn.remove(employeeId);
      final idx = _records.indexWhere(
        (r) => r.employeeId == employeeId && r.clockOut == null,
      );
      if (idx >= 0) {
        final old = _records[idx];
        _records[idx] = _AttendanceRecord(
          employeeId: employeeId,
          employeeName: old.employeeName,
          clockIn: old.clockIn,
          clockOut: timeStr,
          isPresent: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo do dia ───
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Presentes',
                value: '${_clockedIn.length}',
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: 'Ausentes',
                value: '${widget.employees.length - _clockedIn.length}',
                color: IconTone.red,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: 'Total',
                value: '${widget.employees.length}',
                color: ModuleColors.reports,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Botões de ponto rápido ───
        Text(
          'Registo de Ponto',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...widget.employees.map((emp) {
          final isClocked = _clockedIn.contains(emp.id);
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
                      color: isClocked
                          ? IconTone.darkBackground(IconTone.green)
                          : scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isClocked
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      size: 16,
                      color: isClocked
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
                          emp.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          emp.role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClocked)
                    AppButton.secondary(
                      label: 'Sair',
                      onPressed: () => _clockOut(emp.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IconTone.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                      ),
                    )
                  else
                    AppButton.primary(
                      label: 'Entrar',
                      onPressed: () => _clockIn(emp.id),
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: AppSpacing.lg),

        // ─── Registos de hoje ───
        if (_records.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Registos de Hoje',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${_records.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._records.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                elevated: false,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                        color: r.isPresent
                            ? IconTone.green
                            : IconTone.red,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        r.employeeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${r.clockIn} — ${r.clockOut ?? "Em curso"}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// Comissões
// ═══════════════════════════════════════════════════════════════════════════════

class _CommissionsTab extends StatelessWidget {
  const _CommissionsTab({required this.employees});

  final List<_Employee> employees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Dados de exemplo (seriam calculados a partir de vendas reais)
    final totalSalesCents = 2450000; // 24.500,00 MT
    final commissionRate = 0.05; // 5%
    final totalCommissionCents = (totalSalesCents * commissionRate).toInt();

    final employeeData = [
      ('Carlos Silva', 1200000, 5), // 12.000,00 vendas, 5% comissão
      ('Ana Santos', 850000, 7), // 8.500,00 vendas, 7% (gerente)
      ('Miguel Costa', 400000, 5), // 4.000,00 vendas, 5%
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo do mês ───
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendas do Mês',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(totalSalesCents),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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
                      'Comissões',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(totalCommissionCents),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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
          'Comissão por Funcionário',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in employeeData) ...[
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
                          entry.$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.$3}% sobre ${Formatters.currency(entry.$2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(
                      (entry.$2 * entry.$3 / 100).toInt(),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: IconTone.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Metas (Targets)
// ═══════════════════════════════════════════════════════════════════════════════

class _TargetsTab extends StatefulWidget {
  const _TargetsTab({required this.employees});

  final List<_Employee> employees;

  @override
  State<_TargetsTab> createState() => _TargetsTabState();
}

class _TargetsTabState extends State<_TargetsTab> {
  final List<_Target> _targets = [
    _Target(
      employeeId: '1',
      employeeName: 'Carlos Silva',
      targetCents: 1500000, // 15.000,00 MT
      achievedCents: 1200000, // 12.000,00 MT
      month: 'Set 2026',
    ),
    _Target(
      employeeId: '2',
      employeeName: 'Ana Santos',
      targetCents: 1000000, // 10.000,00 MT
      achievedCents: 850000, // 8.500,00 MT
      month: 'Set 2026',
    ),
  ];

  void _openAddTarget() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddTargetSheet(
        employees: widget.employees,
        existingTargetEmployeeIds: _targets.map((t) => t.employeeId).toSet(),
        onSave: (target) {
          setState(() => _targets.add(target));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _removeTarget(int index) {
    setState(() => _targets.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ─── Resumo ───
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Metas Activas',
                value: '${_targets.length}',
                color: ModuleColors.credit,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: 'Atingidas',
                value:
                    '${_targets.where((t) => t.progress >= 1.0).length}',
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MiniStat(
                label: 'Pendentes',
                value:
                    '${_targets.where((t) => t.progress < 1.0).length}',
                color: IconTone.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ─── Lista de metas ───
        if (_targets.isEmpty)
          EmptyState(
            icon: Icons.flag_outlined,
            title: 'Nenhuma meta definida',
            subtitle:
                'Defina metas mensais de vendas para cada funcionário',
          )
        else ...[
          Row(
            children: [
              Text(
                'Metas do Mês',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Set 2026',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _targets.length; i++) ...[
            _TargetCard(
              target: _targets[i],
              onRemove: () => _removeTarget(i),
            ),
            if (i < _targets.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],

        const SizedBox(height: AppSpacing.lg),

        // ─── Botão adicionar ───
        if (widget.employees.isNotEmpty)
          AppButton.secondary(
            expanded: true,
            label: 'Adicionar Meta',
            icon: const Icon(Icons.add_outlined, size: 18),
            onPressed: _openAddTarget,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Componentes
// ═══════════════════════════════════════════════════════════════════════════════

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
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target, required this.onRemove});

  final _Target target;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reached = target.progress >= 1.0;
    final progressColor = reached ? IconTone.green : ModuleColors.credit;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IconTone.darkBackground(progressColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reached
                      ? Icons.check_circle_outline
                      : Icons.flag_outlined,
                  size: 14,
                  color: IconTone.lightForeground(progressColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  target.employeeName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Barra de progresso
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: target.progress,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(target.progress * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: progressColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meta: ${Formatters.currency(target.targetCents)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                'Realizado: ${Formatters.currency(target.achievedCents)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sheet: Adicionar Meta
// ═══════════════════════════════════════════════════════════════════════════════

class _AddTargetSheet extends StatefulWidget {
  const _AddTargetSheet({
    required this.employees,
    required this.existingTargetEmployeeIds,
    required this.onSave,
  });

  final List<_Employee> employees;
  final Set<String> existingTargetEmployeeIds;
  final ValueChanged<_Target> onSave;

  @override
  State<_AddTargetSheet> createState() => _AddTargetSheetState();
}

class _AddTargetSheetState extends State<_AddTargetSheet> {
  String? _selectedEmployeeId;
  final _targetController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = widget.employees
        .where((e) => !widget.existingTargetEmployeeIds.contains(e.id))
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nova Meta',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (available.isEmpty)
              Text(
                'Todos os funcionários já possuem meta definida',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                'Funcionário',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final emp in available)
                    ChoiceChip(
                      label: Text(emp.name),
                      selected: _selectedEmployeeId == emp.id,
                      onSelected: (_) =>
                          setState(() => _selectedEmployeeId = emp.id),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _targetController,
                label: 'Meta Mensal (MT)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.flag_outlined,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: 'Guardar Meta',
              onPressed: _selectedEmployeeId != null &&
                      _targetController.text.isNotEmpty
                  ? () {
                      final target =
                          double.tryParse(_targetController.text) ?? 0;
                      final emp = widget.employees.firstWhere(
                        (e) => e.id == _selectedEmployeeId,
                      );
                      widget.onSave(_Target(
                        employeeId: emp.id,
                        employeeName: emp.name,
                        targetCents: (target * 100).toInt(),
                        achievedCents: 0,
                        month: 'Set 2026',
                      ));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

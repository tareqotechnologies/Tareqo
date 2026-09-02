import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_button.dart';

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
        children: const [
          _AttendanceTab(),
          _CommissionsTab(),
          _TargetsTab(),
        ],
      ),
    );
  }
}

// ─── Ponto ──────────────────────────────────────────────────────────────

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final List<_AttendanceRecord> _records = [
    _AttendanceRecord(
      employeeName: 'Funcionário 1',
      clockIn: '08:00',
      clockOut: '17:00',
      totalHours: '9h 00min',
      isPresent: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Botões de ponto rápido
        Row(
          children: [
            Expanded(
              child: _ClockButton(
                icon: Icons.login_rounded,
                label: 'Entrada',
                color: const Color(0xFF16A34A),
                onPressed: () {
                  setState(() {
                    _records.insert(
                      0,
                      _AttendanceRecord(
                        employeeName: 'Você',
                        clockIn: TimeOfDay.now().format(context),
                        clockOut: '—',
                        totalHours: 'Em curso...',
                        isPresent: true,
                      ),
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ClockButton(
                icon: Icons.logout_rounded,
                label: 'Saída',
                color: scheme.error,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Registos de Hoje',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Material(
              color: scheme.surfaceContainerLow,
              borderRadius: AppRadius.lgAll,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: record.isPresent
                            ? const Color(0xFF16A34A)
                            : scheme.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.employeeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Entrada: ${record.clockIn}  •  Saída: ${record.clockOut}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      record.totalHours,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttendanceRecord {
  _AttendanceRecord({
    required this.employeeName,
    required this.clockIn,
    required this.clockOut,
    required this.totalHours,
    required this.isPresent,
  });

  final String employeeName;
  final String clockIn;
  final String clockOut;
  final String totalHours;
  final bool isPresent;
}

class _ClockButton extends StatelessWidget {
  const _ClockButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Comissões ──────────────────────────────────────────────────────────

class _CommissionsTab extends StatelessWidget {
  const _CommissionsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Resumo
        Material(
          color: scheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comissão do Mês',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '0,00 MT',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Vendas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '0,00 MT',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  size: 40,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sem comissões registadas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Metas ──────────────────────────────────────────────────────────────

class _TargetsTab extends StatelessWidget {
  const _TargetsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 40,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nenhuma meta definida',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Defina metas mensais de vendas\npara cada funcionário',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'Criar Meta',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

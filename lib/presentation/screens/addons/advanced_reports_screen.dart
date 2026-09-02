import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/advanced_reports_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_button.dart';

/// Ecra de relatórios avançados — dashboards, filtros e exportação.
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedPeriod = 'Este Mês';

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
          'Relatórios Avançados',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Filtro de período
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _PeriodChip(
              selected: _selectedPeriod,
              onChanged: (v) => setState(() => _selectedPeriod = v),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vendas'),
            Tab(text: 'Financeiro'),
            Tab(text: 'Estoque'),
          ],
        ),
      ),        body: TabBarView(
        controller: _tabController,
        children: [
          _SalesReportTab(selectedPeriod: _selectedPeriod),
          _FinancialReportTab(selectedPeriod: _selectedPeriod),
          _StockReportTab(selectedPeriod: _selectedPeriod),
        ],
      ),
    );
  }
}

// ─── Vendas ─────────────────────────────────────────────────────────────

class _SalesReportTab extends StatelessWidget {
  const _SalesReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // KPI Cards
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total de Vendas',
                value: '0,00 MT',
                icon: Icons.trending_up,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Ticket Médio',
                value: '0,00 MT',
                icon: Icons.receipt_long,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Nº de Vendas',
                value: '0',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Itens Vendidos',
                value: '0',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Gráfico placeholder
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendas por Dia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 40,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gráfico de vendas diárias',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Top produtos
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Produtos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sem dados para o período seleccionado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Relatório (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareSalesReport(
            period: selectedPeriod,
            kpis: {
              'Total de Vendas': '0,00 MT',
              'Ticket Médio': '0,00 MT',
              'Nº de Vendas': '0',
              'Itens Vendidos': '0',
            },
          ),
        ),
      ],
    );
  }
}

// ─── Financeiro ─────────────────────────────────────────────────────────

class _FinancialReportTab extends StatelessWidget {
  const _FinancialReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Receitas',
                value: '0,00 MT',
                icon: Icons.arrow_downward,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Despesas',
                value: '0,00 MT',
                icon: Icons.arrow_upward,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiCard(
          label: 'Lucro Líquido',
          value: '0,00 MT',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF3B82F6),
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fluxo de Caixa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 40,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gráfico de fluxo de caixa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),        AppButton.secondary(
          expanded: true,
          label: 'Exportar Financeiro (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareFinancialReport(
            period: selectedPeriod,
            kpis: {
              'Receitas': '0,00 MT',
              'Despesas': '0,00 MT',
              'Lucro Líquido': '0,00 MT',
            },
          ),
        ),
      ],
    );
  }
}




// ─── Estoque ────────────────────────────────────────────────────────────

class _StockReportTab extends StatelessWidget {
  const _StockReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Produtos',
                value: '0',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Estoque Baixo',
                value: '0',
                icon: Icons.warning_amber,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Valor em Estoque',
                value: '0,00 MT',
                icon: Icons.attach_money,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Próx. Validade',
                value: '0',
                icon: Icons.event_busy,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),        AppButton.secondary(
          expanded: true,
          label: 'Exportar Estoque (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareStockReport(
            period: selectedPeriod,
            kpis: {
              'Total Produtos': '0',
              'Estoque Baixo': '0',
              'Valor em Estoque': '0,00 MT',
              'Próx. Validade': '0',
            },
          ),
        ),
      ],
    );
  }
}




// ─── Componentes compartilhados ─────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = ['Hoje', 'Esta Semana', 'Este Mês', 'Este Ano'];

    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => periods
          .map(
            (p) => PopupMenuItem(
              value: p,
              child: Text(p),
            ),
          )
          .toList(),
    );
  }
}

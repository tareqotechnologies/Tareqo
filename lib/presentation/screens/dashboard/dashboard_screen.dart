import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/expiry_alerts_provider.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/purchase_card.dart';
import '../../widgets/sale_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/app_shell.dart';
import '../stores/stores_screen.dart';

/// Limiar de "stock baixo" (W8 + W11): produtos com estoque inferior a
/// [Quantity.lowStockThresholdUnits] UNIDADES entram no alerta do
/// dashboard (o estoque vive em milésimos — a comparação usa ×1000).

/// Tela inicial do ERP — visão geral do negócio: indicadores (KPIs),
/// ações rápidas, vendas recentes e alertas de estoque.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    // Tenant do usuário (dono aprovado) — usado no card de Lojas.
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    // Nível de acesso (dono/gerente/funcionário): condiciona os módulos
    // de gestão (Lojas = só dono) e os módulos de nível gerencial
    // (Compras/Relatórios = gerente+). O servidor continua sendo a
    // autoridade (RLS + guardas das RPCs).
    final accessLevel = ref.watch(currentAccessLevelProvider);

    final productsAsync = ref.watch(productsProvider);
    final salesAsync = ref.watch(salesListProvider);
    // Compras recentes (módulo GERENCIAL — a seção só aparece para dono e
    // gerente; o servidor também nega funcionários). O watch é incondicional
    // e a seção filtra por acesso: para funcionários a busca é negada pelo
    // servidor (is_manager_of_store) e cai em AsyncError — engolido pelo
    // `.value ?? const []` (seção vazia e oculta, sem efeito na UI).
    final purchasesAsync = ref.watch(purchasesProvider);
    // KPIs (W5): no modo Supabase a agregação roda no SERVIDOR (RPC
    // `get_dashboard_kpis` — uma chamada em vez de 4 listagens de até 1000
    // linhas); no modo local, fallback client-side idêntico ao anterior.
    final kpisAsync = ref.watch(dashboardKpisProvider);
    final cashFlowPeriod = ref.watch(cashFlowPeriodProvider);
    // Loja ativa (seletor no topo das telas) — o dashboard mostra os
    // indicadores da loja selecionada e exibe o nome dela no topo.
    final activeStoreId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    final stores = tenant == null
        ? const <Store>[]
        : ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    final activeStore = activeStoreId == null
        ? null
        : stores.where((store) => store.id == activeStoreId).firstOrNull;

    final kpis = kpisAsync.value;

    final products = productsAsync.value ?? const <Product>[];
    final lowStock = products
        .where(
          (product) =>
              product.stockQuantity <
              Quantity.lowStockThresholdUnits * Quantity.milliFactor,
        )
        .toList();
    // Alertas de validade (W11): vermelho = lote vencido com estoque;
    // amarelo = vence em menos de 30 dias.
    final expiryAlertsAsync = ref.watch(expiryAlertsProvider);
    final expiryAlerts = expiryAlertsAsync.value ?? const <ExpiryAlert>[];
    final recentSales = (salesAsync.value ?? const <Sale>[]).take(3).toList();
    final recentPurchases =
        (purchasesAsync.value ?? const <Purchase>[]).take(3).toList();

    final displayName = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName.split(' ').first
        : (user?.email.isNotEmpty ?? false)
        ? user!.email.split('@').first
        : l10n.dashboardOwnerFallback;

    final now = DateTime.now();
    final todayLabel =
        '${_weekday(now.weekday, l10n)}, ${Formatters.date(now)}';

    // Padding lateral adaptativo: mais respiro em telas largas (web/tablet),
    // sem desperdiçar espaço em telefones.
    final horizontal = MediaQuery.sizeOf(context).width >= 720 ? 32.0 : 20.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Recarrega KPIs, produtos (estoque) e vendas recentes. O
            // indicador permanece visível até os dados de fato chegarem
            // (`provider.future` resolve quando o AsyncNotifier termina;
            // `onError` engole falhas — o estado AsyncValue já expõe o erro
            // na UI).
            ref.invalidate(dashboardKpisProvider);
            ref.invalidate(productsProvider);
            ref.invalidate(salesListProvider);
            ref.invalidate(purchasesProvider);
            ref.invalidate(expiryAlertsProvider);
            await Future.wait<void>([
              ref
                  .read(dashboardKpisProvider.future)
                  .then<void>((_) {}, onError: (_) {}),
              ref
                  .read(productsProvider.future)
                  .then<void>((_) {}, onError: (_) {}),
              ref
                  .read(salesListProvider.future)
                  .then<void>((_) {}, onError: (_) {}),
              ref
                  .read(purchasesProvider.future)
                  .then<void>((_) {}, onError: (_) {}),
              ref
                  .read(expiryAlertsProvider.future)
                  .then<void>((_) {}, onError: (_) {}),
            ]);
          },
          child: ListView(
            // Sempre rolável: permite o pull-to-refresh mesmo com pouco
            // conteúdo na tela.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardGreeting(displayName),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Nome da loja ativa — deixa claro qual loja os
                        // indicadores abaixo estão exibindo.
                        if (activeStore != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 15,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              // Flexible + ellipsis: nomes de loja longos (ou
                              // escala de texto alta) nunca estouram o cabeçalho.
                              Flexible(
                                child: Text(
                                  activeStore.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.dashboardSignOutTooltip,
                    icon: const Icon(Icons.logout),
                    onPressed: () => ref.read(signOutUseCaseProvider).call(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _KpiGrid(
                cards: [
                  KpiCard(
                    label: l10n.dashboardTotalSales,
                    value: Formatters.currency(kpis?.totalSalesCents ?? 0),
                    caption: l10n.dashboardAllTime,
                    icon: Icons.point_of_sale_outlined,
                    loading: kpisAsync.isLoading,
                  ),
                  KpiCard(
                    label: l10n.dashboardCashBalance,
                    value: Formatters.currency(kpis?.cashBalanceCents ?? 0),
                    caption: cashFlowPeriod.label(context.l10n),
                    icon: Icons.account_balance_wallet_outlined,
                    iconBackground: theme.income.withValues(alpha: 0.14),
                    iconColor: theme.income,
                    loading: kpisAsync.isLoading,
                  ),
                  KpiCard(
                    label: l10n.dashboardReceivables,
                    value: Formatters.currency(kpis?.pendingTotalCents ?? 0),
                    icon: Icons.receipt_long_outlined,
                    iconBackground: theme.warning.withValues(alpha: 0.14),
                    iconColor: theme.warning,
                    loading: kpisAsync.isLoading,
                  ),
                  KpiCard(
                    label: l10n.dashboardStockLabel,
                    // W11: o KPI soma milésimos — exibe em unidades.
                    value:
                        '${Quantity.format(kpis?.stockTotal ?? 0)} ${l10n.commonUnits}',
                    icon: Icons.inventory_2_outlined,
                    loading: kpisAsync.isLoading,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.dashboardQuickActions),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAction(
                    icon: Icons.add_shopping_cart,
                    label: l10n.dashboardQuickNewSale,
                    onTap: () => ref
                        .read(shellIndexProvider.notifier)
                        .goTo(AppSection.sales),
                  ),
                  _QuickAction(
                    icon: Icons.add_box_outlined,
                    label: l10n.dashboardQuickAddProduct,
                    onTap: () => ref
                        .read(shellIndexProvider.notifier)
                        .goTo(AppSection.products),
                  ),
                  _QuickAction(
                    icon: Icons.swap_horiz,
                    label: l10n.dashboardQuickAddTransaction,
                    onTap: () => ref
                        .read(shellIndexProvider.notifier)
                        .goTo(AppSection.financial),
                  ),
                  _QuickAction(
                    icon: Icons.add_card,
                    label: l10n.dashboardQuickAddDebt,
                    onTap: () => ref
                        .read(shellIndexProvider.notifier)
                        .goTo(AppSection.credit),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.dashboardModules),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModuleCard(
                    icon: Icons.people_outline,
                    label: l10n.dashboardModuleCustomers,
                    onTap: () => ref
                        .read(shellIndexProvider.notifier)
                        .goTo(AppSection.customers),
                  ),
                  // Compras e Relatórios: módulos de nível GERENCIAL —
                  // visíveis para dono e gerente, ocultos para funcionários
                  // (matriz de acesso). O servidor também nega compras de
                  // funcionários (is_manager_of_store no process_purchase e
                  // nas políticas RLS de purchases).
                  if (accessLevel != UserAccessLevel.employee)
                    _ModuleCard(
                      icon: Icons.local_shipping_outlined,
                      label: l10n.dashboardModulePurchases,
                      onTap: () {
                        // Dados frescos ao reabrir (providers de escopo raiz).
                        ref.invalidate(purchasesProvider);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PurchasesScreen(),
                          ),
                        );
                      },
                    ),
                  if (accessLevel != UserAccessLevel.employee)
                    _ModuleCard(
                      icon: Icons.bar_chart_outlined,
                      label: l10n.dashboardModuleReports,
                      onTap: () {
                        // Dados frescos ao reabrir (providers de escopo raiz).
                        ref.invalidate(salesReportProvider);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                  // Lojas: gestão do tenant (lojas, funcionários e plano) —
                  // visível APENAS para o DONO com tenant aprovado.
                  if (tenant != null &&
                      tenant.status == TenantStatus.approved &&
                      accessLevel == UserAccessLevel.owner)
                    _ModuleCard(
                      icon: Icons.storefront_outlined,
                      label: l10n.dashboardModuleStores,
                      onTap: () {
                        // Dados frescos + seletor reage a novas lojas ao
                        // voltar (activeStoreIdProvider observa storesProvider).
                        ref.invalidate(storesProvider(tenant.id));
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StoresScreen(tenant: tenant),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n.dashboardRecentSales,
                // "Ver todas" só quando há vendas para ver (o vazio já
                // orienta a registrar a primeira).
                actionLabel: recentSales.isEmpty ? null : l10n.dashboardViewAll,
                onAction: () => ref
                    .read(shellIndexProvider.notifier)
                    .goTo(AppSection.sales),
              ),
              const SizedBox(height: 12),
              if (recentSales.isEmpty)
                _InlineEmpty(message: l10n.dashboardNoSales)
              else
                for (final sale in recentSales) ...[
                  // Card de venda COMPARTILHADO com a lista de Vendas
                  // (tocar abre os detalhes da venda).
                  SalesCard(sale: sale),
                  const SizedBox(height: 8),
                ],
              // Compras recentes — módulo de nível GERENCIAL: visível para
              // dono e gerente, oculto para funcionários (mesma regra do
              // card de módulo; o servidor também nega via is_manager_of_store).
              // Card COMPARTILHADO com a lista de Compras.
              if (accessLevel != UserAccessLevel.employee) ...[
                const SizedBox(height: 24),
                SectionHeader(
                  title: l10n.dashboardRecentPurchases,
                  actionLabel: recentPurchases.isEmpty
                      ? null
                      : l10n.dashboardViewAll,
                  onAction: () {
                    // Dados frescos ao reabrir (providers de escopo raiz).
                    ref.invalidate(purchasesProvider);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PurchasesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (recentPurchases.isEmpty)
                  _InlineEmpty(message: l10n.dashboardNoPurchases)
                else
                  for (final purchase in recentPurchases) ...[
                    PurchaseCard(purchase: purchase),
                    const SizedBox(height: 8),
                  ],
              ],
              if (expiryAlerts.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionHeader(title: l10n.dashboardExpiryAlerts),
                const SizedBox(height: 12),
                for (final alert in expiryAlerts) ...[
                  _ExpiryAlertCard(alert: alert),
                  const SizedBox(height: 8),
                ],
              ],
              if (lowStock.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionHeader(title: l10n.dashboardLowStock),
                const SizedBox(height: 12),
                for (final product in lowStock) ...[
                  _LowStockCard(product: product),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _weekday(int weekday, AppLocalizations l10n) =>
      switch (weekday) {
        DateTime.monday => l10n.weekdayMonday,
        DateTime.tuesday => l10n.weekdayTuesday,
        DateTime.wednesday => l10n.weekdayWednesday,
        DateTime.thursday => l10n.weekdayThursday,
        DateTime.friday => l10n.weekdayFriday,
        DateTime.saturday => l10n.weekdaySaturday,
        _ => l10n.weekdaySunday,
      };
}

/// Grade responsiva de KPIs — sem altura fixa por célula.
///
/// Substitui o `GridView.count` com `childAspectRatio` fixo (que estourava
/// quando um card tinha conteúdo maior — ex.: caption de período —, gerando
/// "BOTTOM OVERFLOWED"): cada linha cresce até a altura do card mais alto
/// via [IntrinsicHeight], então a grade se adapta a escala de texto alta,
/// valores longos e qualquer largura (2 colunas no telefone, 4 em telas
/// largas).
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final rows = <List<Widget>>[];
        for (var i = 0; i < cards.length; i += columns) {
          rows.add(cards.sublist(i, (i + columns).clamp(0, cards.length)));
        }

        return Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: 12),
                      Expanded(child: rows[r][c]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Card de módulo — acesso a módulos complementares (Clientes, Compras,
/// Relatórios) a partir do dashboard.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 148,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ação rápida — pílula com ícone e rótulo.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              // Flexible + ellipsis: rótulos longos ('Adicionar transação')
              // encolhem com escala de texto alta em vez de estourar a pílula.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alerta de produto com estoque baixo.
class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(product.name, style: theme.textTheme.bodyMedium),
            ),
            // Flexible: o chip encolhe (ellipsis) com escala de texto alta
            // ou estoque grande, em vez de estourar o card.
            Flexible(
              child: StatusChip(
                label:
                    '${Quantity.format(product.stockQuantity, unitLabel: product.vendaPorFracao ? product.unitLabel : null, language: Formatters.currentLanguage)}'
                    '${product.vendaPorFracao ? '' : ' ${context.l10n.commonUnits}'}',
                color: theme.warning,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alerta de VALIDADE (W11): vermelho para lotes VENCIDOS com estoque,
/// amarelo para lotes que vencem em menos de [expiryWarningDays] dias.
class _ExpiryAlertCard extends StatelessWidget {
  const _ExpiryAlertCard({required this.alert});

  final ExpiryAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final expired = alert.isExpired;
    final color = expired ? theme.colorScheme.error : theme.warning;
    final product = alert.product;
    final label = expired
        ? l10n.dashboardExpiredIn(-alert.daysRemaining)
        : l10n.dashboardExpiresIn(alert.daysRemaining);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              expired ? Icons.dangerous_outlined : Icons.hourglass_top_rounded,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$label · ${Formatters.date(alert.lot.expiryDate!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Flexible(
              child: StatusChip(
                label: Quantity.format(
                  alert.lot.currentQuantity,
                  unitLabel: product.vendaPorFracao ? product.unitLabel : null,
                  language: Formatters.currentLanguage,
                ),
                color: color,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensagem inline de seção vazia (sem o peso visual do EmptyState).
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

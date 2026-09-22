import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/i18n/domain_error_l10n.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/ui/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/plan_request.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/store_employee.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/usecases/add_employee_use_case.dart';
import '../../../domain/usecases/add_store_use_case.dart';
import '../../../domain/usecases/request_plan_upgrade_use_case.dart';
import '../../../domain/usecases/set_employee_active_use_case.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/store_scoped_content.dart';
import '../auth/change_password_sheet.dart';
import '../support/support_screen.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../domain/repositories/i_employee_account_service.dart';
part 'stores_widgets.dart';

/// Gestão do tenant (dono): lojas, funcionários e plano contratado.
///
/// - **Lojas**: criar lojas (limitadas pelo plano);
/// - **Funcionários**: criar a conta do funcionário (nome + e-mail + senha)
/// e vinculá-lo a uma loja com cargo (limitado pelo plano);
/// - **Plano**: ver o plano atual, limites e solicitar upgrade.
///
/// Usa um [TabController] explícito com listener que chama `setState` —
/// o FAB (que vive no slot do `Scaffold`, fora do escopo de um eventual
/// `DefaultTabController`) precisa reagir à troca de aba.
class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key, required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    // Rebuild para atualizar o FAB (rótulo/visibilidade por aba).
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openAddStore() async {
    await showAppSheet<void>(
      context,
      builder: (_) => _AddStoreSheet(tenant: widget.tenant),
    );
    if (!mounted) return;
    ref.invalidate(storesProvider(widget.tenant.id));
  }

  Future<void> _openAddEmployee() async {
    await showAppSheet<void>(
      context,
      builder: (_) => _AddEmployeeSheet(tenant: widget.tenant),
    );
    if (!mounted) return;
    ref.invalidate(employeesProvider(widget.tenant.id));
  }

  Future<void> _requestUpgrade() async {
    await showAppSheet<void>(
      context,
      builder: (_) => _UpgradeSheet(tenant: widget.tenant),
    );
    if (!mounted) return;
    ref.invalidate(myPlanRequestsProvider(widget.tenant.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tenant = widget.tenant;
    final planAsync = ref.watch(plansProvider);
    final storesAsync = ref.watch(storesProvider(tenant.id));
    final employeesAsync = ref.watch(employeesProvider(tenant.id));
    final requestsAsync = ref.watch(myPlanRequestsProvider(tenant.id));

    final currentPlan = planAsync.value
        ?.where((plan) => plan.id == tenant.planId)
        .firstOrNull;

    // O FAB só faz sentido nas abas Lojas (0) e Funcionários (1).
    final index = _tabController.index;
    final showFab = index != 2 && index != 3;

    return AppPage(
      title: l10n.storesTitle,
      useSafeArea: false,
      // A tela é empurrada por cima do AppShell (fora da casca). A escolha
      // da loja ativa ficou na aba Ajustes (seção "Loja ativa" abaixo).
      body: StoreScopedContent(
        child: Column(
          children: [
            _PlanCard(
              tenant: tenant,
              plan: currentPlan,
              storeCount: storesAsync.value?.length ?? 0,
              employeeCount: employeesAsync.value?.length ?? 0,
              onUpgrade: _requestUpgrade,
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: [
                for (final label in [
                  l10n.storesTabStores,
                  l10n.storesTabEmployees,
                  l10n.storesTabUpgrades,
                  l10n.storesTabSettings,
                ])
                  Tab(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
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
                  _buildStores(storesAsync),
                  _buildEmployees(employeesAsync),
                  _buildUpgrades(requestsAsync),
                  _SettingsTab(tenant: tenant),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showFab
          // FAB circular (design system — igual ao "Novo produto"): só o
          // sinal de +, com tooltip — o rótulo nunca é cortado pelo círculo.
          ? FloatingActionButton(
              // Hero tag único: o AppShell mantém as 6 seções vivas num
              // IndexedStack — sem tags distintas, os FABs (mesmo tag
              // padrão) quebravam o Hero em qualquer transição de rota.
              heroTag: 'fab-stores',
              onPressed: index == 0 ? _openAddStore : _openAddEmployee,
              tooltip: index == 0
                  ? l10n.storesAddStore
                  : l10n.storesAddEmployee,
              // Só o sinal de + (igual ao "Novo produto"): o tooltip
              // carrega o significado — consistência com os FABs das
              // demais telas (Vendas, Compras, Financeiro, Produtos,
              // Clientes).
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStores(AsyncValue<List<Store>> async) {
    final l10n = context.l10n;
    return async.when(
      // Skeleton no primeiro carregamento (padrão das listas).
      loading: () => const ListSkeleton(items: 4),
      error: (error, _) => ErrorView(
        message: l10n.storesLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(storesProvider(widget.tenant.id)),
      ),
      data: (stores) {
        if (stores.isEmpty) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            title: l10n.storesEmptyTitle,
            subtitle: l10n.storesEmptySubtitle,
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            12,
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            96,
          ),
          itemCount: stores.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final store = stores[index];
            final scheme = Theme.of(context).colorScheme;
            return AppCard(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => _openStoreDetail(store),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Avatar pequeno — inicial da loja.
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.tertiaryContainer,
                        child: Text(
                          store.name.isEmpty
                              ? '?'
                              : store.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nome fino + endereço compacto.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w300),
                            ),
                            if (store.address.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                store.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmployees(AsyncValue<List<StoreEmployee>> async) {
    final l10n = context.l10n;
    final stores =
        ref.watch(storesProvider(widget.tenant.id)).value ?? const <Store>[];
    // Só o DONO do tenant vê o interruptor ativar/desativar.
    final user = ref.watch(authStateProvider).value;
    final isOwner = user != null && widget.tenant.ownerUserId == user.id;

    return async.when(
      // Skeleton no primeiro carregamento (padrão das listas).
      loading: () => const ListSkeleton(items: 4),
      error: (error, _) => ErrorView(
        message: l10n.employeesLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(employeesProvider(widget.tenant.id)),
      ),
      data: (employees) {
        if (employees.isEmpty) {
          return EmptyState(
            icon: Icons.badge_outlined,
            title: l10n.employeesEmptyTitle,
            subtitle: l10n.employeesEmptySubtitle,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            12,
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            96,
          ),
          itemCount: employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final employee = employees[index];
            final scheme = Theme.of(context).colorScheme;
            return AppCard(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => _openEmployeeDetail(employee, stores, isOwner),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Avatar pequeno — só a inicial.
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          employee.fullName.isEmpty
                              ? '?'
                              : employee.fullName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nome fino — sem bold, sem chips.
                      Expanded(
                        child: Text(
                          employee.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w300),
                        ),
                      ),
                      // Indicador de estado discreto + chevron.
                      if (!employee.isActive)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEmployeeDetail(
    StoreEmployee employee,
    List<Store> stores,
    bool isOwner,
  ) {
    showAppSheet<void>(
      context,
      builder: (_) => _EmployeeDetailSheet(
        employee: employee,
        stores: stores,
        isOwner: isOwner,
        onToggle: (isActive) => _toggleEmployee(employee, isActive),
      ),
    );
  }

  void _openStoreDetail(Store store) {
    showAppSheet<void>(
      context,
      builder: (_) => _StoreDetailSheet(store: store),
    );
  }

  /// Confirma e ativa/desativa o funcionário (só o dono chega aqui).
  Future<void> _toggleEmployee(StoreEmployee employee, bool isActive) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: isActive
          ? l10n.employeeReactivateConfirm(employee.fullName)
          : l10n.employeeDeactivateConfirm(employee.fullName),
      confirmLabel: isActive
          ? l10n.employeeReactivateAction
          : l10n.employeeDeactivateAction,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(setEmployeeActiveUseCaseProvider)
          .call(
            tenantId: widget.tenant.id,
            employeeId: employee.id,
            isActive: isActive,
          );
      if (!mounted) return;
      ref.invalidate(employeesProvider(widget.tenant.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? l10n.employeeReactivated : l10n.employeeDeactivated,
          ),
        ),
      );
    } on EmployeeNotFoundException catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Funcionário não encontrado ao alterar estado',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.employeesUpdateError)));
    } catch (error, stackTrace) {
      // Supabase: o RPC pode rejeitar (não-dono, rede) — cai aqui sem
      // derrubar a tela; mensagem amigável em vez de erro cru.
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Falha ao alterar estado do funcionário',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.employeesUpdateError)));
    }
  }

  Widget _buildUpgrades(AsyncValue<List<PlanRequest>> async) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];

    String planName(String id) =>
        plans.where((plan) => plan.id == id).firstOrNull?.name ?? id;

    return async.when(
      // Skeleton no primeiro carregamento (padrão das listas).
      loading: () => const ListSkeleton(items: 4),
      error: (error, _) => ErrorView(
        message: l10n.upgradesLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(myPlanRequestsProvider(widget.tenant.id)),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.upgrade_outlined,
            title: l10n.upgradesEmptyTitle,
            subtitle: l10n.upgradesEmptySubtitle,
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            12,
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            96,
          ),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final request = requests[index];
            final scheme = Theme.of(context).colorScheme;
            final (color, label) = switch (request.status) {
              // Pendente = "a aguardar acção" → warning (âmbar), a mesma
              // semântica do resto do app (fiado a receber, vence hoje).
              PlanRequestStatus.pending => (theme.warning, l10n.statusPending),
              PlanRequestStatus.approved => (
                scheme.primary,
                l10n.statusApproved,
              ),
              PlanRequestStatus.rejected => (scheme.error, l10n.statusRejected),
            };
            return AppCard(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.swap_horiz, size: 20, color: color),
                title: Text(
                  '${planName(request.currentPlanId)} → '
                  '${planName(request.requestedPlanId)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.upgradesRequestedOn(
                    '${request.createdAt.day}/${request.createdAt.month}/'
                    '${request.createdAt.year}',
                  ),
                ),
                trailing: StatusChip(label: label, color: color),
                dense: true,
              ),
            );
          },
        );
      },
    );
  }
}

/// Card com o plano atual, uso dos limites e botão de upgrade.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/i18n/l10n_ext.dart';
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
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/store_scoped_content.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../domain/repositories/i_employee_account_service.dart';

/// Gestão do tenant (dono): lojas, funcionários e plano contratado.
///
/// - **Lojas**: criar lojas (limitadas pelo plano);
/// - **Funcionários**: criar a conta do funcionário (nome + e-mail + senha)
///   e vinculá-lo a uma loja com cargo (limitado pelo plano);
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitle)),
      // A tela é empurrada por cima do AppShell (fora da casca): o seletor
      // de loja ativa aparece no topo, deixando claro qual loja está ativa
      // ao gerir lojas.
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
              tabs: [
                Tab(text: l10n.storesTabStores),
                Tab(text: l10n.storesTabEmployees),
                Tab(text: l10n.storesTabUpgrades),
                Tab(text: l10n.storesTabSettings),
              ],
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
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
          ? FloatingActionButton.extended(
              // Hero tag único: o AppShell mantém as 6 seções vivas num
              // IndexedStack — sem tags distintas, os FABs (mesmo tag
              // padrão) quebravam o Hero em qualquer transição de rota.
              heroTag: 'fab-stores',
              onPressed: index == 0 ? _openAddStore : _openAddEmployee,
              icon: Icon(
                index == 0 ? Icons.add_business_outlined : Icons.person_add_alt,
              ),
              label: Text(
                index == 0 ? l10n.storesAddStore : l10n.storesAddEmployee,
              ),
            )
          : null,
    );
  }

  Widget _buildStores(AsyncValue<List<Store>> async) {
    final l10n = context.l10n;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          itemCount: stores.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final store = stores[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.store_outlined),
                title: Text(
                  store.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: store.address.isEmpty ? null : Text(store.address),
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

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
        String storeName(String id) =>
            stores.where((store) => store.id == id).firstOrNull?.name ?? id;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          itemCount: employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final employee = employees[index];
            final scheme = Theme.of(context).colorScheme;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    employee.fullName.isEmpty
                        ? '?'
                        : employee.fullName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  employee.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${storeName(employee.storeId)} · ${employee.email}',
                ),
                trailing: StatusChip(
                  label: employee.role == EmployeeRole.manager
                      ? l10n.roleManager
                      : l10n.roleEmployee,
                  color: employee.role == EmployeeRole.manager
                      ? scheme.primary
                      : scheme.outline,
                  icon: employee.role == EmployeeRole.manager
                      ? Icons.manage_accounts_outlined
                      : Icons.person_outline,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUpgrades(AsyncValue<List<PlanRequest>> async) {
    final l10n = context.l10n;
    final plans = ref.watch(plansProvider).value ?? const <Plan>[];

    String planName(String id) =>
        plans.where((plan) => plan.id == id).firstOrNull?.name ?? id;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final request = requests[index];
            final scheme = Theme.of(context).colorScheme;
            final (color, label) = switch (request.status) {
              PlanRequestStatus.pending => (
                scheme.tertiary,
                l10n.statusPending,
              ),
              PlanRequestStatus.approved => (
                scheme.primary,
                l10n.statusApproved,
              ),
              PlanRequestStatus.rejected => (scheme.error, l10n.statusRejected),
            };
            return Card(
              child: ListTile(
                leading: Icon(Icons.swap_horiz, color: color),
                title: Text(
                  '${planName(request.currentPlanId)} → '
                  '${planName(request.requestedPlanId)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l10n.upgradesRequestedOn(
                    '${request.createdAt.day}/${request.createdAt.month}/'
                    '${request.createdAt.year}',
                  ),
                ),
                trailing: StatusChip(label: label, color: color),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card com o plano atual, uso dos limites e botão de upgrade.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tenant,
    required this.plan,
    required this.storeCount,
    required this.employeeCount,
    required this.onUpgrade,
  });

  final Tenant tenant;
  final Plan? plan;
  final int storeCount;
  final int employeeCount;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan?.name ?? l10n.planCardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.upgrade_outlined, size: 18),
                label: Text(l10n.planCardUpgrade),
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 6),
            Text(
              plan!.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LimitMeter(
                    label: l10n.planCardStores,
                    used: storeCount,
                    max: plan!.maxStores,
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LimitMeter(
                    label: l10n.planCardEmployees,
                    used: employeeCount,
                    max: plan!.maxEmployees,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LimitMeter extends StatelessWidget {
  const _LimitMeter({
    required this.label,
    required this.used,
    required this.max,
    required this.scheme,
  });

  final String label;
  final int used;
  final int max;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ratio = (used / max).clamp(0.0, 1.0);
    final reached = used >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '$used/$max',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: reached ? scheme.error : scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
            color: reached ? scheme.error : scheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Sheet de criação de loja.
class _AddStoreSheet extends ConsumerStatefulWidget {
  const _AddStoreSheet({required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<_AddStoreSheet> createState() => _AddStoreSheetState();
}

class _AddStoreSheetState extends ConsumerState<_AddStoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final store = Store(
      id: AppIds.newId('st'),
      tenantId: widget.tenant.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref.read(addStoreUseCaseProvider).call(store);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addStoreSuccess(store.name))),
      );
    } on InvalidStoreException catch (error) {
      setState(() => _formError = error.message);
    } on PlanLimitExceededException catch (error) {
      setState(() => _formError = error.message);
    } on TenantNotApprovedException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao criar loja');
      setState(() {
        _formError = l10n.addStoreError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: l10n.addStoreTitle),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.addStoreNameLabel,
                prefixIcon: const Icon(Icons.store_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.addStoreNameError
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.addStoreAddressLabel,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 14),
              Text(
                _formError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.addStoreSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de criação de funcionário: nome, e-mail, senha, loja e cargo.
/// A conta é criada no Supabase (ou localmente em dev) e o vínculo é
/// registrado na loja.
class _AddEmployeeSheet extends ConsumerStatefulWidget {
  const _AddEmployeeSheet({required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<_AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedStoreId;
  EmployeeRole _role = EmployeeRole.employee;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      // Cria a conta E o vínculo na loja: no modo Supabase a RPC
      // create_employee_account faz os dois em UMA transação (sem contas
      // órfãs se o limite do plano for atingido); no modo local o caso de
      // uso usa um id sintético + repositório.
      await ref.read(addEmployeeUseCaseProvider).call(
        StoreEmployee(
          id: AppIds.newId('e'),
          tenantId: widget.tenant.id,
          storeId: _selectedStoreId!,
          // Preenchido pelo caso de uso com o id real da conta criada.
          userId: '',
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _role,
        ),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.addEmployeeSuccess)));
    } on InvalidEmployeeException catch (error) {
      setState(() => _formError = error.message);
    } on PlanLimitExceededException catch (error) {
      setState(() => _formError = error.message);
    } on TenantNotApprovedException catch (error) {
      setState(() => _formError = error.message);
    } on EmployeeAccountCreationException catch (error) {
      // Falha ao criar a conta no servidor (e-mail já em uso, senha
      // fraca...) — mensagem amigável vinda da RPC, sem Sentry.
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao cadastrar funcionário',
      );
      setState(() {
        _formError = l10n.addEmployeeError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final storesAsync = ref.watch(storesProvider(widget.tenant.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: l10n.addEmployeeTitle),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.addEmployeeNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.addEmployeeNameError
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.addEmployeeEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return l10n.addEmployeeEmailError;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.addEmployeePasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (value) => (value ?? '').length < 8
                  ? l10n.addEmployeePasswordError
                  : null,
            ),
            const SizedBox(height: 16),
            Text(l10n.addEmployeeStoreLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            storesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(
                l10n.storesLoadError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (stores) {
                if (stores.isEmpty) {
                  return Text(
                    l10n.addEmployeeNoStores,
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final store in stores)
                      ChoiceChip(
                        label: Text(store.name),
                        selected: _selectedStoreId == store.id,
                        onSelected: (_) =>
                            setState(() => _selectedStoreId = store.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(l10n.addEmployeeRoleLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.roleEmployee),
                  selected: _role == EmployeeRole.employee,
                  onSelected: (_) =>
                      setState(() => _role = EmployeeRole.employee),
                ),
                ChoiceChip(
                  label: Text(l10n.roleManager),
                  selected: _role == EmployeeRole.manager,
                  onSelected: (_) =>
                      setState(() => _role = EmployeeRole.manager),
                ),
              ],
            ),
            if (_formError != null) ...[
              const SizedBox(height: 14),
              Text(
                _formError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.addEmployeeSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet de solicitação de upgrade de plano.
class _UpgradeSheet extends ConsumerStatefulWidget {
  const _UpgradeSheet({required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<_UpgradeSheet> {
  String? _selectedPlanId;
  bool _isSubmitting = false;
  String? _formError;

  Future<void> _submit() async {
    if (_selectedPlanId == null) {
      setState(() => _formError = context.l10n.upgradeChooseError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref
          .read(requestPlanUpgradeUseCaseProvider)
          .call(
            tenantId: widget.tenant.id,
            currentPlanId: widget.tenant.planId,
            requestedPlanId: _selectedPlanId!,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.upgradeSuccess)));
    } on InvalidPlanRequestException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao solicitar upgrade',
      );
      setState(() {
        _formError = l10n.upgradeError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plansAsync = ref.watch(plansProvider);
    final candidates = (plansAsync.value ?? const <Plan>[])
        .where((plan) => plan.id != widget.tenant.planId && plan.isActive)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(title: l10n.upgradeTitle),
          Text(
            l10n.upgradeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              l10n.onboardingPlansError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            data: (_) {
              if (candidates.isEmpty) {
                return Text(
                  l10n.upgradeMaxReached,
                  style: theme.textTheme.bodyMedium,
                );
              }
              return Column(
                children: [
                  for (final plan in candidates) ...[
                    _UpgradePlanTile(
                      plan: plan,
                      selected: _selectedPlanId == plan.id,
                      onTap: () => setState(() => _selectedPlanId = plan.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(
              _formError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(l10n.upgradeSubmit),
          ),
        ],
      ),
    );
  }
}

class _UpgradePlanTile extends StatelessWidget {
  const _UpgradePlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.planDetails(plan.maxStores, plan.maxEmployees),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(plan.priceMonthly),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aba Ajustes — o **dono** escolhe o idioma (pt/en) e a moeda
/// (BRL/USD/EUR/MZN) do app. A escolha vale para todo o tenant (os
/// funcionários herdam). Salva em `tenants` e o [tenantSettingsProvider]
/// reage: o locale e a formatação de moeda mudam na hora.
class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab({required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late String _language = widget.tenant.language;
  late String _currencyCode = widget.tenant.currencyCode;

  bool _isSaving = false;
  String? _formError;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref
          .read(updateTenantSettingsUseCaseProvider)
          .call(
            tenantId: widget.tenant.id,
            currencyCode: _currencyCode,
            language: _language,
          );
      if (!mounted) return;
      // Recarrega o tenant: o tenantSettingsProvider (locale + moeda)
      // reage imediatamente.
      final user = ref.read(authStateProvider).value;
      if (user != null) ref.invalidate(myTenantProvider(user.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao salvar ajustes');
      setState(() => _formError = l10n.settingsGenericError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _currencyLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'USD':
        return l10n.currencyUsd;
      case 'EUR':
        return l10n.currencyEur;
      case 'MZN':
        return l10n.currencyMzn;
      default:
        return l10n.currencyBrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text(l10n.onboardingLanguageLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.languagePortuguese),
              selected: _language == 'pt',
              onSelected: (_) => setState(() => _language = 'pt'),
            ),
            ChoiceChip(
              label: Text(l10n.languageEnglish),
              selected: _language == 'en',
              onSelected: (_) => setState(() => _language = 'en'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.onboardingCurrencyLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in AppSettings.supportedCurrencies)
              ChoiceChip(
                label: Text(_currencyLabel(l10n, code)),
                selected: _currencyCode == code,
                onSelected: (_) => setState(() => _currencyCode = code),
              ),
          ],
        ),
        if (_formError != null) ...[
          const SizedBox(height: 14),
          Text(
            _formError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(l10n.settingsSave),
        ),
      ],
    );
  }
}

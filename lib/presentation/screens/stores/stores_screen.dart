import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
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
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/store_scoped_content.dart';
import '../auth/change_password_sheet.dart';
import '../support/support_screen.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../domain/repositories/i_employee_account_service.dart';

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

 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão das demais telas.
 appBar: AppBar(
 title: Text(
 l10n.storesTitle,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.5,
 ),
 ),
 ),
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
 tabs: [
 // FittedBox: rótulos longos ('Funcionários', 'Upgrades')
 // encolhem em vez de estourar o Tab de largura fixa em
 // telas estreitas. Defensivo: a regressão REAL de 21px
 // achada nos testes de rotação foi no _LimitMeter; aqui o
 // risco é de overflow a ~100px por aba com escala alta.
 for (final label in [
 l10n.storesTabStores,
 l10n.storesTabEmployees,
 l10n.storesTabUpgrades,
 l10n.storesTabSettings,
 ])
 Tab(
 child: FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(label, maxLines: 1),
 ),
 ),
 ],
 labelStyle: theme.textTheme.labelLarge?.copyWith(
 fontWeight: FontWeight.w500,
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
 padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
 itemCount: stores.length,
 separatorBuilder: (_, _) => const SizedBox(height: 8),      itemBuilder: (context, index) {
 final store = stores[index];
 final scheme = Theme.of(context).colorScheme;
 return AppCard(
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openStoreDetail(store),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (store.address.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            store.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
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
 padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
 itemCount: employees.length,
 separatorBuilder: (_, _) => const SizedBox(height: 8),      itemBuilder: (context, index) {
          final employee = employees[index];
          final scheme = Theme.of(context).colorScheme;
          return AppCard(
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openEmployeeDetail(employee, stores, isOwner),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                      ),
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
 }  void _openEmployeeDetail(
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
 final confirmed = await showDialog<bool>(
 context: context,
 builder: (context) => AlertDialog(
 title: Text(
 isActive
 ? l10n.employeeReactivateConfirm(employee.fullName)
 : l10n.employeeDeactivateConfirm(employee.fullName),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.of(context).pop(false),
 child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
 ),
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // texto w400 — a confirmação segue o padrão dos demais diálogos.
 AppButton.primary(
 onPressed: () => Navigator.of(context).pop(true),
 label: isActive
 ? l10n.employeeReactivateAction
 : l10n.employeeDeactivateAction,
 ),
 ],
 ),
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
 } on EmployeeNotFoundException catch (error) {
 if (!mounted) return;
 ScaffoldMessenger.of(
 context,
 ).showSnackBar(SnackBar(content: Text(error.message)));
 } catch (error) {
 // Supabase: o RPC pode rejeitar (não-dono, rede) — a mensagem já
 // vem amigável do datasource; cai aqui sem derrubar a tela.
 if (!mounted) return;
 ScaffoldMessenger.of(
 context,
 ).showSnackBar(SnackBar(content: Text('$error')));
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
 padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
 itemCount: requests.length,
 separatorBuilder: (_, _) => const SizedBox(height: 8),
 itemBuilder: (context, index) {
 final request = requests[index];
 final scheme = Theme.of(context).colorScheme;
 final (color, label) = switch (request.status) {
 // Pendente = "a aguardar acção" → warning (âmbar), a mesma
 // semântica do resto do app (fiado a receber, vence hoje).
 PlanRequestStatus.pending => (
 theme.warning,
 l10n.statusPending,
 ),
 PlanRequestStatus.approved => (
 scheme.primary,
 l10n.statusApproved,
 ),
 PlanRequestStatus.rejected => (scheme.error, l10n.statusRejected),
 };        return AppCard(
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.swap_horiz, size: 20, color: color),
            title: Text(
              '${planName(request.currentPlanId)} → '
              '${planName(request.requestedPlanId)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
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
 final l10n = context.l10n;    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
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
 fontWeight: FontWeight.w500,
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
 // Flexible: em telas estreitas o cartão de plano fica com
 // colunas ~158px — sem flex o rótulo longo estourava o Row
 // (regressão encontrada nos testes de rotação).
 Flexible(
 child: Text(
 label,
 // Quebra em até 2 linhas — o rótulo do limite nunca é cortado.
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: Theme.of(context).textTheme.labelSmall?.copyWith(
 color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
 ),
 ),
 ),
 const SizedBox(width: 8),
 Flexible(
 child: Text(
 '$used/$max',
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: Theme.of(context).textTheme.labelSmall?.copyWith(
 fontWeight: FontWeight.w500,
 color: reached ? scheme.error : scheme.onPrimaryContainer,
 ),
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
}class _AddStoreSheetState extends ConsumerState<_AddStoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nuitController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nuitController.dispose();
    _cityController.dispose();
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
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      nuit: _nuitController.text.trim(),
      city: _cityController.text.trim(),
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
 children: [        AppSheetHeader(title: l10n.addStoreTitle),
        // Seção: Dados da loja — nome e endereço.
        SheetSection(
          icon: Icons.store_outlined,
          title: l10n.addStoreTitle,
          children: [
            AppTextField(
              controller: _nameController,
              label: l10n.addStoreNameLabel,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.addStoreNameError
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _addressController,
              label: l10n.addStoreAddressLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneController,
              label: l10n.addStorePhoneLabel,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: l10n.addStoreEmailLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SheetSection(
          icon: Icons.receipt_long_outlined,
          title: l10n.storeDetailNuit,
          children: [
            AppTextField(
              controller: _nuitController,
              label: l10n.addStoreNuitLabel,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _cityController,
              label: l10n.addStoreCityLabel,
              textInputAction: TextInputAction.done,
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
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // cores sólidas — o spinner substitui o ícone durante o envio.
 AppButton.primary(
 onPressed: _isSubmitting ? null : _submit,
 label: l10n.addStoreSubmit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
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

 /// Alterna a visibilidade da senha (olho) — UX para senha longa no
 /// celular (mesmo padrão do login e da troca de senha).
 bool _obscurePassword = true;

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
 await ref
 .read(addEmployeeUseCaseProvider)
 .call(
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
 children: [        AppSheetHeader(title: l10n.addEmployeeTitle),
        // Seção: Dados pessoais — nome, email e senha.
        SheetSection(
          icon: Icons.person_outline,
          title: l10n.addEmployeeTitle,
          children: [
            AppTextField(
              controller: _nameController,
              label: l10n.addEmployeeNameLabel,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.addEmployeeNameError
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: l10n.addEmployeeEmailLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return l10n.addEmployeeEmailError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: l10n.addEmployeePasswordLabel,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? l10n.loginShowPassword
                    : l10n.loginHidePassword,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) => (value ?? '').length < 8
                  ? l10n.addEmployeePasswordError
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Seção: Vínculo — loja e cargo.
        SheetSection(
          icon: Icons.work_outline,
          title: l10n.addEmployeeStoreLabel,
          children: [
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
            const SizedBox(height: 12),
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
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // cores sólidas — o spinner substitui o ícone durante o envio.
 AppButton.primary(
 onPressed: _isSubmitting ? null : _submit,
 label: l10n.addEmployeeSubmit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
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
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // cores sólidas — o spinner substitui o ícone durante o envio.
 AppButton.primary(
 onPressed: _isSubmitting ? null : _submit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 18,
 width: 18,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Icon(Icons.send_outlined),
 label: l10n.upgradeSubmit,
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
 final l10n = context.l10n;    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.3)
              : null,
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
 fontWeight: FontWeight.w500,
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
 Formatters.currency(plan.priceMonthlyCents),
 style: Theme.of(context).textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.w500,
 color: scheme.primary,
 ),
 ),
 ],
 ),
 ),
 );
 }
}

/// Aba Ajustes — o **dono** escolhe o idioma (pt/en/fr) e a moeda
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
 // Loja ativa: a escolha migrou do banner do topo para AQUI (Lojas →
 // Ajustes). Todos os módulos (vendas, estoque, financeiro...) escopam
 // por activeStoreIdProvider — trocar o chip troca os dados na hora.
 final user = ref.watch(authStateProvider).value;
 final storesAsync = ref.watch(storesProvider(widget.tenant.id));
 final stores = storesAsync.value ?? const <Store>[];
 final activeStoreId = user == null
 ? null
 : ref.watch(activeStoreIdProvider(user.id));

 return ListView(
 padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
 children: [
 // LOJA ATIVA — só com 2+ lojas E usuário logado há o que escolher
 // (com uma única loja não existe seletor, o mesmo critério do
 // banner antigo). O guard `user != null` espelha a linha do
 // `activeStoreId` acima — sem `!` no callback.
 if (user != null && stores.length > 1) ...[
 Text(
 l10n.storeSelectorSectionTitle,
 style: theme.textTheme.titleSmall,
 ),
 const SizedBox(height: 4),
 Text(
 l10n.storeSelectorSectionHint,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: 8),
 Wrap(
 spacing: 8,
 runSpacing: 8,
 children: [
 for (final store in stores)
 ChoiceChip(
 avatar: store.id == activeStoreId
 ? const Icon(Icons.check, size: 16)
 : null,
 label: Text(store.name),
 selected: store.id == activeStoreId,
 onSelected: (_) => ref
 .read(activeStoreIdProvider(user.id).notifier)
 .select(store.id),
 ),
 ],
 ),
 const SizedBox(height: 24),
 ],
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
 ChoiceChip(
 label: Text(l10n.languageFrench),
 selected: _language == 'fr',
 onSelected: (_) => setState(() => _language = 'fr'),
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
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // cores sólidas — o spinner substitui o ícone durante o envio.
 AppButton.primary(
 onPressed: _isSaving ? null : _save,
 icon: _isSaving
 ? const SizedBox(
 height: 18,
 width: 18,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Icon(Icons.save_outlined),
 label: l10n.settingsSave,
 ),
 // SEGURANÇA — troca de senha da conta (qualquer utilizador
 // logado; não é uma definição do tenant).
 const SizedBox(height: 32),
 Text(l10n.securitySectionTitle, style: theme.textTheme.titleSmall),
 const SizedBox(height: 8),
 AppCard(
 onTap: () => showAppSheet<void>(
 context,
 builder: (_) => const ChangePasswordSheet(),
 ),
 child: Row(
 children: [
 Icon(Icons.lock_reset_outlined, color: theme.colorScheme.primary),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 l10n.securityChangePassword,
 style: theme.textTheme.titleSmall,
 ),
 const SizedBox(height: 2),
 Text(
 l10n.securityChangePasswordHint,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.35,
 ),
 ),
 ],
 ),
 ),
 Icon(
 Icons.chevron_right,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ],
 ),
 ),
 // SUPORTE — acesso à documentação embutida (Ajuda → Guia do
 // Usuário / Troubleshooting). Fica separado do formulário acima
 // (moeda/idioma) por não ser uma definição do tenant.
 const SizedBox(height: 32),
 Text(l10n.settingsSupportSection, style: theme.textTheme.titleSmall),
 const SizedBox(height: 8),
 AppCard(
 onTap: () => Navigator.of(context).push(
 MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
 ),
 child: Row(
 children: [
 Icon(
 Icons.support_agent_outlined,
 color: theme.colorScheme.primary,
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 l10n.settingsSupportEntry,
 style: theme.textTheme.titleSmall,
 ),
 const SizedBox(height: 2),
 Text(
 l10n.settingsSupportEntryHint,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.35,
 ),
 ),
 ],
 ),
 ),
 Icon(
 Icons.chevron_right,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ],
 ),
 ),
 ],
 );
 }
}

/// Sheet de detalhes de um funcionário — exibida ao tocar no card.
class _EmployeeDetailSheet extends StatelessWidget {
  const _EmployeeDetailSheet({
    required this.employee,
    required this.stores,
    required this.isOwner,
    required this.onToggle,
  });

  final StoreEmployee employee;
  final List<Store> stores;
  final bool isOwner;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isManager = employee.role == EmployeeRole.manager;

    final storeName = stores
        .where((s) => s.id == employee.storeId)
        .firstOrNull?.name ?? employee.storeId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho: avatar + nome ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  employee.fullName.isEmpty
                      ? '?'
                      : employee.fullName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  employee.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (!employee.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Detalhes ──
          _DetailRow(
            label: l10n.employeeDetailEmail,
            value: employee.email,
            icon: Icons.email_outlined,
          ),
          _DetailRow(
            label: l10n.employeeDetailStore,
            value: storeName,
            icon: Icons.store_outlined,
          ),
          _DetailRow(
            label: l10n.employeeDetailRole,
            value: isManager ? l10n.roleManager : l10n.roleEmployee,
            icon: isManager
                ? Icons.manage_accounts_outlined
                : Icons.person_outline,
            valueColor: isManager ? scheme.primary : null,
          ),
          _DetailRow(
            label: l10n.employeeDetailStatus,
            value: employee.isActive
                ? l10n.employeeDetailActive
                : l10n.employeeDetailInactive,
            icon: employee.isActive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            valueColor: employee.isActive ? scheme.primary : scheme.error,
          ),

          // ── Ações ──
          if (isOwner) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (employee.isActive)
              AppButton.danger(
                onPressed: () {
                  Navigator.of(context).pop();
                  onToggle(false);
                },
                label: l10n.employeeDeactivateAction,
                icon: const Icon(Icons.block_outlined, size: 18),
              )
            else
              AppButton.primary(
                onPressed: () {
                  Navigator.of(context).pop();
                  onToggle(true);
                },
                label: l10n.employeeReactivateAction,
                icon: const Icon(Icons.check_circle_outlined, size: 18),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Linha de detalhe — ícone + rótulo + valor.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ?? scheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet de detalhes de uma loja — exibida ao tocar no card.
class _StoreDetailSheet extends StatelessWidget {
  const _StoreDetailSheet({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho: avatar + nome ──
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.tertiaryContainer,
                child: Text(
                  store.name.isEmpty
                      ? '?'
                      : store.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Detalhes ──
          if (store.phone.isNotEmpty)
            _DetailRow(
              label: l10n.storeDetailPhone,
              value: store.phone,
              icon: Icons.phone_outlined,
            ),
          if (store.email.isNotEmpty)
            _DetailRow(
              label: l10n.storeDetailEmail,
              value: store.email,
              icon: Icons.email_outlined,
            ),
          if (store.nuit.isNotEmpty)
            _DetailRow(
              label: l10n.storeDetailNuit,
              value: store.nuit,
              icon: Icons.receipt_long_outlined,
            ),
          if (store.city.isNotEmpty)
            _DetailRow(
              label: l10n.storeDetailCity,
              value: store.city,
              icon: Icons.location_city_outlined,
            ),
          if (store.address.isNotEmpty)
            _DetailRow(
              label: l10n.storeDetailAddress,
              value: store.address,
              icon: Icons.place_outlined,
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

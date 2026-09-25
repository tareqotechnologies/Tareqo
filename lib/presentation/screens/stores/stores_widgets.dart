part of 'stores_screen.dart';

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
      margin: EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        12,
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    fontWeight: FontWeight.w600,
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
}

class _AddStoreSheetState extends ConsumerState<_AddStoreSheet> {
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
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on PlanLimitExceededException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on TenantNotApprovedException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
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
            SheetHeader(title: l10n.addStoreTitle),
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
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on PlanLimitExceededException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on TenantNotApprovedException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on EmployeeAccountCreationException catch (error) {
      // Falha ao criar a conta no servidor (e-mail já em uso, senha
      // fraca...) — mensagem amigável vinda da RPC, sem Sentry.
      setState(() => _formError = domainErrorMessage(error, l10n));
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
            SheetHeader(title: l10n.addEmployeeTitle),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                Text(
                  l10n.addEmployeeRoleLabel,
                  style: theme.textTheme.titleSmall,
                ),
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
      setState(() => _formError = domainErrorMessage(error, l10n));
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
          SheetHeader(title: l10n.upgradeTitle),
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
    final l10n = context.l10n;
    return InkWell(
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
                      fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
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
  late bool _mfaEnforced = widget.tenant.mfaEnforced;
  // Haptics: estado inicial assume ligado (default); a leitura real é
  // async — sincroniza no initState sem bloquear o primeiro frame.
  bool _hapticsEnabled = Haptics.isEnabled;

  @override
  void initState() {
    super.initState();
    Haptics.load().then((_) {
      if (mounted) setState(() => _hapticsEnabled = Haptics.isEnabled);
    });
  }

  bool _isSaving = false;
  String? _formError;

  /// P1 (auditoria): o dono ativa a exigência de MFA NO SERVIDOR — a RPC
  /// `update_tenant_settings` valida dono + fator TOTP verificado antes de
  /// ligar `tenants.mfa_enforced`.
  Future<void> _toggleMfaEnforced(bool value) async {
    setState(() => _mfaEnforced = value);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(updateTenantSettingsUseCaseProvider)
          .call(
            tenantId: widget.tenant.id,
            currencyCode: _currencyCode,
            language: _language,
            mfaEnforced: value,
          );
      final user = ref.read(authStateProvider).value;
      if (user != null) ref.invalidate(myTenantProvider(user.id));
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao alterar exigência de MFA do tenant',
      );
      if (mounted) setState(() => _mfaEnforced = !value);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsMfaEnforceError)),
      );
    }
  }

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
            // P1: a RPC grava mfa_enforced SEMPRE que p_mfa_enforced vem
            // preenchido — enviar o estado ATUAL do formulário evita que
            // um ajuste de moeda/idioma desligue a exigência por engano.
            mfaEnforced: _mfaEnforced,
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        16,
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        96,
      ),
      children: [
        // SALVAR — botão verde de largura total no TOPO da aba (referência
        // de produto): persiste idioma + moeda. O spinner substitui o
        // ícone durante o envio (design system ultra-clean).
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
        if (_formError != null) ...[
          const SizedBox(height: 10),
          Text(
            _formError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        // MFA + FEEDBACK TÁTIL — switches de efeito IMEDIATO (salvam
        // sozinhos, sem passar pelo botão Salvar), logo abaixo dele como
        // na referência.
        // P1 (MFA server-side): exigência de aal2 nas escritas de dinheiro
        // do tenant — persistida no SERVIDOR via update_tenant_settings.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _mfaEnforced,
          onChanged: (v) => unawaited(_toggleMfaEnforced(v)),
          title: Text(
            l10n.settingsMfaEnforceTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _mfaEnforced
                ? l10n.settingsMfaEnforceSubOn
                : l10n.settingsMfaEnforceSubOff,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
        // GERAL — feedback tátil: preferência LOCAL do dispositivo (não é
        // do tenant — cada operador escolhe no seu aparelho).
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          onChanged: (v) async {
            await Haptics.setEnabled(v);
            if (mounted) setState(() => _hapticsEnabled = v);
          },
          title: Text(
            l10n.settingsHapticsTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.settingsHapticsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // LOJA ATIVA — só com 2+ lojas E usuário logado há o que escolher
        // (com uma única loja não existe seletor, o mesmo critério do
        // banner antigo). O guard `user != null` espelha a linha do
        // `activeStoreId` acima — sem `!` no callback.
        if (user != null && stores.length > 1) ...[
          Text(
            l10n.storeSelectorSectionTitle,
            style: theme.textTheme.titleSmall,
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
        const SizedBox(height: 24),
        // SEGURANÇA — troca de senha da conta (qualquer utilizador
        // logado; não é uma definição do tenant).
        const SizedBox(height: 32),
        Text(l10n.securitySectionTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _SettingsEntry(
          icon: Icons.lock_reset_outlined,
          title: l10n.securityChangePassword,
          subtitle: l10n.securityChangePasswordHint,
          onTap: () => showAppSheet<void>(
            context,
            builder: (_) => const ChangePasswordSheet(),
          ),
        ),
        // SUPORTE — acesso à documentação embutida (Ajuda → Guia do
        // Usuário / Troubleshooting). Fica separado do formulário acima
        // (moeda/idioma) por não ser uma definição do tenant.
        const SizedBox(height: 32),
        Text(l10n.settingsSupportSection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _SettingsEntry(
          icon: Icons.support_agent_outlined,
          title: l10n.settingsSupportEntry,
          subtitle: l10n.settingsSupportEntryHint,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
          ),
        ),
      ],
    );
  }
}

/// Entrada de lista da aba Ajustes (Segurança/Suporte) — ícone em círculo
/// tintado à esquerda, título + subtítulo e chevron à direita. Mesmo
/// idioma visual dos tiles do Menu e da referência de produto.
class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IconTone.darkBackground(scheme.primary),
            ),
            child: Icon(
              icon,
              size: 20,
              color: IconTone.lightForeground(scheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
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

    final storeName =
        stores.where((s) => s.id == employee.storeId).firstOrNull?.name ??
        employee.storeId;

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
          DetailRow(
            labelWidth: 70,
            padding: const EdgeInsets.symmetric(vertical: 5),
            label: l10n.employeeDetailEmail,
            value: employee.email,
            icon: Icons.email_outlined,
          ),
          DetailRow(
            labelWidth: 70,
            padding: const EdgeInsets.symmetric(vertical: 5),
            label: l10n.employeeDetailStore,
            value: storeName,
            icon: Icons.store_outlined,
          ),
          DetailRow(
            labelWidth: 70,
            padding: const EdgeInsets.symmetric(vertical: 5),
            label: l10n.employeeDetailRole,
            value: isManager ? l10n.roleManager : l10n.roleEmployee,
            icon: isManager
                ? Icons.manage_accounts_outlined
                : Icons.person_outline,
            valueColor: isManager ? scheme.primary : null,
          ),
          DetailRow(
            labelWidth: 70,
            padding: const EdgeInsets.symmetric(vertical: 5),
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
                        fontWeight: FontWeight.w600,
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
            DetailRow(
              labelWidth: 70,
              padding: const EdgeInsets.symmetric(vertical: 5),
              label: l10n.storeDetailPhone,
              value: store.phone,
              icon: Icons.phone_outlined,
            ),
          if (store.email.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              padding: const EdgeInsets.symmetric(vertical: 5),
              label: l10n.storeDetailEmail,
              value: store.email,
              icon: Icons.email_outlined,
            ),
          if (store.nuit.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              padding: const EdgeInsets.symmetric(vertical: 5),
              label: l10n.storeDetailNuit,
              value: store.nuit,
              icon: Icons.receipt_long_outlined,
            ),
          if (store.city.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              padding: const EdgeInsets.symmetric(vertical: 5),
              label: l10n.storeDetailCity,
              value: store.city,
              icon: Icons.location_city_outlined,
            ),
          if (store.address.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              padding: const EdgeInsets.symmetric(vertical: 5),
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

part of 'stores_screen.dart';

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
    final l10n = context.l10n;

    return SheetForm(
      formKey: _formKey,
      title: l10n.addStoreTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.addStoreSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
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
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _addressController,
              label: l10n.addStoreAddressLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              label: l10n.addStorePhoneLabel,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _emailController,
              label: l10n.addStoreEmailLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _cityController,
              label: l10n.addStoreCityLabel,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ],
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
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final storesAsync = ref.watch(storesProvider(widget.tenant.id));

    return SheetForm(
      formKey: _formKey,
      title: l10n.addEmployeeTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.addEmployeeSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
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
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.md),
        // Seção: Vínculo — loja e cargo.
        SheetSection(
          icon: Icons.work_outline,
          title: l10n.addEmployeeStoreLabel,
          children: [
            storesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(
                l10n.storesLoadError,
                style: AppTypography.bodySmall.copyWith(color: theme.expense),
              ),
              data: (stores) {
                if (stores.isEmpty) {
                  return Text(
                    l10n.addEmployeeNoStores,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                }
                return Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.addEmployeeRoleLabel,
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
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
                  onSelected: (_) => setState(() => _role = EmployeeRole.manager),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Sheet de edição de loja (nome, endereço, telefone, e-mail, NUIT, cidade).
class _EditStoreSheet extends ConsumerStatefulWidget {
  const _EditStoreSheet({required this.store});

  final Store store;

  @override
  ConsumerState<_EditStoreSheet> createState() => _EditStoreSheetState();
}

class _EditStoreSheetState extends ConsumerState<_EditStoreSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _nuitController;
  late final TextEditingController _cityController;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _addressController = TextEditingController(text: widget.store.address);
    _phoneController = TextEditingController(text: widget.store.phone);
    _emailController = TextEditingController(text: widget.store.email);
    _nuitController = TextEditingController(text: widget.store.nuit);
    _cityController = TextEditingController(text: widget.store.city);
  }

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

    final updated = widget.store.copyWith(
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
      await ref.read(updateStoreUseCaseProvider).call(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.editStoreSuccess(updated.name))),
      );
    } on InvalidStoreException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on TenantNotApprovedException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao editar loja');
      setState(() {
        _formError = l10n.editStoreError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SheetForm(
      formKey: _formKey,
      title: l10n.editStoreTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.editStoreSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
        SheetSection(
          icon: Icons.store_outlined,
          title: l10n.editStoreTitle,
          children: [
            AppTextField(
              controller: _nameController,
              label: l10n.addStoreNameLabel,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.addStoreNameError
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _addressController,
              label: l10n.addStoreAddressLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              label: l10n.addStorePhoneLabel,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _emailController,
              label: l10n.addStoreEmailLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _cityController,
              label: l10n.addStoreCityLabel,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ],
    );
  }
}

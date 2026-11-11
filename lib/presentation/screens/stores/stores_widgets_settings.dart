part of 'stores_screen.dart';

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
    final scheme = theme.colorScheme;
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
      // Chave estável para os testes rolarem até o rodapé (o botão Salvar
      // é o último elemento e a lista é lazy).
      key: const ValueKey('settingsTabList'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        AppSpacing.md,
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        AppSpacing.fabBottomClearance,
      ),
      children: [
        // MFA + FEEDBACK TÁTIL — switches de efeito IMEDIATO (salvam
        // sozinhos, sem passar pelo botão Salvar do rodapé).
        // P1 (MFA server-side): exigência de aal2 nas escritas de dinheiro
        // do tenant — persistida no SERVIDOR via update_tenant_settings.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _mfaEnforced,
          onChanged: (v) => unawaited(_toggleMfaEnforced(v)),
          title: Text(
            l10n.settingsMfaEnforceTitle,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _mfaEnforced
                ? l10n.settingsMfaEnforceSubOn
                : l10n.settingsMfaEnforceSubOff,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
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
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            l10n.settingsHapticsSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // LOJA ATIVA — só com 2+ lojas E usuário logado há o que escolher
        // (com uma única loja não existe seletor, o mesmo critério do
        // banner antigo). O guard `user != null` espelha a linha do
        // `activeStoreId` acima — sem `!` no callback.
        if (user != null && stores.length > 1) ...[
          Text(
            l10n.storeSelectorSectionTitle,
            style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final store in stores)
                ChoiceChip(
                  avatar: store.id == activeStoreId
                      ? const Icon(Icons.check, size: AppSizes.iconSm)
                      : null,
                  label: Text(store.name),
                  selected: store.id == activeStoreId,
                  onSelected: (_) => ref
                      .read(activeStoreIdProvider(user.id).notifier)
                      .select(store.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          l10n.onboardingLanguageLabel,
          style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.onboardingCurrencyLabel,
          style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xxl),
        // SEGURANÇA — troca de senha da conta (qualquer utilizador
        // logado; não é uma definição do tenant).
        Text(
          l10n.securitySectionTitle,
          style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l10n.settingsSupportSection,
          style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        _SettingsEntry(
          icon: Icons.support_agent_outlined,
          title: l10n.settingsSupportEntry,
          subtitle: l10n.settingsSupportEntryHint,
          // U-09: rota nomeada (SupportScreen via AppRoutes.support).
          onTap: () => AppNavigator.push(context, AppRoutes.support),
        ),
        const SizedBox(height: AppSpacing.xxl),
        // SALVAR — último elemento da aba (rodapé): persiste idioma +
        // moeda depois de todas as definições. O spinner substitui o
        // ícone durante o envio (design system ultra-clean).
        if (_formError != null) ...[
          Text(
            _formError!,
            style: AppTypography.bodySmall.copyWith(color: theme.expense),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppButton.primary(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  height: AppSizes.iconMd,
                  width: AppSizes.iconMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined, size: AppSizes.iconMd),
          label: l10n.settingsSave,
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
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarMd,
            height: AppSizes.avatarMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IconTone.darkBackground(scheme.primary),
            ),
            child: Icon(
              icon,
              size: AppSizes.iconMd,
              color: IconTone.lightForeground(scheme.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(
            Icons.chevron_right,
            size: AppSizes.iconMd,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../controllers/account_providers.dart';
import '../controllers/auth_providers.dart';
import 'app_menu_option.dart';

/// Seletor rápido de loja ativa — pílula compacta com menu popup.
class StoreSwitcher extends ConsumerWidget {
  const StoreSwitcher({super.key, this.hideWhenSingle = true});

  final bool hideWhenSingle;

  static const pillKey = ValueKey('storeSwitcherPill');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return const SizedBox.shrink();

    final stores = ref.watch(storesProvider(tenant.id)).value ?? const [];
    if (stores.isEmpty) return const SizedBox.shrink();

    final multiStore = stores.length > 1;
    if (!multiStore && hideWhenSingle) return const SizedBox.shrink();

    // Em listas (dashboard) o child estica para largura total — o Align
    // devolve à pílula o tamanho do conteúdo (esquerda), então o hit-test
    // cobre exatamente a pílula (sem "buraco" fora do texto).
    Widget aligned(Widget widget) =>
        Align(alignment: Alignment.centerLeft, child: widget);

    final activeStoreId = ref.watch(activeStoreIdProvider(user.id));
    final active = activeStoreId == null
        ? null
        : stores.where((store) => store.id == activeStoreId).firstOrNull;
    final activeName = active?.name ?? stores.first.name;

    // Seletor curto — MESMO tamanho e tipografia do seletor de período da
    // Home (labelLarge + chevron, sem caixa, sem ícone): só o nome da loja.
    // M3 (auditoria de a11y): o chevron decorativo é excluído da árvore de
    // semântica e a pílula expõe UM nó claro "Loja: X" — o leitor de tela
    // anuncia contexto em vez de um texto solto sem papel.
    final pill = Container(
      key: StoreSwitcher.pillKey,
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              activeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (multiStore) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (!multiStore) {
      return aligned(
        Semantics(
          label: l10n.storeSwitcherA11yLabel(activeName),
          excludeSemantics: true,
          child: pill,
        ),
      );
    }

    // Theme local: anula o hover/splash do InkWell INTERNO do
    // PopupMenuButton (que desenhava o realce ao pairar o mouse sobre a
    // pílula) — o menu em si segue com hover normal (aberto num overlay
    // com o tema global).
    final noHover = Theme(
      data: theme.copyWith(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      // Menu padronizado via AppMenuOption (itens 44px, bodySmall,
      // check leve na loja ativa, overlay chapado do popupMenuTheme).
      // A pílula multi-loja carrega a MESMA [pillKey] do branch de loja
      // única: testes e ferramentas encontram o widget nos dois casos
      // (regressão store_selector_test). O ConstrainedBox preserva o
      // maxWidth de 160 (ellipsis em nomes longos) que a pílula antiga
      // tinha — o AppMenuOption não impõe limite próprio.
      child: ConstrainedBox(
        key: StoreSwitcher.pillKey,
        constraints: const BoxConstraints(maxWidth: 160),
        child: AppMenuOption<String>(
          label: activeName,
          tooltip: l10n.storeSwitcherTooltip,
          options: [
            for (final store in stores)
              AppMenuOptionItem(
                value: store.id,
                label: store.name,
                checked: store.id == activeStoreId,
              ),
          ],
          onSelected: (storeId) =>
              ref.read(activeStoreIdProvider(user.id).notifier).select(storeId),
        ),
      ),
    );
    return aligned(noHover);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../domain/entities/store.dart';
import '../controllers/account_providers.dart';
import '../controllers/auth_providers.dart';

/// Seletor rápido de loja ativa para o app bar (multi-loja).
///
/// Pílula compacta com o nome da loja ativa; com 2+ lojas, tocar abre o
/// menu com todas as lojas do tenant (check na ativa). A troca chama
/// [ActiveStoreNotifier.select] — todos os módulos observam
/// [activeStoreIdProvider] e re-escopam na hora (mesma mecânica do seletor
/// de Lojas → Ajustes, agora sem sair da tela atual).
///
/// Sem usuário/tenant/lojas renderiza nada (SizedBox.shrink). Com UMA loja
/// e [hideWhenSingle] = true também não renderiza (não há o que escolher —
/// mesmo critério do seletor de Lojas → Ajustes); com `false`, exibe a
/// pílula NÃO-interativa (usado no cabeçalho do dashboard, que mostra o
/// nome da loja ativa mesmo com uma única loja).
class StoreSwitcher extends ConsumerWidget {
  const StoreSwitcher({super.key, this.hideWhenSingle = true});

  /// Quando `false`, renderiza a pílula mesmo com uma única loja (sem
  /// menu — apenas o nome da loja ativa).
  final bool hideWhenSingle;

  /// Chave da pílula — os testes localizam o seletor por ela.
  static const pillKey = ValueKey('storeSwitcherPill');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return const SizedBox.shrink();

    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    // Carregando/sem lojas: nada a exibir ainda.
    if (stores.isEmpty) return const SizedBox.shrink();

    final multiStore = stores.length > 1;
    if (!multiStore && hideWhenSingle) return const SizedBox.shrink();

    final activeStoreId = ref.watch(activeStoreIdProvider(user.id));
    final active = activeStoreId == null
        ? null
        : stores.where((store) => store.id == activeStoreId).firstOrNull;
    final activeName = active?.name ?? stores.first.name;

    // Pílula compacta (design system ultra-clean): superfície + borda sutil
    // + ícone da loja na cor primária; seta indica que há menu. Texto com
    // ellipsis e largura limitada — nunca estoura o app bar em telas
    // estreitas ou com escala de texto alta.
    final pill = Container(
      key: StoreSwitcher.pillKey,
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              activeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (multiStore) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    // Com uma única loja a pílula é apenas informativa (sem menu).
    if (!multiStore) return pill;

    return PopupMenuButton<String>(
      tooltip: l10n.storeSwitcherTooltip,
      onSelected: (storeId) =>
          ref.read(activeStoreIdProvider(user.id).notifier).select(storeId),
      itemBuilder: (context) => [
        for (final store in stores)
          PopupMenuItem<String>(
            value: store.id,
            child: Row(
              children: [
                Icon(
                  store.id == activeStoreId
                      ? Icons.check_circle
                      : Icons.storefront_outlined,
                  size: 18,
                  color: store.id == activeStoreId
                      ? theme.colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    store.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}

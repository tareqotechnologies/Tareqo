import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../domain/entities/store.dart';
import '../controllers/account_providers.dart';
import '../controllers/auth_providers.dart';

/// Barra de seleção de loja ativa (Fase 2 do multi-tenancy).
///
/// Exibida no topo das telas do AppShell quando o tenant tem mais de uma
/// loja: um chip por loja, com a loja ativa destacada. Tocar em outro chip
/// troca a loja ativa ([ActiveStoreNotifier.select]) — os providers de
/// produtos, vendas, financeiro, fiado, clientes e compras reagem
/// automaticamente (todos escopam por `activeStoreIdProvider`).
///
/// Com uma única loja, retorna `SizedBox.shrink()` (nada a selecionar).
class StoreSelectorBar extends ConsumerWidget {
  const StoreSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return const SizedBox.shrink();

    final storesAsync = ref.watch(storesProvider(tenant.id));
    final stores = storesAsync.value ?? const <Store>[];
    if (stores.length < 2) return const SizedBox.shrink();

    final activeStoreId = ref.watch(activeStoreIdProvider(user.id));
    final activeStore = activeStoreId == null
        ? null
        : stores.where((store) => store.id == activeStoreId).firstOrNull;

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final store in stores)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: store.id == activeStoreId
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        label: Text(store.name),
                        selected: store.id == activeStoreId,
                        onSelected: (_) => ref
                            .read(activeStoreIdProvider(user.id).notifier)
                            .select(store.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (activeStore != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: l10n.storeSelectorActiveTooltip,
                child: Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

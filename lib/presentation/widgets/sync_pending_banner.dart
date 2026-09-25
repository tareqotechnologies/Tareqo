import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../controllers/dashboard_providers.dart';
import 'app_card.dart';

/// Aparece no topo do conteúdo (todas as abas do shell) quando há operações
/// do caminho de dinheiro enfileiradas sem conexão
/// ([pendingOpsCountProvider] > 0) e some sozinho quando a fila esvazia.
///
/// Quando alguma operação falhou por NEGÓCIO no replay
/// ([failedOpsCountProvider] > 0), o texto distingue "N com erro" — é o
/// caso em que sincronizar NÃO resolve (dado rejeitado pelo servidor) e o
/// operador precisa revisar a operação, não apenas a conexão.
/// "Sincronizar" dispara o dreno imediato da fila.
class SyncPendingBanner extends ConsumerWidget {
  const SyncPendingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final count = ref.watch(pendingOpsCountProvider).value ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    final failed = ref.watch(failedOpsCountProvider).value ?? 0;

    return AppCard(
      color: theme.warning.withValues(alpha: 0.08),
      borderColor: theme.warning.withValues(alpha: 0.30),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: theme.warning.withValues(alpha: 0.9),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failed > 0
                  ? '${l10n.syncPendingCount(count)} · ${l10n.syncErrorsCount(failed)}'
                  : l10n.syncPendingCount(count),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _syncNow(context, ref),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(l10n.syncNow),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final sync = ref.read(offlineSyncServiceProvider);
    if (sync == null) return;
    final synced = await sync.drain();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          synced > 0 ? l10n.syncDone(synced) : l10n.syncStillOffline,
        ),
      ),
    );
  }
}

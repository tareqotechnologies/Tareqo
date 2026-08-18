import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../controllers/account_providers.dart';
import '../controllers/auth_providers.dart';

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
 fontWeight: FontWeight.w500,
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

 if (!multiStore) return aligned(pill);

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
 child: PopupMenuButton<String>(
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
 ? Icons.check_circle_rounded
 : Icons.storefront_outlined,
 size: 18,
 color: store.id == activeStoreId
 ? theme.colorScheme.primary
 : null,
 ),
 const SizedBox(width: AppSpacing.sm),
 Flexible(
 child: Text(store.name, overflow: TextOverflow.ellipsis),
 ),
 ],
 ),
 ),
 ],
 child: pill,
 ),
 );
 return aligned(noHover);
 }
}

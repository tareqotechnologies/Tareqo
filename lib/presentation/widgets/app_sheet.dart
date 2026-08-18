import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';

/// Abre uma bottom sheet V4 com animação suave e suporte fullscreen.
Future<T?> showAppSheet<T>(
 BuildContext context, {
 required WidgetBuilder builder,
 bool isDismissible = true,
 bool fullscreen = false,
}) {
 return showModalBottomSheet<T>(
 context: context,
 isScrollControlled: true,
 isDismissible: isDismissible,
 backgroundColor: Colors.transparent,
 builder: (context) {
 final scheme = Theme.of(context).colorScheme;
 return SafeArea(
 top: false,
 child: AnimatedPadding(
 duration: AppDurations.fast,
 padding: EdgeInsets.only(
 bottom: MediaQuery.viewInsetsOf(context).bottom,
 ),
 child: Container(
 decoration: BoxDecoration(
 color: scheme.surface,
 borderRadius: fullscreen
 ? BorderRadius.zero
 : const BorderRadius.vertical(top: Radius.circular(28)),
 border: fullscreen
 ? null
 : Border(
 top: BorderSide(color: scheme.outlineVariant),
 ),
 ),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (fullscreen)
 const Padding(
 padding: EdgeInsets.only(top: 10, bottom: 4),
 child: _SheetHandle(),
 )
 else
 const Padding(
 padding: EdgeInsets.only(top: 10, bottom: 6),
 child: _SheetHandle(),
 ),
 Flexible(
 child: fullscreen
 ? SizedBox(
 height: MediaQuery.sizeOf(context).height,
 child: builder(context),
 )
 : builder(context),
 ),
 ],
 ),
 ),
 ),
 );
 },
 );
}

class _SheetHandle extends StatelessWidget {
 const _SheetHandle();

 @override
 Widget build(BuildContext context) {
 return Container(
 width: 40,
 height: 4,
 decoration: BoxDecoration(
 color: Theme.of(context).colorScheme.outlineVariant,
 borderRadius: BorderRadius.circular(AppRadius.full),
 ),
 );
 }
}

/// Cabeçalho padrão das sheets V4.
class AppSheetHeader extends StatelessWidget {
 const AppSheetHeader({super.key, required this.title, this.subtitle});

 final String title;
 final String? subtitle;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Padding(
 padding: const EdgeInsets.fromLTRB(
 AppSpacing.xl,
 AppSpacing.xs,
 AppSpacing.sm,
 AppSpacing.xs,
 ),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(title, style: theme.textTheme.titleLarge),
 if (subtitle != null) ...[
 const SizedBox(height: 4),
 Text(
 subtitle!,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodySmall,
 ),
 ],
 ],
 ),
 ),
 IconButton(
 tooltip: context.l10n.appSheetClose,
 style: IconButton.styleFrom(
 backgroundColor: theme.colorScheme.surfaceContainerHighest,
 foregroundColor: theme.colorScheme.onSurfaceVariant,
 ),
 icon: const Icon(Icons.close, size: 18),
 onPressed: () => Navigator.of(context).pop(),
 ),
 ],
 ),
 );
 }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Folha de feed estilo Apple — um ÚNICO card elevado com as linhas
/// separadas por divisórias hairline, a mesma linguagem do feed
/// "Atividade de hoje" da Home. Replica o estilo da tela inicial nas
/// listas (Vendas, Movimentos, etc.): o contêiner é o card; cada linha
/// entra transparente e com padding de feed.
class FeedCard extends StatelessWidget {
 const FeedCard({super.key, required this.rows});

 final List<Widget> rows;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Material(
 color: theme.colorScheme.surfaceContainerHighest,
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(AppRadius.xl),
 side: BorderSide(
 color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
 ),
 ),
 clipBehavior: Clip.antiAlias,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 for (var i = 0; i < rows.length; i++) ...[
 if (i > 0)
 Divider(
 height: 1,
 indent: 60,
 endIndent: AppSpacing.md,
 color: theme.colorScheme.outlineVariant,
 ),
 rows[i],
 ],
 ],
 ),
 );
 }
}

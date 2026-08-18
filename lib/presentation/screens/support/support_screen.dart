import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../widgets/app_card.dart';
import 'doc_reader_screen.dart';

/// Ecrã Ajuda — hub do fluxo de suporte (Lojas → Ajustes → Suporte → Ajuda).
///
/// Lista os documentos embutidos (Guia do Usuário + Troubleshooting) e abre
/// cada um no leitor interno ([DocReaderScreen]) — leitura OFFLINE, sem
/// depender de internet ou de abrir o navegador.
class SupportScreen extends StatelessWidget {
 const SupportScreen({super.key});

 void _open(BuildContext context, SupportDocument document) {
 Navigator.of(context).push(
 MaterialPageRoute<void>(
 builder: (_) => DocReaderScreen(document: document),
 ),
 );
 }

 Widget _docTile(
 BuildContext context, {
 required SupportDocument document,
 required IconData icon,
 required String title,
 required String hint,
 }) {
 final theme = Theme.of(context);
 // Tile premium (estilo Apple): cantos 18, superfície elevada e ícone
 // em círculo pleno tintado — mesmo idioma das listas principais.
 return AppCard(
 elevated: true,
 borderRadius: const BorderRadius.all(Radius.circular(18)),
 onTap: () => _open(context, document),
 child: Row(
 children: [
 // Ícone circular tintado (estilo feed da Home).
 Container(
 width: 42,
 height: 42,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: theme.colorScheme.primaryContainer,
 ),
 child: Icon(icon, size: 22, color: theme.colorScheme.primary),
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: theme.textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 hint,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.35,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: 8),
 Icon(
 Icons.chevron_right,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ],
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão das demais telas.
 appBar: AppBar(
 title: Text(
 l10n.supportTitle,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w700,
 letterSpacing: -0.5,
 ),
 ),
 ),
 body: ListView(
 padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
 children: [
 Text(
 l10n.supportSubtitle,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.45,
 ),
 ),
 const SizedBox(height: 16),
 _docTile(
 context,
 document: SupportDocument.userGuide,
 icon: Icons.menu_book_outlined,
 title: l10n.supportUserGuide,
 hint: l10n.supportUserGuideHint,
 ),
 const SizedBox(height: 12),
 _docTile(
 context,
 document: SupportDocument.troubleshooting,
 icon: Icons.build_circle_outlined,
 title: l10n.supportTroubleshooting,
 hint: l10n.supportTroubleshootingHint,
 ),
 ],
 ),
 );
 }
}

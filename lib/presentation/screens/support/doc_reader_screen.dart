import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';

/// Documentos de suporte embutidos no app (assets) — os MESMOS markdowns de
/// `docs/`, empacotados para leitura OFFLINE no ecrã Ajuda. O asset é
/// escolhido pelo idioma ativo do dispositivo/tenant.
enum SupportDocument {
  userGuide,
  troubleshooting;

  /// Caminho do asset no idioma [languageCode] ('pt' | 'en'); qualquer
  /// outro idioma cai no português (idioma padrão do produto).
  String assetPath(String languageCode) {
    final en = languageCode == 'en';
    return switch (this) {
      SupportDocument.userGuide =>
        en ? 'docs/en/USER_GUIDE.md' : 'docs/pt/GUIA_DO_USUARIO.md',
      SupportDocument.troubleshooting =>
        en ? 'docs/en/TROUBLESHOOTING.md' : 'docs/pt/TROUBLESHOOTING.md',
    };
  }
}

/// Leitor de um documento de suporte (markdown embutido) — renderizado com
/// `flutter_markdown` no estilo do design system (cores do tema, sem HTML).
class DocReaderScreen extends StatefulWidget {
  const DocReaderScreen({super.key, required this.document});

  final SupportDocument document;

  @override
  State<DocReaderScreen> createState() => _DocReaderScreenState();
}

class _DocReaderScreenState extends State<DocReaderScreen> {
  // Cache por caminho de asset: `Localizations.localeOf(context)` só pode
  // ser consultado no BUILD (não no initState — dependOnInheritedWidget) e
  // não queremos recarregar o markdown a cada rebuild com o mesmo idioma.
  String? _cachedPath;
  Future<String>? _content;

  Future<String> _load(BuildContext context) {
    final path = widget.document
        .assetPath(Localizations.localeOf(context).languageCode);
    if (_cachedPath != path || _content == null) {
      _cachedPath = path;
      _content = rootBundle.loadString(path);
    }
    return _content!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document == SupportDocument.userGuide
              ? l10n.supportUserGuide
              : l10n.supportTroubleshooting,
        ),
      ),
      body: FutureBuilder<String>(
        future: _load(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.supportReadingError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            );
          }
          final scheme = theme.colorScheme;
          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
            // Links internos entre os documentos (GUIA ↔ TROUBLESHOOTING)
            // navegam DENTRO do leitor; http(s) abrem no navegador externo;
            // outros são ignorados (sem url_launcher sem contexto).
            onTapLink: (text, href, title) {
              if (href == null) return;
              if (href.startsWith('http')) {
                launchUrl(
                  Uri.parse(href),
                  mode: LaunchMode.externalApplication,
                );
                return;
              }
              final target = switch (href) {
                'GUIA_DO_USUARIO.md' || 'USER_GUIDE.md' =>
                  SupportDocument.userGuide,
                'TROUBLESHOOTING.md' => SupportDocument.troubleshooting,
                _ => null,
              };
              if (target != null && target != widget.document) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DocReaderScreen(document: target),
                  ),
                );
              }
            },
            styleSheet: MarkdownStyleSheet(
              h1: theme.textTheme.headlineMedium,
              h2: theme.textTheme.titleLarge,
              h3: theme.textTheme.titleMedium,
              p: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              blockquote: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
              ),
              strong: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              em: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              code: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              codeblockDecoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              tableHead: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              tableBody: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              tableBorder: TableBorder.all(color: scheme.outlineVariant),
              a: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                decoration: TextDecoration.underline,
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant, width: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

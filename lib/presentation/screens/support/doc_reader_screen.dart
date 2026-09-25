import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';

/// Documentos de suporte embutidos no app (assets) — os MESMOS markdowns de
/// `docs/`, empacotados para leitura OFFLINE no ecrã Ajuda. O asset é
/// escolhido pelo idioma ativo do dispositivo/tenant.
enum SupportDocument {
  userGuide,
  troubleshooting;

  /// Caminho do asset no idioma [languageCode] ('pt' | 'en' | 'fr');
  /// qualquer outro idioma cai no português (idioma padrão do produto).
  String assetPath(String languageCode) {
    final en = languageCode == 'en';
    final fr = languageCode == 'fr';
    return switch (this) {
      SupportDocument.userGuide =>
        en
            ? 'docs/en/USER_GUIDE.md'
            : fr
            ? 'docs/fr/GUIDE_DE_L_UTILISATEUR.md'
            : 'docs/pt/GUIA_DO_UTILIZADOR.md',
      SupportDocument.troubleshooting =>
        en
            ? 'docs/en/TROUBLESHOOTING.md'
            : fr
            ? 'docs/fr/DEPANNAGE.md'
            : 'docs/pt/TROUBLESHOOTING.md',
    };
  }
}

/// Leitor de um documento de suporte (markdown embutido) — renderizado com
/// `flutter_markdown_plus` no estilo do design system (cores do tema, sem HTML).
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
    final path = widget.document.assetPath(
      Localizations.localeOf(context).languageCode,
    );
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
                padding: const EdgeInsets.all(AppSpacing.xl),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, AppSpacing.huge),
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
                'GUIA_DO_UTILIZADOR.md' ||
                'USER_GUIDE.md' ||
                'GUIDE_DE_L_UTILISATEUR.md' => SupportDocument.userGuide,
                'TROUBLESHOOTING.md' ||
                'DEPANNAGE.md' => SupportDocument.troubleshooting,
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
              h1: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              h2: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h3: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h4: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h5: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              h6: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              // Corpo — entrelinha confortável para leitura longa.
              p: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.5,
                letterSpacing: 0.1,
              ),
              // Blockquotes (dicas Atenção://✓): fundo da MARCA com filete à
              // esquerda — antes usavam o padrão AZUL da biblioteca
              // (Colors.blue.shade100) que atrapalhava a leitura.
              blockquote: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
              blockquotePadding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              blockquoteDecoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border(
                  left: BorderSide(color: scheme.primary, width: 3),
                ),
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
              ),
              strong: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              em: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              // Código inline — chip discreto, texto com contraste.
              code: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              codeblockPadding: const EdgeInsets.all(AppSpacing.sm),
              codeblockDecoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              tableHead: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              tableBody: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              tableBorder: TableBorder.all(color: scheme.outlineVariant),
              // Hiperlinks — cor da marca, sublinhado suave, peso médio.
              a: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: scheme.primary.withValues(alpha: 0.55),
                decorationThickness: 1.2,
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

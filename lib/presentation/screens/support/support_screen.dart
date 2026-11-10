import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/support_config.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/search_field.dart';
import 'doc_reader_screen.dart';

/// Ecrã Ajuda — hub do fluxo de suporte (Lojas → Ajustes → Suporte → Ajuda).
///
/// Layout clonado da referência de produto:
/// * subtítulo explicativo logo abaixo do AppBar;
/// * campo de busca que filtra os tópicos em tempo real;
/// * tiles premium com ícone circular VERDE (mesmo idioma do feed da Home):
///   Guia do Usuário e Solução de problemas abrem o leitor interno
///   ([DocReaderScreen]) — leitura OFFLINE; Fale com o suporte abre o
///   WhatsApp com mensagem pré-preenchida;
/// * rodapé discreto "Central de ajuda" que abre o site no navegador.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Busca ────────────────────────────────────────────────────────────────

  /// Normaliza para comparação: minúsculas + sem acentos (pt/fr dos ARBs),
  /// para que "solucao" encontre "Solução".
  static String _normalize(String value) {
    const accented = 'áàâãéêíóôõúüçñ';
    const plain = 'aaaaeeiooouucn';
    return value.toLowerCase().split('').map((c) {
      final i = accented.indexOf(c);
      return i >= 0 ? plain[i] : c;
    }).join();
  }

  bool _matches(String title, String hint) {
    final q = _normalize(_query.trim());
    if (q.isEmpty) return true;
    return _normalize(title).contains(q) || _normalize(hint).contains(q);
  }

  // ── Navegação / links externos ──────────────────────────────────────────

  void _open(BuildContext context, SupportDocument document) {
    AppNavigator.pushWith(context, AppRoutes.docReader, {'document': document});
  }

  /// Abre um link externo (WhatsApp do suporte / site) no navegador; em caso
  /// de falha (sem app/navegador) mostra o erro com SnackBar — mesmo padrão
  /// das partilhas WhatsApp do app.
  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final l10n = context.l10n;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.supportOpenError)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.supportOpenError)));
      }
    }
  }

  void _contactSupport(BuildContext context) {
    final l10n = context.l10n;
    _launchExternal(
      context,
      // Número real do suporte (SupportConfig) com mensagem pré-preenchida.
      SupportConfig.whatsappUri(l10n.supportContactMessage),
    );
  }

  // ── Tiles ────────────────────────────────────────────────────────────────

  /// Tile premium da referência: card elevado (cantos 16), ícone em círculo
  /// pleno VERDE escuro com glifo claro, título w600 e hint discreto,
  /// chevron à direita.
  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String hint,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final accent = theme.accent;
    final scheme = theme.colorScheme;
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.lgAll,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.touchTarget,
            height: AppSizes.touchTarget,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IconTone.darkBackground(accent),
              // No escuro o círculo preto some sobre o cartão preto — o
              // hairline mantém a forma visível.
              border: theme.brightness == Brightness.dark
                  ? Border.all(color: PremiumDecor.hairline(scheme))
                  : null,
            ),
            child: Icon(
              icon,
              size: AppSizes.iconMd,
              color: IconTone.lightForeground(accent),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  hint,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right,
            size: AppSizes.iconMd,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  /// Rodapé discreto — pílula central "Central de ajuda" que abre o site.
  Widget _helpCenterFooter(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: InkWell(
        onTap: () => _launchExternal(context, Uri.parse('https://tareqo.app')),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.iconMd,
                height: AppSizes.iconMd,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.question_mark,
                  size: AppSizes.iconSm,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.supportHelpCenter,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    final topics = [
      (
        icon: Icons.menu_book_outlined,
        title: l10n.supportUserGuide,
        hint: l10n.supportUserGuideHint,
        onTap: () => _open(context, SupportDocument.userGuide),
      ),
      (
        icon: Icons.settings,
        title: l10n.supportTroubleshooting,
        hint: l10n.supportTroubleshootingHint,
        onTap: () => _open(context, SupportDocument.troubleshooting),
      ),
      (
        icon: Icons.headset_mic_outlined,
        title: l10n.supportContactSupport,
        hint: l10n.supportContactSupportHint,
        onTap: () => _contactSupport(context),
      ),
    ];
    final visible = topics.where((t) => _matches(t.title, t.hint)).toList();

    return AppPage(
      title: l10n.supportTitle,
      useSafeArea: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.xs,
          horizontal,
          AppSpacing.huge,
        ),
        children: [
          Text(
            l10n.supportSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SearchField(
            controller: _searchController,
            hintText: l10n.supportSearchHint,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.search_off,
              title: l10n.commonNoResults,
              subtitle: l10n.commonNoResultsHint,
            )
          else ...[
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _tile(
                context,
                icon: visible[i].icon,
                title: visible[i].title,
                hint: visible[i].hint,
                onTap: visible[i].onTap,
              ),
            ],
          ],
          // Rodapé apenas no estado completo (sem busca ativa) — a
          // referência o mantém ancorado no fim da página.
          if (_query.trim().isEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _helpCenterFooter(context),
          ],
        ],
      ),
    );
  }
}

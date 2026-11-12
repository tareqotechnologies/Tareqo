import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';

/// Tela exibida ao dono enquanto a solicitação de acesso aguarda a
/// aprovação manual do super admin (prazo de até 24h).
class TenantPendingScreen extends ConsumerWidget {
  const TenantPendingScreen({super.key, required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Estado "a aguardar": ícone-em-superfície neutro — o
                  // mesmo padrão das telas de estado, sem cor de acção.
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_top,
                      size: 32,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.tenantPendingTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.tenantPendingSubtitle(tenant.businessName),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.tenantPendingHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.secondary(
                    onPressed: () async {
                      await ref.read(signOutUseCaseProvider).call();
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: l10n.commonSignOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

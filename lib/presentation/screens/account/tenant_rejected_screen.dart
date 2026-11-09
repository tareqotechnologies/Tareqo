import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// Tela exibida ao dono quando a solicitação de acesso foi rejeitada pelo
/// super admin (com o motivo informado).
class TenantRejectedScreen extends ConsumerWidget {
  const TenantRejectedScreen({super.key, required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Estado "rejeitado": erro oficial (#C62828) em véu —
                // mesmo ícone-em-superfície da tela de pendência.
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.expense.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 32,
                    color: theme.expense,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.tenantRejectedTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tenantRejectedSubtitle(tenant.businessName),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (tenant.rejectionReason != null &&
                    tenant.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    color: scheme.errorContainer,
                    borderColor: theme.expense.withValues(alpha: 0.30),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            tenant.rejectionReason!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton.secondary(
                  onPressed: () async {
                    await ref.read(signOutUseCaseProvider).call();
                  },
                  icon: const Icon(Icons.logout),
                  label: l10n.commonSignOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

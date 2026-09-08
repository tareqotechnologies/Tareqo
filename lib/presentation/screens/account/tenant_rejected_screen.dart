import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
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
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 48,
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.tenantRejectedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tenantRejectedSubtitle(tenant.businessName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (tenant.rejectionReason != null &&
                    tenant.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    // Card premium (estilo Apple): cantos 18 + superfície
                    // elevada com fundo tingido pelo estado de erro.
                    elevated: true,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    color: scheme.errorContainer.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tenant.rejectionReason!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/premium_decor.dart';

/// Ecra de reconciliação de pagamentos mobile money — M-Pesa e E-Mola.
///
/// BLOCKED — DEPENDÊNCIA EXTERNA (API do provedor): o add-on
/// `ao_mobile_money` foi desactivado no catálogo porque a reconciliação
/// REAL exige a API do provedor de mobile money (M-Pesa/E-Mola), que não
/// existe neste projeto. Esta tela só é alcançável por instalações que
/// activaram o add-on ANTES do bloqueio — por isso mostra apenas o
/// estado honesto, nunca funcionalidade demonstrativa.
class PaymentReconciliationScreen extends ConsumerStatefulWidget {
  const PaymentReconciliationScreen({super.key});

  @override
  ConsumerState<PaymentReconciliationScreen> createState() =>
      _PaymentReconciliationScreenState();
}

class _PaymentReconciliationScreenState
    extends ConsumerState<PaymentReconciliationScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.paymentsTitle,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.md,
          horizontal,
          AppSpacing.xl,
        ),
        child: _IntegrationBlockedBanner(
          message: l10n.paymentsIntegrationBlocked,
        ),
      ),
    );
  }
}

/// Banner honesto: integração real ainda não existe (API externa).
class _IntegrationBlockedBanner extends StatelessWidget {
  const _IntegrationBlockedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      color: scheme.primaryContainer,
      borderColor: PremiumDecor.hairline(scheme),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.primary,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

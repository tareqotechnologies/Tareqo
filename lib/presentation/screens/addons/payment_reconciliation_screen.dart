import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_card.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentsTitle)),
      body: _IntegrationBlockedBanner(message: l10n.paymentsIntegrationBlocked),
    );
  }
}

/// Banner honesto: integração real ainda não existe (API externa).
class _IntegrationBlockedBanner extends StatelessWidget {
  const _IntegrationBlockedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = IconTone.amber;

    return SafeArea(
      top: false,
      child: AppCard(
        color: warning.withValues(alpha: 0.08),
        borderColor: warning.withValues(alpha: 0.30),
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: warning, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

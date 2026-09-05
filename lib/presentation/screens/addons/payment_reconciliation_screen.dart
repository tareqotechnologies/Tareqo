import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de reconciliação de pagamentos mobile money — M-Pesa e E-Mola.
class PaymentReconciliationScreen extends ConsumerStatefulWidget {
  const PaymentReconciliationScreen({super.key});

  @override
  ConsumerState<PaymentReconciliationScreen> createState() =>
      _PaymentReconciliationScreenState();
}

class _PaymentReconciliationScreenState
    extends ConsumerState<PaymentReconciliationScreen> {
  final List<_PaymentRecord> _payments = [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.paymentsTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ─── Aviso honesto ───
          // A reconciliação REAL exige a API do provedor de mobile money.
          // Até essa integração existir, os registos são locais/demonstrativos
          // e o add-on está marcado como indisponível no marketplace.
          _IntegrationBlockedBanner(
            message: l10n.paymentsIntegrationBlocked,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.phone_android_outlined,
                title: l10n.paymentsEmpty,
                subtitle: l10n.paymentsEmptySubtitle,
              ),
            )
          else ...[
            // ─── Resumo ───
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: l10n.paymentsStatusConfirmed,
                    value:
                        '${_payments.where((p) => p.status == _PaymentStatus.confirmed).length}',
                    color: IconTone.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MiniStat(
                    label: l10n.paymentsStatusPending,
                    value:
                        '${_payments.where((p) => p.status == _PaymentStatus.pending).length}',
                    color: ModuleColors.credit,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _MiniStat(
                    label: l10n.paymentsStatusRejected,
                    value:
                        '${_payments.where((p) => p.status == _PaymentStatus.rejected).length}',
                    color: IconTone.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Lista de transacções ───
            ..._payments.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _PaymentCard(
                  payment: payment,
                  onConfirm: () {
                    setState(() {
                      final idx = _payments.indexOf(payment);
                      _payments[idx] =
                          payment.copyWith(status: _PaymentStatus.confirmed);
                    });
                  },
                  onReject: payment.status == _PaymentStatus.pending
                      ? () {
                          setState(() {
                            final idx = _payments.indexOf(payment);
                            _payments[idx] =
                                payment.copyWith(status: _PaymentStatus.rejected);
                          });
                        }
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-payment',
        onPressed: _openNewPayment,
        tooltip: l10n.paymentsNewFab,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewPayment() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewPaymentSheet(
        onSave: (record) {
          setState(() => _payments.insert(0, record));
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Estado de reconciliação de um pagamento.
enum _PaymentStatus { pending, confirmed, rejected }

class _PaymentRecord {
  _PaymentRecord({
    required this.provider,
    required this.phone,
    required this.amountCents,
    required this.confirmationCode,
    required this.status,
    required this.date,
  });

  final String provider;
  final String phone;
  final int amountCents;
  final String confirmationCode;
  final _PaymentStatus status;
  final String date;

  _PaymentRecord copyWith({_PaymentStatus? status}) {
    return _PaymentRecord(
      provider: provider,
      phone: phone,
      amountCents: amountCents,
      confirmationCode: confirmationCode,
      status: status ?? this.status,
      date: date,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Componentes
// ═══════════════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onConfirm,
    this.onReject,
  });

  final _PaymentRecord payment;
  final VoidCallback onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isMpesa = payment.provider == 'M-Pesa';
    final providerColor = isMpesa ? IconTone.red : const Color(0xFF03754F);
    final l10n = context.l10n;

    final (statusColor, statusLabel) = switch (payment.status) {
      _PaymentStatus.confirmed =>
        (IconTone.green, l10n.paymentsStatusConfirmed),
      _PaymentStatus.rejected =>
        (IconTone.red, l10n.paymentsStatusRejected),
      _PaymentStatus.pending =>
        (ModuleColors.credit, l10n.paymentsStatusPending),
    };

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: IconTone.darkBackground(providerColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_android,
              size: 16,
              color: IconTone.lightForeground(providerColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      payment.provider,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  payment.phone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (payment.confirmationCode.isNotEmpty)
                  Text(
                    l10n.paymentsReference(payment.confirmationCode),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(payment.amountCents),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (payment.status == _PaymentStatus.pending) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onConfirm,
                  child: Text(
                    l10n.paymentsConfirm,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: IconTone.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onReject != null)
                  GestureDetector(
                    onTap: onReject,
                    child: Text(
                      l10n.paymentsReject,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: IconTone.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sheet: Registar Pagamento
// ═══════════════════════════════════════════════════════════════════════════════

class _NewPaymentSheet extends StatefulWidget {
  const _NewPaymentSheet({required this.onSave});

  final ValueChanged<_PaymentRecord> onSave;

  @override
  State<_NewPaymentSheet> createState() => _NewPaymentSheetState();
}

class _NewPaymentSheetState extends State<_NewPaymentSheet> {
  String _provider = 'M-Pesa';
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.paymentsSheetTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Seletor de provedor
            Row(
              children: [
                Expanded(
                  child: _ProviderButton(
                    label: 'M-Pesa',
                    color: IconTone.red,
                    isSelected: _provider == 'M-Pesa',
                    onTap: () => setState(() => _provider = 'M-Pesa'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ProviderButton(
                    label: 'E-Mola',
                    color: const Color(0xFF03754F),
                    isSelected: _provider == 'E-Mola',
                    onTap: () => setState(() => _provider = 'E-Mola'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              label: context.l10n.paymentsSenderPhone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _amountController,
              label: context.l10n.paymentsAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _confirmationController,
              label: context.l10n.paymentsConfirmationCode,
              prefixIcon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: context.l10n.paymentsConfirm,
              onPressed: _phoneController.text.trim().isNotEmpty &&
                      _amountController.text.trim().isNotEmpty
                  ? () {
                      // Montante em CENTAVOS com arredondamento (antes:
                      // toInt() truncava — 0,29 × 100 virava 28 cêntimos).
                      final amount =
                          (double.tryParse(_amountController.text) ?? 0) * 100;
                      if (amount <= 0) return;
                      widget.onSave(
                        _PaymentRecord(
                          provider: _provider,
                          phone: _phoneController.text.trim(),
                          amountCents: amount.round(),
                          confirmationCode:
                              _confirmationController.text.trim(),
                          status: _PaymentStatus.pending,
                          date: Formatters.date(DateTime.now()),
                        ),
                      );
                    }
                  : null,
            ),
          ],
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
    final theme = Theme.of(context);
    final warning = IconTone.amber;

    return AppCard(
      color: warning.withValues(alpha: 0.08),
      borderColor: warning.withValues(alpha: 0.30),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: warning,
            size: 20,
          ),
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
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

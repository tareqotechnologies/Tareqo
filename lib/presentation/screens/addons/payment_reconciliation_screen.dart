import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'M-Pesa / E-Mola',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _payments.isEmpty
          ? EmptyState(
              icon: Icons.phone_android_outlined,
              title: 'Sem transacções',
              subtitle:
                  'Registe pagamentos recebidos via\nM-Pesa ou E-Mola para reconciliação',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // ─── Resumo ───
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Confirmadas',
                        value:
                            '${_payments.where((p) => p.status == 'Confirmada').length}',
                        color: IconTone.green,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _MiniStat(
                        label: 'Pendentes',
                        value:
                            '${_payments.where((p) => p.status == 'Pendente').length}',
                        color: ModuleColors.credit,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _MiniStat(
                        label: 'Rejeitadas',
                        value:
                            '${_payments.where((p) => p.status == 'Rejeitada').length}',
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
                              payment.copyWith(status: 'Confirmada');
                        });
                      },
                      onReject: payment.status == 'Pendente'
                          ? () {
                              setState(() {
                                final idx = _payments.indexOf(payment);
                                _payments[idx] =
                                    payment.copyWith(status: 'Rejeitada');
                              });
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-payment',
        onPressed: _openNewPayment,
        tooltip: 'Registar Pagamento',
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
  final String status;
  final String date;

  _PaymentRecord copyWith({String? status}) {
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

    final (statusColor, statusLabel) = switch (payment.status) {
      'Confirmada' => (IconTone.green, 'Confirmada'),
      'Rejeitada' => (IconTone.red, 'Rejeitada'),
      _ => (ModuleColors.credit, 'Pendente'),
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
                    'Ref: ${payment.confirmationCode}',
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
              if (payment.status == 'Pendente') ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onConfirm,
                  child: Text(
                    'Confirmar',
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
                      'Rejeitar',
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
              'Registar Pagamento',
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
              label: 'Telefone do remetente',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _amountController,
              label: 'Valor (MT)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _confirmationController,
              label: 'Código de confirmação',
              prefixIcon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: 'Registar Pagamento',
              onPressed: _phoneController.text.trim().isNotEmpty &&
                      _amountController.text.trim().isNotEmpty
                  ? () {
                      final amount =
                          (double.tryParse(_amountController.text) ?? 0);
                      widget.onSave(
                        _PaymentRecord(
                          provider: _provider,
                          phone: _phoneController.text.trim(),
                          amountCents: (amount * 100).toInt(),
                          confirmationCode:
                              _confirmationController.text.trim(),
                          status: 'Pendente',
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

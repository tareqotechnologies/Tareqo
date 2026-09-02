import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
    final scheme = theme.colorScheme;

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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_android_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sem transacções',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Registe pagamentos recebidos via\nM-Pesa ou E-Mola para reconciliação automática',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Resumo
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Reconciliadas',
                        count: _payments
                            .where((p) => p.status == 'Confirmada')
                            .length
                            .toString(),
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Pendentes',
                        count: _payments
                            .where((p) => p.status == 'Pendente')
                            .length
                            .toString(),
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Lista de transacções
                ..._payments.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _PaymentCard(
                      payment: payment,
                      onConfirm: () {
                        setState(() {
                          final idx = _payments.indexOf(payment);
                          _payments[idx] = payment.copyWith(
                            status: 'Confirmada',
                          );
                        });
                      },
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
    required this.amount,
    required this.confirmationCode,
    required this.status,
    required this.date,
  });

  final String provider;
  final String phone;
  final String amount;
  final String confirmationCode;
  final String status;
  final String date;

  _PaymentRecord copyWith({String? status}) {
    return _PaymentRecord(
      provider: provider,
      phone: phone,
      amount: amount,
      confirmationCode: confirmationCode,
      status: status ?? this.status,
      date: date,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              count,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
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
    final providerColor = isMpesa
        ? const Color(0xFFDC2626)
        : const Color(0xFF03754F);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Provider badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: providerColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                Icons.phone_android,
                size: 20,
                color: providerColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        payment.provider,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: payment.status == 'Confirmada'
                              ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                              : const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          payment.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: payment.status == 'Confirmada'
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    payment.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (payment.confirmationCode.isNotEmpty)
                    Text(
                      'Ref: ${payment.confirmationCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payment.amount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                if (payment.status == 'Pendente') ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Text(
                        'Confirmar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (onReject != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: GestureDetector(
                        onTap: onReject,
                        child: Text(
                          'Rejeitar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
                    color: const Color(0xFFDC2626),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                      widget.onSave(
                        _PaymentRecord(
                          provider: _provider,
                          phone: _phoneController.text.trim(),
                          amount:
                              '${double.tryParse(_amountController.text) ?? 0} MT',
                          confirmationCode:
                              _confirmationController.text.trim(),
                          status: 'Pendente',
                          date: DateTime.now().toString().substring(0, 10),
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
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

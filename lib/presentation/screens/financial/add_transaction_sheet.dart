import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/domain_error_l10n.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_segmented_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/money_live_preview.dart';
import '../../../core/observability/crash_reporting.dart';

/// Bottom sheet para registrar uma transação financeira
/// (entrada/saída de caixa).
///
/// [initialType] pré-seleciona o tipo (ex.: o FAB central do shell abre
/// "Registrar despesa" já em [TransactionType.expense]).
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.income,
  });

  final TransactionType initialType;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();

  late TransactionType _type = widget.initialType;
  bool _isPending = false;
  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Interpreta o texto digitado como CENTAVOS inteiros (W4).
  int _parseAmount(String value) => Money.parse(value);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    // O movimento pertence à loja ativa (o caixa é por loja).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final transaction = FinancialTransaction(
      id: AppIds.newId('t'),
      storeId: storeId ?? 'st1',
      description: _descriptionController.text.trim(),
      amountCents: _parseAmount(_amountController.text),
      type: _type,
      category: _categoryController.text.trim().isEmpty
          ? (_type == TransactionType.income
                ? context.l10n.financialDefaultCategoryIncome
                : context.l10n.financialDefaultCategoryExpense)
          : _categoryController.text.trim(),
      date: DateTime.now(),
      status: _isPending ? TransactionStatus.pending : TransactionStatus.paid,
    );

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref.read(addTransactionUseCaseProvider).call(transaction);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.financialRegistered)));
    } on InvalidAmountException catch (error) {
      if (mounted) {
        setState(() => _formError = domainErrorMessage(error, l10n));
      }
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'financial_add_transaction',
      );
      if (mounted) {
        setState(() {
          _formError = l10n.financialRegisterError;
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SheetForm(
      formKey: _formKey,
      title: l10n.financialAddTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.financialRegister,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
        // Tipo — pílulas estilo Apple.
        SheetSection(
          children: [
            AppSegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.financialIncomingType),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.financialOutgoingType),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Dados — descrição, categoria, valor e estado.
        SheetSection(
          icon: Icons.edit_note_rounded,
          children: [
            AppTextField(
              controller: _descriptionController,
              label: l10n.financialDescriptionLabel,
              prefixIcon: Icons.edit_note_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.financialDescriptionError
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _categoryController,
              label: l10n.financialCategoryLabel,
              prefixIcon: Icons.tag_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _amountController,
              label: l10n.financialAmountLabel,
              prefixIcon: Icons.currency_exchange_rounded,
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => _parseAmount(value ?? '') <= 0
                  ? l10n.financialAmountError
                  : null,
            ),
            // A2: mostra ao vivo o valor que será registado.
            MoneyLivePreview(controller: _amountController),
            const SizedBox(height: AppSpacing.xs),
            // Pendente (fiado) — switch de efeito imediato, sem moldura
            // própria: o grupo já é a superfície.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.financialPendingLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  l10n.financialPendingHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isPending,
                activeThumbColor: theme.warning,
                onChanged: (value) => setState(() => _isPending = value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

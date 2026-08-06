import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../../core/observability/crash_reporting.dart';

/// Bottom sheet para registrar uma transação financeira
/// (entrada/saída de caixa).
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _type = TransactionType.income;
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
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao registrar transação',
      );
      setState(() {
        _formError = l10n.financialRegisterError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSheetHeader(title: l10n.financialAddTitle),
            SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.financialIncomingType),
                  icon: const Icon(Icons.south_west),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.financialOutgoingType),
                  icon: const Icon(Icons.north_east),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.financialDescriptionLabel,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.financialDescriptionError
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.financialCategoryLabel,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.financialAmountLabel,
                prefixIcon: const Icon(Icons.attach_money),
              ),
              validator: (value) => _parseAmount(value ?? '') <= 0
                  ? l10n.financialAmountError
                  : null,
            ),
            const SizedBox(height: 4),
            // Material explícito: o SwitchListTile pinta o fundo e o ink no
            // Material ancestral; dentro do Container colorido do app_sheet
            // (DecoratedBox) o Flutter emite a assertion "ListTile background
            // color or ink splashes may be invisible".
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.financialPendingLabel,
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l10n.financialPendingHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isPending,
                onChanged: (value) => setState(() => _isPending = value),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.financialRegister),
            ),
          ],
        ),
      ),
    );
  }
}

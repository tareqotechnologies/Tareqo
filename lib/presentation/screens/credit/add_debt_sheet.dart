import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/domain_error_l10n.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/usecases/add_debt_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/money_live_preview.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../data/services/offline_sync_service.dart';

/// Bottom sheet para registrar uma dívida ("fiado") de cliente.
///
/// Integração com o módulo de clientes: é possível **vincular** a dívida a
/// um cliente cadastrado (opcional). Ao selecionar, o nome é preenchido
/// automaticamente (snapshot em [Debt.personName] + vínculo via
/// [Debt.customerId]).
class AddDebtSheet extends ConsumerStatefulWidget {
  const AddDebtSheet({super.key});

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;
  String? _formError;

  /// Cliente vinculado (null = fiado sem vínculo).
  Customer? _customer;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Interpreta o texto digitado como CENTAVOS inteiros (W4).
  int _parseAmount(String value) => Money.parse(value);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: context.l10n.debtsDueDateHelp,
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _selectCustomer(Customer? customer) {
    setState(() {
      _customer = customer;
      // Snapshot do nome do cliente no campo (editável depois).
      if (customer != null) _nameController.text = customer.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    // O fiado pertence à loja ativa (cujo estoque/vendas estão na tela).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final debt = Debt(
      id: AppIds.newId('d'),
      storeId: storeId ?? 'st1',
      personName: _nameController.text.trim(),
      amountCents: _parseAmount(_amountController.text),
      dueDate: _dueDate,
      isCustomerDebt: true,
      customerId: _customer?.id,
    );

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      // O AddDebtUseCase registra a dívida E a pendência financeira
      // vinculada (debtId) — o livro reflete o fiado desde o início.
      await ref.read(addDebtUseCaseProvider).call(debt);
      // Confirmação tátil da conclusão (antes do pop: imediato, sem atraso)
      // — mesmo padrão das sheets de Vendas e Compras.
      Haptics.success();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtsRegisteredFor(debt.personName))),
      );
      // Fiado, Financeiro e KPIs mudaram — as telas recarregam.
      ref.invalidate(pendingDebtsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
    } on OfflineEnqueuedException {
      // Sem conexão: o fiado foi ENFILEIRADO (outbox) e será sincronizado.
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
    } on InvalidDebtAmountException catch (error) {
      Haptics.error();
      setState(() => _formError = domainErrorMessage(error, l10n));
    } on PendingEntryRegistrationException catch (error, stackTrace) {
      // A dívida foi registrada; apenas a pendência falhou. Não sugerir
      // nova tentativa (duplicaria o fiado): orienta a conferir o
      // Financeiro e recarrega o que já foi registrado.
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Fiado registrado sem pendência',
      );
      setState(() {
        _formError = l10n.debtsPendingEntryError;
      });
      ref.invalidate(pendingDebtsProvider);
    } catch (error, stackTrace) {
      Haptics.error();
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao registrar fiado',
      );
      setState(() {
        _formError = l10n.debtsRegisterError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final customersAsync = ref.watch(customersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.debtsAddDebt),
            // Seção: Cliente — seletor opcional vinculado ao módulo de clientes.
            customersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (customers) => customers.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SheetSection(
                        icon: Icons.people_outline,
                        title: l10n.debtsCustomerLinkLabel,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.debtsNoCustomer),
                                selected: _customer == null,
                                onSelected: (_) => _selectCustomer(null),
                              ),
                              for (final customer in customers)
                                ChoiceChip(
                                  label: Text(customer.name),
                                  selected: _customer?.id == customer.id,
                                  onSelected: (_) => _selectCustomer(customer),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
            // Seção: Dados da dívida — nome, valor e vencimento.
            SheetSection(
              icon: Icons.receipt_long_outlined,
              title: l10n.debtsAddDebt,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: l10n.debtsCustomerNameLabel,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.debtsCustomerNameError
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _amountController,
                  label: l10n.financialAmountLabel,
                  prefixIcon: Icons.attach_money,
                  // Teclado com separador decimal: o usuário consegue digitar
                  // "13,90" em vez de "1390" (que viraria 1.390,00).
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) => _parseAmount(value ?? '') <= 0
                      ? l10n.financialAmountError
                      : null,
                ),
                // A2: mostra ao vivo o valor que será registado — "1390"
                // aparece como 1.390,00 ANTES de salvar.
                MoneyLivePreview(controller: _amountController),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: AppRadius.mdAll,
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.debtsDueDateLabel,
                      prefixIcon: const Icon(Icons.event_outlined),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.date(_dueDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
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
            // AppButton (design system ultra-clean): altura 48, cantos 12,
            // cores sólidas — o spinner substitui o ícone durante o envio.
            AppButton.primary(
              onPressed: _isSubmitting ? null : _submit,
              label: l10n.debtsAddDebt,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

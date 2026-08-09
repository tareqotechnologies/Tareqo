import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/usecases/add_customer_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Tela de clientes — busca local, listagem com total de fiado pendente por
/// cliente e cadastro via bottom sheet. O fiado (módulo Crédito) vincula as
/// dívidas ao cliente via [Debt.customerId].
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    await showAppSheet<void>(
      context,
      builder: (_) => const _AddCustomerSheet(),
    );
    if (!mounted) return;
    ref.invalidate(customersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final debtsAsync = ref.watch(pendingDebtsProvider);
    final l10n = context.l10n;

    // Total de fiado pendente por cliente (para o chip no card) em
    // CENTAVOS inteiros (W4) — soma exata, sem Money.round2.
    final pendingByCustomer = <String, int>{};
    for (final debt in debtsAsync.value ?? const <Debt>[]) {
      final customerId = debt.customerId;
      if (customerId != null) {
        pendingByCustomer[customerId] =
            (pendingByCustomer[customerId] ?? 0) + debt.amountCents;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appNavCustomers)),
      // CTA único: sem clientes, o FAB some — o estado vazio traz o botão
      // "Novo cliente" centralizado.
      floatingActionButton: customersAsync.value?.isNotEmpty ?? false
          ? FloatingActionButton.extended(
              heroTag: 'fab-customers',
              onPressed: _openAddSheet,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.customersAddNew),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.customersSearchHint,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: l10n.customersLoadError,
                details: error.toString(),
                onRetry: () => ref.invalidate(customersProvider),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.customersEmptyTitle,
                    subtitle: l10n.customersEmptySubtitle,
                    // CTA único no estado vazio (o FAB some).
                    actionLabel: l10n.customersAddNew,
                    onAction: _openAddSheet,
                  );
                }

                final filtered = _query.isEmpty
                    ? customers
                    : customers
                          .where(
                            (customer) =>
                                customer.name.toLowerCase().contains(_query) ||
                                customer.phone.contains(_query) ||
                                customer.email.toLowerCase().contains(_query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: l10n.commonNoResults,
                    subtitle: l10n.commonNoResultsHint,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customersProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _CustomerTile(
                      customer: filtered[index],
                      pendingTotalCents:
                          pendingByCustomer[filtered[index].id] ?? 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card do cliente: avatar com inicial, nome, contatos e chip de fiado
/// pendente (se houver).
class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.pendingTotalCents,
  });

  final Customer customer;
  final int pendingTotalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final contacts = [
      if (customer.phone.isNotEmpty) customer.phone,
      if (customer.email.isNotEmpty) customer.email,
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                customer.name.isEmpty
                    ? '?'
                    : customer.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (contacts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contacts,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (pendingTotalCents > 0) ...[
              const SizedBox(width: 8),
              // Flexible: 'Fiado R\$ 1.234.567,89' encolhe (ellipsis) com
              // escala de texto alta em vez de estourar o card.
              Flexible(
                child: StatusChip(
                  label: l10n.customersCreditLabel(
                    Formatters.currency(pendingTotalCents),
                  ),
                  color: theme.colorScheme.tertiary,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de cadastro de cliente.
class _AddCustomerSheet extends ConsumerStatefulWidget {
  const _AddCustomerSheet();

  @override
  ConsumerState<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    // O cliente pertence à loja ativa (clientes são por loja).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final customer = Customer(
      id: AppIds.newId('c'),
      storeId: storeId ?? 'st1',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref.read(addCustomerUseCaseProvider).call(customer);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.customersAdded(customer.name))),
      );
    } on InvalidCustomerException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao cadastrar cliente',
      );
      setState(() {
        _formError = l10n.customersAddError;
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
            AppSheetHeader(title: l10n.customersAddNew),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.loginNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.customersNameError
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.customersPhoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.customersEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 14),
              Text(
                _formError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.customersAddSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

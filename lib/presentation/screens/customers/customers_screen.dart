import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/usecases/add_customer_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
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
 builder: (_) => const AddCustomerSheet(),
 );
 if (!mounted) return;
 ref.invalidate(customersProvider);
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
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

 // Contagem de clientes cadastrados (canvas: header com "N clientes").
 final customerCount = customersAsync.value?.length ?? 0;

 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão das demais telas.
 appBar: AppBar(
 toolbarHeight: 72,
 titleSpacing: 20,
 title: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 l10n.appNavCustomers,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.5,
 ),
 ),
 // Subtítulo do header — rótulo pequeno (design system: label).
 Text(
 l10n.customersHeaderCount(customerCount),
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 // CTA único: sem clientes, o FAB some — o estado vazio traz o botão
 // "Novo cliente" centralizado.
 floatingActionButton: customersAsync.value?.isNotEmpty ?? false
 // FAB circular (design system — igual ao "Novo produto"): o
 // canvas usa o ícone de adicionar pessoa (user-plus) — o gesto
 // "novo cliente" fica explícito, com tooltip.
 ? FloatingActionButton(
 heroTag: 'fab-customers',
 onPressed: _openAddSheet,
 tooltip: l10n.customersAddNew,
 child: const Icon(Icons.person_add_alt_1_outlined),
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
 // Skeleton no primeiro carregamento (padrão das listas).
 loading: () => const ListSkeleton(),
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

 // Query NORMALIZADO para minúsculas (mesmo padrão da busca
 // de Produtos): sem isso, digitar 'ANA' não achava 'ana'.
 final query = _query.toLowerCase();
 final filtered = _query.isEmpty
 ? customers
 : customers
 .where(
 (customer) =>
 customer.name.toLowerCase().contains(query) ||
 customer.phone.contains(query) ||
 customer.email.toLowerCase().contains(query),
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
 // Lista premium (V3): cards individuais com cantos 18 e
 // superfície elevada — mesmo padrão de Vendas/Produtos.
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

/// Iniciais do cliente para o avatar (ex.: "Ana Costa" → "AC") — até 2
/// letras, do primeiro e do último nome quando existem.
String _initials(String name) {
 final parts = name
 .trim()
 .split(RegExp(r'\s+'))
 .where((part) => part.isNotEmpty)
 .toList();
 if (parts.isEmpty) return '?';
 if (parts.length == 1) {
 return parts.first.substring(0, 1).toUpperCase();
 }
 return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
 .toUpperCase();
}

/// Card de cliente premium (V3): avatar com iniciais, nome + badge de
/// fiado pendente inline e contacto por baixo — cantos 18, superfície
/// elevada, como os cards de Vendas/Produtos.
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

 return Material(
 color: theme.colorScheme.surfaceContainerHighest,
 borderRadius: BorderRadius.circular(18),
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 child: Row(
 children: [
 CircleAvatar(
 radius: 20,
 backgroundColor: theme.colorScheme.surface,
 child: Text(
 _initials(customer.name),
 style: theme.textTheme.labelMedium?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Nome COMPLETO do cliente — quebra em linhas quando
 // necessário (nada de truncar nomes).
 Text(
 customer.name,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w500,
 ),
 ),
 if (contacts.isNotEmpty) ...[
 const SizedBox(height: 2),
 Text(
 contacts,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ],
 ),
 ),
 // Fiado pendente ANCORADO ao canto direito (estilo Home): a
 // pílula âmbar com o valor completo fica na borda, alinhada
 // verticalmente com o nome — mesmo padrão dos demais cards.
 if (pendingTotalCents > 0) ...[
 const SizedBox(width: 8),
 Flexible(
 child: Align(
 alignment: Alignment.centerRight,
 child: StatusChip(
 label: l10n.customersCreditLabel(
 Formatters.currency(pendingTotalCents),
 ),
 color: theme.warning,
 icon: Icons.receipt_long_outlined,
 ),
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
class AddCustomerSheet extends ConsumerStatefulWidget {
 const AddCustomerSheet({super.key});

 @override
 ConsumerState<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<AddCustomerSheet> {
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
 children: [        AppSheetHeader(title: l10n.customersAddNew),
        // Seção: Dados do cliente — nome, telefone e email.
        SheetSection(
          icon: Icons.person_outline,
          title: l10n.customersAddNew,
          children: [
            AppTextField(
              controller: _nameController,
              label: l10n.loginNameLabel,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.customersNameError
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneController,
              label: l10n.customersPhoneLabel,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: l10n.customersEmailLabel,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              // Email OPCIONAL — mas se preenchido, precisa ter formato
              // válido (emails inválidos não entram na base).
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return null;
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : l10n.loginEmailError;
              },
            ),
          ],
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
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // cores sólidas — o spinner substitui o ícone durante o envio.
 AppButton.primary(
 onPressed: _isSubmitting ? null : _submit,
 label: l10n.customersAddSubmit,
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

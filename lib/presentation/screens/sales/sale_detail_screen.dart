import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/cancel_sale_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/product_image.dart';
import '../../widgets/app_card.dart';
import '../../widgets/payment_filter.dart' show PaymentMethodIcon;
import '../../widgets/section_header.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';
import 'sale_receipt_share_sheet.dart';

/// Tela de detalhes de uma venda — itens expandidos com quantidade,
/// preço unitário e subtotal, além do total e da forma de pagamento.
///
/// Quando a venda está ativa e o usuário tem acesso gerencial
/// (dono/gerente — o servidor é a autoridade), oferece a ação
/// **Anular venda**: estorna o estoque aos lotes exatos, cria o estorno
/// no caixa e marca a venda como anulada no histórico (ela permanece
/// visível com o selo "Anulada", mas sai de relatórios e KPIs).
class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  /// Evita cliques repetidos durante a confirmação da anulação.
  bool _cancelling = false;

  Sale get sale => widget.sale;

  /// Loja ativa do usuário (nome/endereço para o recibo partilhado).
  ///
  /// Resolve o mesmo caminho do restante do app: usuário → tenant → lojas
  /// → seleção ativa. `null` enquanto os dados carregam (o recibo funciona
  /// sem cabeçalho de estabelecimento).
  Store? _activeStore() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return null;
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    return stores.where((store) => store.id == storeId).firstOrNull;
  }

  /// Abre o bottom sheet de partilha do recibo (visual + WhatsApp).
  void _openShareSheet(Store? store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SaleReceiptShareSheet(
        sale: sale,
        storeName: store?.name,
        storeAddress: (store?.address ?? '').isEmpty
            ? null
            : store?.address,
      ),
    );
  }

  /// Fluxo de anulação: confirmação → [CancelSaleUseCase] (estorno de
  /// estoque + caixa + status) → recarrega vendas, estoque, caixa e KPIs.
  Future<void> _confirmCancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saleDetailCancelConfirmTitle),
        content: Text(
          l10n.saleDetailCancelConfirmBody(
            Formatters.currency(sale.totalAmountCents),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          // AppButton.danger: vermelho sóbrio no diálogo de confirmação
          // (48px, cantos 12, w400 — medidas do design system).
          AppButton.danger(
            label: l10n.saleDetailCancelConfirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateProvider).value;
    final storeId =
        user == null ? null : ref.read(activeStoreIdProvider(user.id));
    if (storeId == null) return;

    setState(() => _cancelling = true);
    try {
      await ref
          .read(cancelSaleUseCaseProvider)
          .call(sale.id, storeId: storeId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleCancelledSuccess)),
      );
      // Vendas, estoque, caixa e KPIs mudaram — as telas recarregam.
      ref.invalidate(salesListProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
      Navigator.of(context).pop();
    } on SaleNotFoundException {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleNotFoundError)));
      ref.invalidate(salesListProvider);
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao anular venda');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleCancelError)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final itemsLabel = l10n.dashboardSaleItems(sale.items.length);
    // Apenas dono/gerente veem a ação de anular (a RPC também exige
    // is_manager_of_store no servidor — o app só orienta a UI).
    final canCancel = ref.watch(canCancelSalesProvider);
    final isCancelled = sale.status == SaleStatus.cancelled;
    // Loja ativa — alimenta o cabeçalho do recibo partilhado (nome e
    // endereço do estabelecimento; opcionais no recibo).
    final activeStore = _activeStore();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.saleDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ---------------------------------------------------------
          // Resumo: identificação, pagamento, data e total
          // ---------------------------------------------------------
          // AppCard (design system ultra-clean): radius 12, borda 0.5px,
          // flat — o resumo da venda segue o padrão dos demais cards.
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    children: [
                      // Ícone circular verde (design system 2026 — igual ao
                      // app de referência: círculo verde com recibo branco).
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          size: 22,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.saleDetailId(
                                Formatters.saleLabel(sale.number),
                              ),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$itemsLabel · '
                              '${Formatters.dateTime(sale.dateTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Venda anulada: selo próprio no lugar do pagamento (o
                  // estorno compensou a entrada original no caixa).
                  if (isCancelled)
                    StatusChip(
                      label: l10n.salesStatusCancelled,
                      color: theme.expense,
                      icon: Icons.block,
                    )
                  else
                    StatusChip(
                      label: sale.paymentMethod.labelFor(context.l10n),
                      color: theme.colorScheme.primary,
                      icon: sale.paymentMethod.icon,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.saleDetailTotalLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(sale.totalAmountCents),
                    style: isCancelled
                        ? theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          )
                        : theme.textTheme.headlineMedium,
                  ),
                  if (isCancelled && sale.cancelledAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.saleDetailCancelledAt} '
                      '${Formatters.dateTime(sale.cancelledAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: 8),
          // ---------------------------------------------------------
          // Itens: quantidade × preço unitário e subtotal
          // ---------------------------------------------------------
          // AppCard (design system ultra-clean): padding zero mantém o
          // espaçamento interno das linhas de item (14px próprios).
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < sale.items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                  _ItemRow(item: sale.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ---------------------------------------------------------
          // Total: card próprio (design system 2026 — 'Total' + valor)
          // ---------------------------------------------------------
          // AppCard (design system ultra-clean): radius 12, borda 0.5px,
          // flat — o card do total segue o padrão.
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
                children: [
                  Text(
                    l10n.saleDetailTotal,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  // SmartAmount: o total encolhe para SEMPRE caber.
                  Flexible(
                    child: SmartAmount(
                      cents: sale.totalAmountCents,
                      alignment: Alignment.centerRight,
                      style: isCancelled
                          ? theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              decoration: TextDecoration.lineThrough,
                            )
                          : theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ---------------------------------------------------------
          // Snapshot: preços congelados no momento da venda
          // ---------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.saleDetailSnapshot,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          // ---------------------------------------------------------
          // Ações: partilhar recibo (todos) e anular venda (dono/gerente,
          // apenas se ainda ativa)
          // ---------------------------------------------------------
          const SizedBox(height: 28),
          // Partilhar recibo: botão sólido verde (design system 2026).
          // AppButton ultra-clean: altura 48, cantos 12, texto w400.
          AppButton.primary(
            label: l10n.saleDetailShareAction,
            onPressed: () => _openShareSheet(activeStore),
            icon: const Icon(Icons.ios_share, size: 20),
          ),
          if (canCancel && !isCancelled) ...[
            const SizedBox(height: 12),
            // Anular venda: AppButton.secondary com contorno LARANJA +
            // lixeira (igual ao app de referência: ação destrutiva
            // secundária em laranja). A sobreposição só muda as CORES —
            // altura 48, cantos 12 e w400 vêm do outlinedButtonTheme.
            AppButton.secondary(
              label: l10n.saleDetailCancelAction,
              onPressed: _cancelling ? null : _confirmCancel,
              icon: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.warning,
                side: BorderSide(color: theme.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha de item: nome, `quantidade × preço unitário` e subtotal.
///
/// Consome [productsProvider] apenas para resolver a FOTO do produto
/// (por [SaleItem.productId]) — o nome/preço vêm do snapshot da venda.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // W11: quantidade em milésimos — subtotal com divisão inteira exata.
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    // Lookup da foto: usa o id estável (o produto pode ter sido
    // desativado/renomeado) — vazio = fallback de ícone.
    final imagePath = ref
            .watch(productsProvider)
            .value
            ?.where((p) => p.id == item.productId)
            .map((p) => p.imagePath)
            .firstOrNull ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Foto do produto (fallback: ícone) — imagem cadastrada.
          ProductImage(imagePath: imagePath, size: 42, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.currency(subtotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

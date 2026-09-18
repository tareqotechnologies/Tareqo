import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/ui/haptics.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/usecases/close_cash_register_use_case.dart';
import '../../../domain/usecases/get_cash_closing_summary_use_case.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/money_live_preview.dart';
import '../../widgets/smart_amount.dart';

/// Bottom sheet do FECHO DE CAIXA DIÁRIO (Z-report).
///
/// Mostra o resumo do dia (vendas por forma de pagamento, total e o
/// ESPERADO na gaveta — só dinheiro), pede a CONTAGEM FÍSICA do dinheiro
/// e calcula a diferença (sobra/falta/confere) antes de confirmar. A
/// confirmação persiste o fecho (UPSERT por loja + dia — refazer corrige
/// a contagem sem duplicar). Operação GERENCIAL: a entrada na tela só
/// aparece para dono/gerente e o servidor (RPC `close_cash_register`)
/// valida a guarda de novo.
class CashClosingSheet extends ConsumerStatefulWidget {
  const CashClosingSheet({super.key});

  @override
  ConsumerState<CashClosingSheet> createState() => _CashClosingSheetState();
}

class _CashClosingSheetState extends ConsumerState<CashClosingSheet> {
  final _countedController = TextEditingController();
  bool _isSubmitting = false;
  String? _formError;
  String? _successMessage;

  @override
  void dispose() {
    _countedController.dispose();
    super.dispose();
  }

  int _parseAmount(String value) => Money.parse(value);

  Future<void> _submit({required CashClosingSummary summary}) async {
    final countedCents = _parseAmount(_countedController.text);
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));
    if (storeId == null) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
      _successMessage = null;
    });

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final closing = await ref
          .read(closeCashRegisterUseCaseProvider)
          .call(
            storeId: storeId,
            day: summary.day,
            countedCashCents: countedCents,
          );
      if (!mounted) return;
      // Confirmação tátil do fecho (operação gerencial — imediato, sem
      // atraso): mesmo padrão das sheets de Vendas/Compras/Fiado.
      Haptics.success();
      setState(() {
        _isSubmitting = false;
        // Mostra o resultado persistido (o servidor é a autoridade no modo
        // SaaS — os valores exibidos vêm do retorno da RPC).
        _successMessage = summary.existingClosing == null
            ? l10n.cashClosingSuccess
            : l10n.cashClosingUpdated;
      });
      ref.invalidate(cashClosingSummaryProvider);
      ref.invalidate(cashClosingHistoryProvider);
      messenger.showSnackBar(SnackBar(content: Text(_successMessage!)));
      _prefillCounted(closing.expectedCashCents);
    } on InvalidCashCountException catch (error) {
      Haptics.error();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _formError = error.message;
        });
      }
    } catch (error, stackTrace) {
      Haptics.error();
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao fechar o caixa');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _formError = l10n.cashClosingError;
        });
      }
    }
  }

  /// Preenche o campo com o esperado na gaveta (atalho para quem confere
  /// — o usuário ajusta se houver sobra/falta). Formato SEM símbolo
  /// ("13.90") — o Money.parse aceita vírgula ou ponto, mesmo padrão do
  /// formulário de produto.
  void _prefillCounted(int expectedCents) {
    _countedController.text = Money.toReais(expectedCents).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(cashClosingSummaryProvider);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.cashClosingTitle),
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.cashClosingError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              data: (summary) {
                if (summary == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.cashClosingError),
                  );
                }
                return _buildContent(l10n, theme, summary);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    ThemeData theme,
    CashClosingSummary summary,
  ) {
    final isAlreadyClosed = summary.existingClosing != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAlreadyClosed) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n.cashClosingClosedAt} '
                    '${Formatters.dateTime(summary.existingClosing!.closedAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Resumo do dia: total, esperado na gaveta e diferença ao vivo.
        _SummaryCard(
          summary: summary,
          countedCents: _countedController.text.trim().isEmpty
              ? null
              : _parseAmount(_countedController.text),
        ),
        const SizedBox(height: 16),
        // Abertura por forma de pagamento (o Z).
        Text(l10n.cashClosingByMethod, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ByMethodBreakdown(summary: summary),
        const SizedBox(height: 20),
        // AppTextField (design system ultra-clean): o botão de auto-refresh
        // (suffixIcon) preenche com o esperado; a borda acende no foco.
        AppTextField(
          controller: _countedController,
          label: l10n.cashClosingCountedCash,
          prefixIcon: Icons.payments_outlined,
          textInputAction: TextInputAction.done,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: l10n.cashClosingCountedCashHint,
          errorText: _formError,
          suffixIcon: IconButton(
            tooltip: l10n.cashClosingExpectedCash,
            icon: const Icon(Icons.autorenew),
            onPressed: () => _prefillCounted(summary.expectedCashCents),
          ),
          onChanged: (_) => setState(() {}),
        ),
        // A2: mostra ao vivo a contagem que será registada — "1390" aparece
        // como 1.390,00 ANTES de confirmar o fecho.
        MoneyLivePreview(controller: _countedController),
        const SizedBox(height: 16),
        // AppButton (design system ultra-clean): altura 48, cantos 12,
        // cores sólidas — o spinner substitui o ícone durante o envio.
        AppButton.primary(
          onPressed: _isSubmitting ? null : () => _submit(summary: summary),
          icon: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock_clock_outlined),
          label: isAlreadyClosed
              ? l10n.cashClosingUpdate
              : l10n.cashClosingConfirm,
        ),
        if (_successMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _successMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Card do resumo do dia: total de vendas, esperado na gaveta e a
/// diferença ao vivo (confere/sobra/falta) conforme a contagem digitada.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.countedCents});

  final CashClosingSummary summary;
  final int? countedCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final difference = countedCents == null
        ? null
        : countedCents! - summary.expectedCashCents;
    final (Color color, IconData icon, String label) = difference == null
        ? (
            theme.colorScheme.onSurfaceVariant,
            Icons.edit_note_outlined,
            l10n.cashClosingCountedCashHint,
          )
        : switch (difference) {
            == 0 => (
              theme.colorScheme.primary,
              Icons.check_circle_outline,
              l10n.cashClosingConfers,
            ),
            > 0 => (
              theme.colorScheme.tertiary,
              Icons.trending_up,
              l10n.cashClosingSurplus(Formatters.currency(difference)),
            ),
            _ => (
              theme.colorScheme.error,
              Icons.trending_down,
              l10n.cashClosingShortage(Formatters.currency(difference.abs())),
            ),
          };

    // AppCard (design system ultra-clean): radius 12, borda 0.5px #222E35,
    // flat — o resumo do dia segue o padrão dos demais cards.
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cashClosingDaySummary, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _row(theme, l10n.cashClosingTotalSales, summary.totalSalesCents),
          const SizedBox(height: 8),
          _row(
            theme,
            l10n.cashClosingExpectedCash,
            summary.expectedCashCents,
            emphasize: true,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.cashClosingExpectedCashHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    int cents, {
    bool emphasize = false,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        // SmartAmount (design system ultra-clean): auto-size — o valor em
        // CENTAVOS encolhe para nunca estourar o card, mesmo com valores
        // grandes ou escala de texto alta.
        SmartAmount(
          cents: cents,
          alignment: Alignment.centerRight,
          style: emphasize
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                )
              : theme.textTheme.titleSmall,
        ),
      ],
    );
  }
}

/// Abertura do dia por forma de pagamento (o Z do Z-report) — valores em
/// centavos formatados; formas sem vendas não aparecem.
class _ByMethodBreakdown extends StatelessWidget {
  const _ByMethodBreakdown({required this.summary});

  final CashClosingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (summary.salesByMethodCents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.cashClosingEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in summary.salesByMethodCents.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _methodIcon(entry.key),
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _methodLabel(l10n, entry.key),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                // SmartAmount (design system ultra-clean): auto-size do
                // valor por forma (o Z) — encolhe em telas estreitas.
                SmartAmount(
                  cents: entry.value,
                  alignment: Alignment.centerRight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _methodIcon(String methodName) => switch (methodName) {
    'cash' => Icons.payments_outlined,
    'mPesa' => Icons.phone_android,
    'eMola' => Icons.phone_android,
    'debitCard' || 'creditCard' => Icons.credit_card,
    'transfer' => Icons.swap_horiz,
    _ => Icons.receipt_long_outlined,
  };

  String _methodLabel(AppLocalizations l10n, String methodName) {
    final method = PaymentMethod.values.asNameMap()[methodName];
    return method == null ? methodName : method.labelFor(l10n);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_lot.dart';
import '../../domain/usecases/get_stock_lots_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';
import 'products_providers.dart';

/// Janela de aviso de validade (W11): lotes com vencimento em MENOS de
/// [expiryWarningDays] dias entram no alerta AMARELO do dashboard; lotes
/// já vencidos (com estoque) entram no VERMELHO. Constante nomeada para
/// ajuste central sem literais espalhados.
const int expiryWarningDays = 30;

/// Ponte entre o ServiceLocator e o Riverpod para o caso de uso de lotes.
final getStockLotsUseCaseProvider = Provider<GetStockLotsUseCase>(
  (ref) => ServiceLocator.instance<GetStockLotsUseCase>(),
);

/// Alerta de validade de um LOTE com estoque, no contexto do produto.
final class ExpiryAlert {
  const ExpiryAlert({
    required this.product,
    required this.lot,
    required this.daysRemaining,
  });

  final Product product;
  final StockLot lot;

  /// Dias até o vencimento (NEGATIVO = lote já vencido; 0 = vence hoje).
  final int daysRemaining;

  /// Vermelho: lote com estoque já VENCIDO.
  bool get isExpired => daysRemaining < 0;

  /// Amarelo: vence em menos de [expiryWarningDays] dias (pode estar
  /// vencido — o vermelho tem precedência na ordenação/UI).
  bool get isExpiring => daysRemaining < expiryWarningDays;
}

/// Alertas de validade do dashboard:
///
/// Lê os lotes ATIVOS da loja (que ainda têm estoque), casa com o
/// catálogo e classifica por urgência — vencidos primeiro (vermelho) e
/// depois os que vencem em menos de [expiryWarningDays] dias (amarelo).
final expiryAlertsProvider =
    AsyncNotifierProvider<ExpiryAlertsNotifier, List<ExpiryAlert>>(
      ExpiryAlertsNotifier.new,
    );

class ExpiryAlertsNotifier extends AsyncNotifier<List<ExpiryAlert>> {
  @override
  Future<List<ExpiryAlert>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];

    final lots = await ref
        .watch(getStockLotsUseCaseProvider)
        .getByStore(storeId: storeId);
    if (lots.isEmpty) return const [];

    final products = await ref.watch(productsProvider.future);
    final productsById = {for (final product in products) product.id: product};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final alerts = <ExpiryAlert>[];
    for (final lot in lots) {
      final expiry = lot.expiryDate;
      // Lotes sem validade nunca disparam alerta.
      if (expiry == null) continue;
      final days = DateTime(
        expiry.year,
        expiry.month,
        expiry.day,
      ).difference(today).inDays;
      // Vencido OU vencendo em menos de expiryWarningDays dias. Produto
      // DESATIVADO não alerta (não vende — o estoque dele não está em
      // rotação; alertar seria ruído).
      if (days < 0 || days < expiryWarningDays) {
        final product = productsById[lot.productId];
        if (product == null || !product.isActive) continue;
        alerts.add(
          ExpiryAlert(product: product, lot: lot, daysRemaining: days),
        );
      }
    }

    // Vencidos (vermelho) primeiro; entre iguais, vencimento mais próximo.
    alerts.sort((a, b) {
      if (a.isExpired != b.isExpired) return a.isExpired ? -1 : 1;
      return a.lot.expiryDate!.compareTo(b.lot.expiryDate!);
    });
    return alerts;
  }

  /// Recarrega os alertas (ex.: pull-to-refresh do dashboard).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

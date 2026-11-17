import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/quantity.dart';
import '../../domain/entities/product.dart';
import 'expiry_alerts_provider.dart';
import 'products_providers.dart';

enum BusinessAlertType { outOfStock, lowStock, expired, expiring }

/// An active, actionable inventory alert derived from the current store data.
/// It remains visible until the underlying stock or expiry condition changes.
final class BusinessAlert {
  const BusinessAlert({
    required this.type,
    required this.product,
    required this.quantity,
    this.expiryDate,
    this.daysRemaining,
  });

  final BusinessAlertType type;
  final Product product;
  final int quantity;
  final DateTime? expiryDate;
  final int? daysRemaining;
}

final businessAlertsProvider = FutureProvider<List<BusinessAlert>>((ref) async {
  final products = await ref.watch(productsProvider.future);
  final expiryAlerts = await ref.watch(expiryAlertsProvider.future);

  final alerts = <BusinessAlert>[];
  for (final product in products) {
    if (!product.isActive) continue;
    if (product.stockQuantity <= 0) {
      alerts.add(
        BusinessAlert(
          type: BusinessAlertType.outOfStock,
          product: product,
          quantity: product.stockQuantity,
        ),
      );
    } else if (product.stockQuantity <
        Quantity.lowStockThresholdUnits * Quantity.milliFactor) {
      alerts.add(
        BusinessAlert(
          type: BusinessAlertType.lowStock,
          product: product,
          quantity: product.stockQuantity,
        ),
      );
    }
  }

  // A product can have several expiring lots. Keep only its most urgent lot
  // in the inbox; opening the product takes the user to the full lot details.
  final expiryByProduct = <String, ExpiryAlert>{};
  for (final alert in expiryAlerts) {
    expiryByProduct.putIfAbsent(alert.product.id, () => alert);
  }
  for (final alert in expiryByProduct.values) {
    alerts.add(
      BusinessAlert(
        type: alert.isExpired
            ? BusinessAlertType.expired
            : BusinessAlertType.expiring,
        product: alert.product,
        quantity: alert.lot.currentQuantity,
        expiryDate: alert.lot.expiryDate,
        daysRemaining: alert.daysRemaining,
      ),
    );
  }

  alerts.sort((a, b) {
    int priorityOf(BusinessAlertType type) => switch (type) {
      BusinessAlertType.outOfStock || BusinessAlertType.expired => 0,
      BusinessAlertType.lowStock => 1,
      BusinessAlertType.expiring => 2,
    };

    final priority = priorityOf(a.type).compareTo(priorityOf(b.type));
    if (priority != 0) return priority;
    final expiryA = a.expiryDate;
    final expiryB = b.expiryDate;
    if (expiryA != null && expiryB != null) return expiryA.compareTo(expiryB);
    return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
  });
  return alerts;
});

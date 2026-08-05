import 'package:freezed_annotation/freezed_annotation.dart';

import 'sale_item.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

/// Formas de pagamento aceitas no ERP.
enum PaymentMethod {
  cash('Dinheiro'),
  debitCard('Cartão de débito'),
  creditCard('Cartão de crédito'),
  pix('Pix'),
  transfer('Transferência');

  const PaymentMethod(this.label);

  /// Rótulo exibido na UI (a serialização JSON usa o nome do enum).
  final String label;
}

/// Entidade de domínio que representa uma venda registrada.
@freezed
abstract class Sale with _$Sale {
  const factory Sale({
    required String id,
    // Loja onde a venda foi realizada (Fase 2 do multi-tenancy). Cada
    // loja tem seu próprio histórico de vendas.
    @Default('st1') String storeId,
    required List<SaleItem> items,
    required double totalAmount,
    required PaymentMethod paymentMethod,
    required DateTime dateTime,
  }) = _Sale;

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'sale_item.dart';

part 'sale.freezed.dart';
part 'sale.g.dart';

/// Formas de pagamento aceitas no ERP.
///
/// Mercado-alvo: Moçambique — o dinheiro móvel local (M-Pesa e E-Mola)
/// substituiu o Pix (BR). O nome do enum é o valor persistido no banco
/// (migração antiga: 'pix' → 'mPesa').
enum PaymentMethod {
  cash('Dinheiro'),
  debitCard('Cartão de débito'),
  creditCard('Cartão de crédito'),
  mPesa('M-Pesa'),
  eMola('E-Mola'),
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
    // Número SEQUENCIAL da venda DENTRO da loja (ex.: S-00001, S-00002).
    // Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
    // transação; Supabase: RPC process_sale com advisory lock por loja.
    // O default 0 nunca é persistido (é substituído na gravação).
    @Default(0) int number,
    // Loja onde a venda foi realizada (Fase 2 do multi-tenancy). Cada
    // loja tem seu próprio histórico de vendas.
    @Default('st1') String storeId,
    required List<SaleItem> items,
    // Valor TOTAL da venda em CENTAVOS inteiros (W4 — migração de
    // dinheiro para centavos; o banco persiste BIGINT/INTEGER).
    required int totalAmountCents,
    required PaymentMethod paymentMethod,
    required DateTime dateTime,
  }) = _Sale;

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}

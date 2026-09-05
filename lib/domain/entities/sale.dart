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

/// Situação de uma venda no histórico.
///
/// Toda venda nasce [SaleStatus.active]; ao ser anulada (operação de
/// nível gerencial — dono/gerente), passa a [SaleStatus.cancelled] com
/// [Sale.cancelledAt] preenchido. Vendas anuladas permanecem no histórico
/// (trilha de auditoria), mas são ignoradas por relatórios, KPIs e pelo
/// resumo do dia — o estoque dos itens volta aos lotes exatos e a entrada
/// no caixa é estornada com um movimento de saída.
enum SaleStatus {
 active('Ativa'),
 cancelled('Anulada');

 const SaleStatus(this.label);

 /// Rótulo exibido na UI (a serialização JSON usa o nome do enum).
 final String label;
}

/// Entidade de domínio que representa uma venda registrada.
@freezed
abstract class Sale with _$Sale {  const factory Sale({
 required String id,
 // Número SEQUENCIAL da venda DENTRO da loja (ex.: S-00001, S-00002).
 // Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
 // transação; Supabase: RPC process_sale com advisory lock por loja.
 // O default 0 nunca é persistido (é substituído na gravação).
 @Default(0) int number,
 // Loja onde a venda foi realizada (Fase 2 do multi-tenancy). Cada
 // loja tem seu próprio histórico de vendas.
 @Default('st1') String storeId,
 // Caixa (funcionário) que registrou a venda — UUID do usuário
 // autenticado. No Supabase a coluna `user_id` é preenchida pelo
 // trigger `set_tenant_user_id` (auth.uid()); localmente é carimbada
 // pelo fluxo de venda. Usada pelo add-on de gestão de funcionários
 // para calcular COMISSÕES e progresso de METAS a partir das vendas
 // reais. Vazio = venda legada sem atribuição (não conta para
 // comissões, nunca gera números falsos).
 @Default('') String userId,
 required List<SaleItem> items,
 // Valor TOTAL da venda em CENTAVOS inteiros (W4 — migração de
 // dinheiro para centavos; o banco persiste BIGINT/INTEGER).
 required int totalAmountCents,
 required PaymentMethod paymentMethod,
 required DateTime dateTime,
 // Situação no histórico: [SaleStatus.active] ao registrar; ao ser
 // anulada, [SaleStatus.cancelled] + [cancelledAt] preenchido. Default
 // 'active' preserva a leitura de vendas antigas (bancos sem a coluna
 // de status) e os testes existentes.
 @Default(SaleStatus.active) SaleStatus status,
 // Momento em que a venda foi anulada (null enquanto ativa).
 DateTime? cancelledAt,
 }) = _Sale;

 factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
}

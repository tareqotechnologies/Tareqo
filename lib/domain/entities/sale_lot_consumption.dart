/// Consumo de um LOTE em uma venda (registro para a anulação exata).
///
/// Quando uma venda é processada, cada item abate o estoque dos lotes em
/// ordem FIFO (validade mais próxima primeiro). Este registro guarda a
/// "fotografia" de QUAIS lotes foram abatidos e em QUE quantidade — é o
/// que permite à anulação da venda devolver o estoque aos MESMOS lotes,
/// preservando as datas de validade e o custo de cada lote.
///
/// Gravado na mesma transação da venda (tabela `sale_lot_consumption`
/// no SQLite/Supabase ou em memória no modo web) e consumido pelo
/// [CancelSaleUseCase] na anulação.
final class LotConsumption {
 const LotConsumption({
 required this.lotId,
 required this.productId,
 required this.quantity,
 });

 /// Lote de origem que foi abatido.
 final String lotId;

 /// Produto dono do lote (necessário para devolver o total do produto).
 final String productId;

 /// Quantidade abatida, em MILÉSIMOS de unidade (W11).
 final int quantity;

 @override
 bool operator ==(Object other) =>
 other is LotConsumption &&
 other.lotId == lotId &&
 other.productId == productId &&
 other.quantity == quantity;

 @override
 int get hashCode => Object.hash(lotId, productId, quantity);

 @override
 String toString() =>
 'LotConsumption(lotId: $lotId, productId: $productId, quantity: $quantity)';
}

import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../local/sale_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [SaleLocalDataSource] sobre o Supabase.
///
/// A venda e seus itens são gravados em **uma única requisição** usando o
/// insert aninhado do PostgREST (a FK `sale_items.sale_id → sales.id` faz o
/// vínculo automaticamente; `defaultToNull: false` deixa o `id` serial e as
/// colunas com default no banco). O RLS isola os dados por tenant.
///
/// ⚠️ O método [add] não é atômico (cada chamada REST é uma transação
/// isolada). Por isso o caminho de vendas do Supabase usa [processSale],
/// que delega a função RPC `process_sale` (`SECURITY DEFINER`) — venda +
/// itens + baixa de estoque + entrada no caixa em UMA transação do banco.
final class SaleSupabaseDataSourceImpl implements SaleLocalDataSource {
  const SaleSupabaseDataSourceImpl();

  static const _table = 'sales';

  /// Processa a venda **atomicamente** no servidor (RPC `process_sale`).
  ///
  /// O RPC valida e trava o estoque (`FOR UPDATE`), grava venda + itens,
  /// baixa o estoque e lança a entrada no caixa — tudo em uma única
  /// transação, com `auth.uid()` no servidor. Lança exceção se o estoque
  /// for insuficiente ou se o total não corresponder aos itens.
  Future<void> processSale(Sale sale) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    await supabaseClient.rpc('process_sale', params: {
      'p_sale': {
        'id': sale.id,
        'store_id': sale.storeId,
        'total_amount': sale.totalAmount,
        'payment_method': sale.paymentMethod.name,
        'date_time': sale.dateTime.toUtc().toIso8601String(),
      },
      'p_items': [
        for (final item in sale.items)
          {
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          },
      ],
    });
  }

  @override
  Future<List<Sale>> getAll({required String storeId}) async {
    // Embedded resource: itens vêm junto na mesma resposta.
    final rows = await supabaseClient
        .from(_table)
        .select('*, sale_items(*)')
        .eq('store_id', storeId)
        .order('date_time', ascending: false);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(Sale sale) async {
    final userId = requireCurrentUserId();
    await supabaseClient.from(_table).insert({
      'id': sale.id,
      'user_id': userId,
      'store_id': sale.storeId,
      'total_amount': sale.totalAmount,
      'payment_method': sale.paymentMethod.name,
      'date_time': sale.dateTime.toUtc().toIso8601String(),
      'sale_items': [
        for (final item in sale.items)
          {
            'user_id': userId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
          },
      ],
    }, defaultToNull: false);
  }

  Sale _map(Map<String, dynamic> row) => Sale(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        items: [
          for (final item in (row['sale_items'] as List<dynamic>? ?? const []))
            _mapItem(item as Map<String, dynamic>),
        ],
        totalAmount: (row['total_amount'] as num).toDouble(),
        paymentMethod:
            PaymentMethod.values.byName(row['payment_method'] as String),
        dateTime: DateTime.parse(row['date_time'] as String).toLocal(),
      );

  SaleItem _mapItem(Map<String, dynamic> row) => SaleItem(
        productId: row['product_id'] as String,
        productName: row['product_name'] as String,
        quantity: (row['quantity'] as num).toInt(),
        unitPrice: (row['unit_price'] as num).toDouble(),
      );
}

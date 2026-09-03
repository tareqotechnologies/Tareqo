import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/data/datasources/remote/supabase_sale_data_source.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';

/// Teste de CONTRATO da RPC atômica `process_sale` do datasource remoto de
/// vendas — verifica o payload EXATO enviado ao servidor (venda + itens em
/// centavos, método de pagamento pelo nome do enum, data em UTC ISO) via
/// seam `rpc` injetável, e que erros do servidor propagam como estão.
void main() {
 group('SaleSupabaseDataSourceImpl.processSale (RPC process_sale)', () {
 test('chama a RPC com venda, itens e totais em centavos', () async {
 final dateTime = DateTime.utc(2026, 8, 7, 14, 30);
 final sale = Sale(
 id: 's1',
 storeId: 'st1',
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Arroz',
 quantity: 2,
 unitPriceCents: 3500,
 ),
 SaleItem(
 productId: 'p2',
 productName: 'Feijão',
 quantity: 1,
 unitPriceCents: 2800,
 ),
 ],
 totalAmountCents: 9800,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: dateTime,
 );

 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 expect(fn, 'process_sale');
 expect(params['p_sale'], {
 'id': 's1',
 'store_id': 'st1',
 'total_amount': 9800,
 'payment_method': 'mPesa',
 'date_time': dateTime.toUtc().toIso8601String(),
 });
 expect(params['p_items'], [
 {
 'product_id': 'p1',
 'product_name': 'Arroz',
 'quantity': 2,
 'unit_price': 3500,
 },
 {
 'product_id': 'p2',
 'product_name': 'Feijão',
 'quantity': 1,
 'unit_price': 2800,
 },
 ]);
 return null;
 }

 final ds = SaleSupabaseDataSourceImpl(rpc: rpc);

 await ds.processSale(sale);
 });

 test('PostgrestException da RPC propaga como está (sem tradução)',
 () async {
 final sale = Sale(
 id: 's1',
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Arroz',
 quantity: 5,
 unitPriceCents: 1000,
 ),
 ],
 totalAmountCents: 5000,
 paymentMethod: PaymentMethod.cash,
 dateTime: DateTime(2026, 8, 7),
 );

 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Estoque insuficiente para o produto Arroz.',
 code: 'P0001',
 );
 }

 final ds = SaleSupabaseDataSourceImpl(rpc: rpc);

 await expectLater(
 ds.processSale(sale),
 throwsA(
 isA<PostgrestException>().having(
 (error) => error.message,
 'message',
 contains('Estoque insuficiente'),
 ),
 ),
 );
 });
 });
}

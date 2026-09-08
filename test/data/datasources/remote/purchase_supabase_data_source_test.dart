import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/data/datasources/remote/supabase_purchase_data_source.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';

/// Teste de CONTRATO da RPC atômica `process_purchase` do datasource remoto
/// de compras — verifica o payload EXATO enviado ao servidor (compra +
/// itens em centavos, fornecedor, método de pagamento pelo nome do enum,
/// data em UTC ISO) via seam `rpc` injetável, e que erros do servidor
/// propagam como estão.
void main() {
  group(
    'PurchaseSupabaseDataSourceImpl.processPurchase (RPC process_purchase)',
    () {
      test('chama a RPC com compra, itens e totais em centavos', () async {
        final dateTime = DateTime.utc(2026, 8, 8, 9, 15);
        final purchase = Purchase(
          id: 'c1',
          storeId: 'st1',
          supplierName: 'Fornecedor A',
          items: const [
            PurchaseItem(
              productId: 'p1',
              productName: 'Arroz',
              quantity: 10,
              unitPriceCents: 2800,
            ),
            PurchaseItem(
              productId: 'p3',
              productName: 'Óleo',
              quantity: 5,
              unitPriceCents: 1500,
            ),
          ],
          totalAmountCents: 35500,
          paymentMethod: PaymentMethod.transfer,
          dateTime: dateTime,
        );

        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          expect(fn, 'process_purchase');
          expect(params['p_purchase'], {
            'id': 'c1',
            'store_id': 'st1',
            'supplier_name': 'Fornecedor A',
            'total_amount': 35500,
            'payment_method': 'transfer',
            'date_time': dateTime.toUtc().toIso8601String(),
          });
          expect(params['p_items'], [
            {
              'product_id': 'p1',
              'product_name': 'Arroz',
              'quantity': 10,
              'unit_price': 2800,
              // W11: validade opcional do lote FIFO (null = sem validade).
              'expiry_date': null,
            },
            {
              'product_id': 'p3',
              'product_name': 'Óleo',
              'quantity': 5,
              'unit_price': 1500,
              'expiry_date': null,
            },
          ]);
          return null;
        }

        final ds = PurchaseSupabaseDataSourceImpl(rpc: rpc);

        await ds.processPurchase(purchase);
      });

      test(
        'PostgrestException da RPC propaga como está (sem tradução)',
        () async {
          final purchase = Purchase(
            id: 'c1',
            supplierName: 'Fornecedor A',
            items: const [
              PurchaseItem(
                productId: 'x',
                productName: 'Produto inexistente',
                quantity: 1,
                unitPriceCents: 1000,
              ),
            ],
            totalAmountCents: 1000,
            paymentMethod: PaymentMethod.cash,
            dateTime: DateTime(2026, 8, 8),
          );

          Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
            throw PostgrestException(
              message: 'Produto não encontrado no catálogo.',
              code: 'P0001',
            );
          }

          final ds = PurchaseSupabaseDataSourceImpl(rpc: rpc);

          await expectLater(
            ds.processPurchase(purchase),
            throwsA(
              isA<PostgrestException>().having(
                (error) => error.message,
                'message',
                contains('Produto não encontrado'),
              ),
            ),
          );
        },
      );
    },
  );
}

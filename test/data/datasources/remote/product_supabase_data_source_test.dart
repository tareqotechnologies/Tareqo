import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:dumbhanengue/data/datasources/remote/supabase_product_data_source.dart';

/// Teste de CONTRATO da RPC `adjust_product_stock` do datasource remoto de
/// produtos — verifica o payload EXATO enviado ao servidor (id do produto,
/// loja e a nova quantidade ABSOLUTA em milésimos) via seam `rpc`
/// injetável, e que erros do servidor propagam como estão.
void main() {
  group('ProductSupabaseDataSourceImpl.adjustStock (RPC adjust_product_stock)',
      () {
    test('chama a RPC com produto, loja e a nova quantidade', () async {
      Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
        expect(fn, 'adjust_product_stock');
        expect(params, {
          'p_product_id': 'p1',
          'p_store_id': 'st1',
          'p_new_quantity': 7500,
        });
        return null;
      }

      final ds = ProductSupabaseDataSourceImpl(rpc: rpc);

      await ds.adjustStock('p1', 7500, storeId: 'st1');
    });

    test('PostgrestException da RPC propaga como está (sem tradução)',
        () async {
      Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
        throw PostgrestException(
          message: 'Apenas o dono ou um gerente podem ajustar o estoque.',
          code: 'P0001',
        );
      }

      final ds = ProductSupabaseDataSourceImpl(rpc: rpc);

      await expectLater(
        ds.adjustStock('p1', 5000, storeId: 'st1'),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.message,
            'message',
            contains('gerente'),
          ),
        ),
      );
    });
  });
}

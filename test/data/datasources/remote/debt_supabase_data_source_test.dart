import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/data/datasources/remote/supabase_debt_data_source.dart';
import 'package:tareqo/domain/entities/debt.dart';

/// Teste de CONTRATO das RPCs atômicas do datasource remoto de fiado:
/// `settle_debt` e `register_debt` — verifica os payloads exatos enviados
/// ao servidor (via seam `rpc` injetável, mesmo padrão do
/// `SupabaseEmployeeProcessor`) e que os erros do servidor propagam como
/// estão (o datasource não engole nem traduz — a autoridade é a RPC).
void main() {
  group('DebtSupabaseDataSourceImpl (RPCs atômicas)', () {
    test('settleDebt chama a RPC settle_debt com dívida e loja', () async {
      Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
        expect(fn, 'settle_debt');
        expect(params, {'p_debt_id': 'd1', 'p_store': 'st1'});
        return null;
      }

      final ds = DebtSupabaseDataSourceImpl(rpc: rpc);

      await ds.settleDebt('d1', storeId: 'st1');
    });

    test(
      'registerDebt chama a RPC register_debt com o payload completo',
      () async {
        final dueDate = DateTime.utc(2026, 8, 15, 10);
        final debt = Debt(
          id: 'd1',
          storeId: 'st1',
          personName: 'João',
          amountCents: 15000,
          dueDate: dueDate,
          isCustomerDebt: true,
          customerId: 'c1',
        );

        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          expect(fn, 'register_debt');
          expect(params['p_debt'], {
            'id': 'd1',
            'store_id': 'st1',
            'person_name': 'João',
            'amount': 15000,
            'due_date': dueDate.toUtc().toIso8601String(),
            'is_customer_debt': true,
            'customer_id': 'c1',
          });
          return null;
        }

        final ds = DebtSupabaseDataSourceImpl(rpc: rpc);

        await ds.registerDebt(debt);
      },
    );

    test(
      'registerDebt omite customer_id quando a dívida não tem cliente',
      () async {
        final debt = Debt(
          id: 'd2',
          personName: 'Sem cliente',
          amountCents: 5000,
          dueDate: DateTime(2026, 8, 15),
          isCustomerDebt: false,
        );

        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          expect(fn, 'register_debt');
          expect(params['p_debt'].containsKey('customer_id'), isFalse);
          return null;
        }

        final ds = DebtSupabaseDataSourceImpl(rpc: rpc);

        await ds.registerDebt(debt);
      },
    );

    test(
      'PostgrestException da RPC propaga como está (sem tradução)',
      () async {
        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          throw PostgrestException(
            message: 'Dívida não encontrada para a loja informada.',
            code: 'P0001',
          );
        }

        final ds = DebtSupabaseDataSourceImpl(rpc: rpc);

        await expectLater(
          ds.settleDebt('x', storeId: 'st1'),
          throwsA(
            isA<PostgrestException>().having(
              (error) => error.message,
              'message',
              contains('Dívida não encontrada'),
            ),
          ),
        );
      },
    );
  });
}

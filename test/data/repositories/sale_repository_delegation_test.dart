import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/repositories/sale_repository_impl.dart';
import 'package:tareqo/data/datasources/local/sale_local_data_source.dart';
import 'package:tareqo/data/services/supabase_debt_processor.dart';
import 'package:tareqo/data/datasources/remote/supabase_debt_data_source.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';

/// DataSource falso que grava as chamadas — o [SaleRepositoryImpl] é um
/// delegador puro; o contrato é "todo método chega ao datasource com os
/// MESMOS argumentos" (o teste prova a passagem, não a persistência).
class _RecordingSaleDataSource implements SaleLocalDataSource {
  final List<({String method, String id, String storeId})> calls = [];

  @override
  Future<List<Sale>> getAll({required String storeId}) async {
    calls.add((method: 'getAll', id: '', storeId: storeId));
    return [];
  }

  @override
  Future<Sale?> getById(String id, {required String storeId}) async {
    calls.add((method: 'getById', id: id, storeId: storeId));
    return null;
  }

  @override
  Future<void> add(Sale sale) async {
    calls.add((method: 'add', id: sale.id, storeId: sale.storeId));
  }

  @override
  Future<void> markCancelled(String id, {required String storeId}) async {
    calls.add((method: 'markCancelled', id: id, storeId: storeId));
  }

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) async {
    calls.add((method: 'getLotConsumption', id: saleId, storeId: storeId));
    return [];
  }

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) async {
    calls.add((method: 'registerLotConsumption', id: saleId, storeId: storeId));
  }
}

void main() {
  group('SaleRepositoryImpl — delegação completa do contrato', () {
    test('registerSale chega ao datasource com a MESMA venda', () async {
      final ds = _RecordingSaleDataSource();
      final repo = SaleRepositoryImpl(ds);
      final sale = _sale();

      await repo.registerSale(sale);

      expect(ds.calls.single.method, 'add');
      expect(ds.calls.single.id, 's-001');
      expect(ds.calls.single.storeId, 'st-1');
    });

    test(
      'getAll e getById preservam o storeId (isolamento por loja)',
      () async {
        final ds = _RecordingSaleDataSource();
        final repo = SaleRepositoryImpl(ds);

        await repo.getAll(storeId: 'st-9');
        await repo.getById('s-x', storeId: 'st-9');

        expect(ds.calls[0], (method: 'getAll', id: '', storeId: 'st-9'));
        expect(ds.calls[1], (method: 'getById', id: 's-x', storeId: 'st-9'));
      },
    );

    test(
      'markCancelled preserva o escopo da loja (defesa em profundidade)',
      () async {
        final ds = _RecordingSaleDataSource();
        final repo = SaleRepositoryImpl(ds);

        await repo.markCancelled('s-42', storeId: 'st-2');

        expect(ds.calls.single, (
          method: 'markCancelled',
          id: 's-42',
          storeId: 'st-2',
        ));
      },
    );

    test(
      'consumo de lotes: leitura e registro delegam com o saleId certo',
      () async {
        final ds = _RecordingSaleDataSource();
        final repo = SaleRepositoryImpl(ds);

        await repo.getLotConsumption('s-7', storeId: 'st-1');
        await repo.registerLotConsumption('s-7', 'st-1', const []);

        expect(ds.calls[0].method, 'getLotConsumption');
        expect(ds.calls[0].id, 's-7');
        expect(ds.calls[1].method, 'registerLotConsumption');
        expect(ds.calls[1].id, 's-7');
        expect(ds.calls[1].storeId, 'st-1');
      },
    );
  });

  group('SupabaseDebtProcessor — delegação às RPCs atômicas', () {
    test(
      'register chama register_debt com o payload exato da dívida',
      () async {
        final debt = Debt(
          id: 'd-001',
          personName: 'Maria Fiado',
          amountCents: 12500,
          dueDate: DateTime(2026, 9, 30, 12, 0),
          isCustomerDebt: true,
          customerId: 'c-1',
        );
        Map<String, dynamic>? payload;
        final processor = SupabaseDebtProcessor(
          DebtSupabaseDataSourceImpl(
            rpc: (fn, params) async {
              expect(fn, 'register_debt');
              payload = Map<String, dynamic>.from(params['p_debt'] as Map);
              return null;
            },
          ),
        );

        await processor.register(debt);

        // O payload é o mapa de COLUNAS do Postgres (contrato da RPC
        // register_debt) — nenhum campo da dívida se perde no caminho.
        expect(payload!['id'], 'd-001');
        expect(payload!['store_id'], 'st1');
        expect(payload!['person_name'], 'Maria Fiado');
        expect(payload!['amount'], 12500);
        expect(payload!['is_customer_debt'], isTrue);
        expect(payload!['customer_id'], 'c-1');
        expect(
          DateTime.parse(payload!['due_date'] as String),
          DateTime(2026, 9, 30, 12, 0).toUtc(),
        );
      },
    );

    test(
      'register SEM customerId omite a chave (coluna fica NULL no banco)',
      () async {
        final debt = Debt(
          id: 'd-002',
          personName: 'João Avulso',
          amountCents: 900,
          dueDate: DateTime(2026, 10, 10),
          isCustomerDebt: false,
        );
        Map<String, dynamic>? payload;
        final processor = SupabaseDebtProcessor(
          DebtSupabaseDataSourceImpl(
            rpc: (fn, params) async {
              payload = Map<String, dynamic>.from(params['p_debt'] as Map);
              return null;
            },
          ),
        );

        await processor.register(debt);

        expect(payload!.containsKey('customer_id'), isFalse);
        expect(payload!['is_customer_debt'], isFalse);
      },
    );

    test('settle chama settle_debt com o id e a loja exatos', () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final processor = SupabaseDebtProcessor(
        DebtSupabaseDataSourceImpl(
          rpc: (fn, params) async {
            calls.add((fn, params));
            return null;
          },
        ),
      );

      await processor.settle('d-77', storeId: 'st-3');

      expect(calls.single.$1, 'settle_debt');
      expect(calls.single.$2['p_debt_id'], 'd-77');
      expect(calls.single.$2['p_store'], 'st-3');
    });
  });
}

Sale _sale() => Sale.fromJson(const {
  'id': 's-001',
  'storeId': 'st-1',
  'number': 1,
  'totalAmountCents': 1500,
  'paymentMethod': 'cash',
  'status': 'active',
  'dateTime': '2026-09-01T10:00:00.000Z',
  'items': <Map<String, dynamic>>[],
});

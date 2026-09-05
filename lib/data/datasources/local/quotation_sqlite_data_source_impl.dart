import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/quotation.dart';
import 'quotation_local_data_source.dart';

/// Implementação SQLite do [QuotationLocalDataSource].
///
/// Tabela `quotations` (v4): a cotação é um DOCUMENTO por loja — o corpo
/// completo (items snapshot, estado, desconto, validade) é guardado como
/// JSON numa única linha, com número sequencial dentro da loja (`MAX+1`
/// na transação; `UNIQUE(store_id, quotation_number)` garante que duas
/// cotações concorrentes nunca recebem o mesmo número).
final class QuotationSqliteDataSourceImpl implements QuotationLocalDataSource {
  const QuotationSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, quotation_number, payload, created_at';

  @override
  Future<List<Quotation>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM quotations WHERE store_id = ? '
      'ORDER BY created_at DESC, quotation_number DESC',
      [storeId],
    );
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<Quotation> add(Quotation quotation) async {
    var persisted = quotation;
    AppDatabase.runInTransaction(_db, () {
      // Mesma semântica dos demais datasources: id duplicado é um erro
      // de domínio (StateError) — espelha a PK do banco sem vazar a
      // exceção crua do SQLite para a UI.
      final exists = _db
          .select('SELECT 1 FROM quotations WHERE id = ?', [quotation.id])
          .isNotEmpty;
      if (exists) {
        throw StateError('Cotação ${quotation.id} já existe.');
      }
      // Número SEQUENCIAL da loja: MAX+1 calculado DENTRO da transação
      // (mesmo padrão das vendas/facturas) — o número enviado no objeto é
      // ignorado: o banco é a autoridade. O UNIQUE(store_id,
      // quotation_number) é a rede de segurança contra corridas.
      final nextNumber = _db
          .select(
            'SELECT COALESCE(MAX(quotation_number), 0) + 1 AS next '
            'FROM quotations WHERE store_id = ?',
            [quotation.storeId],
          )
          .first['next'] as int;

      persisted = quotation.copyWith(number: nextNumber);
      _db.execute(
        'INSERT INTO quotations '
        '(id, store_id, quotation_number, payload, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          persisted.id,
          persisted.storeId,
          persisted.number,
          jsonEncode(persisted.toJson()),
          persisted.createdAt.millisecondsSinceEpoch,
        ],
      );
    });
    return persisted;
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    final rows = _db.select(
      'SELECT $_columns FROM quotations WHERE id = ?',
      [quotation.id],
    );
    if (rows.isEmpty) {
      throw StateError('Cotação ${quotation.id} não existe.');
    }
    final persisted = quotation.copyWith(
      number: (rows.first['quotation_number'] as num).toInt(),
    );
    AppDatabase.runInTransaction(_db, () {
      _db.execute(
        'UPDATE quotations SET payload = ? WHERE id = ?',
        [jsonEncode(persisted.toJson()), persisted.id],
      );
    });
    return persisted;
  }

  Quotation _map(Row row) {
    final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    final quotation = Quotation.fromJson(json);
    return quotation.copyWith(
      number: (row['quotation_number'] as num).toInt(),
    );
  }
}
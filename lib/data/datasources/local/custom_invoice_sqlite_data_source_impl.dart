import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/custom_invoice.dart';
import 'custom_invoice_local_data_source.dart';

/// Implementação SQLite do [CustomInvoiceLocalDataSource].
///
/// Tabela `custom_invoices` (v3): a factura é um DOCUMENTO por loja — o
/// corpo completo (items snapshot, descontos, notas, pagamento) é guardado
/// como JSON numa única linha, com número sequencial dentro da loja
/// (`MAX+1` na transação; `UNIQUE(store_id, invoice_number)` garante que
/// duas facturas concorrentes nunca recebem o mesmo número).
final class CustomInvoiceSqliteDataSourceImpl
    implements CustomInvoiceLocalDataSource {
  const CustomInvoiceSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns = 'id, store_id, invoice_number, payload, created_at';

  @override
  Future<List<CustomInvoice>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM custom_invoices WHERE store_id = ? '
      'ORDER BY created_at DESC, invoice_number DESC',
      [storeId],
    );
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) async {
    var persisted = invoice;
    AppDatabase.runInTransaction(_db, () {
      // Mesma semântica dos demais datasources: id duplicado é um erro
      // de domínio (StateError) — espelha a PK do banco sem vazar a
      // exceção crua do SQLite para a UI.
      final exists = _db.select('SELECT 1 FROM custom_invoices WHERE id = ?', [
        invoice.id,
      ]).isNotEmpty;
      if (exists) {
        throw StateError('Factura ${invoice.id} já existe.');
      }
      // Número SEQUENCIAL da loja: MAX+1 calculado DENTRO da transação
      // (mesmo padrão das vendas) — o número enviado no objeto é ignorado:
      // o banco é a autoridade. O UNIQUE(store_id, invoice_number) é a
      // rede de segurança contra corridas.
      final nextNumber =
          _db.select(
                'SELECT COALESCE(MAX(invoice_number), 0) + 1 AS next '
                'FROM custom_invoices WHERE store_id = ?',
                [invoice.storeId],
              ).first['next']
              as int;

      persisted = invoice.copyWith(number: nextNumber);
      _db.execute(
        'INSERT INTO custom_invoices '
        '(id, store_id, invoice_number, payload, created_at) '
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

  CustomInvoice _map(Row row) {
    final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    final invoice = CustomInvoice.fromJson(json);
    return invoice.copyWith(number: (row['invoice_number'] as num).toInt());
  }
}

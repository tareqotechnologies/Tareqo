import 'package:sqlite3/sqlite3.dart';

// Testes rodam na VM: importa a implementação io (com dart:ffi) em vez da
// facade condicional, que o analyzer resolveria para a stub.
import 'package:dumbhanengue/core/database/app_database_io.dart';

/// Abre um banco SQLite **em memória** com o schema do app (sem seed),
/// para testes de datasources/repositórios.
///
/// Na VM Windows o loader cai para a `winsqlite3.dll` do sistema via
/// [AppDatabase.configureLoader] — sem necessidade de setup manual.
Database openTestDatabase() {
  AppDatabase.configureLoader();
  final db = sqlite3.openInMemory();
  db.execute('PRAGMA foreign_keys = ON;');
  AppDatabase.createSchema(db);
  return db;
}

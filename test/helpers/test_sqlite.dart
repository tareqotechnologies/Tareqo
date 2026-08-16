import 'package:sqlite3/sqlite3.dart';

// Testes rodam na VM: importa a implementação io (com dart:ffi) em vez da
// facade condicional, que o analyzer resolveria para a stub.
import 'package:dumbhanengue/core/database/app_database_io.dart';

/// Abre um banco SQLite **em memória** com o schema do app (sem seed),
/// para testes de datasources/repositórios.
///
/// W10: com sqlite3 3.x os build hooks carregam a biblioteca nativa em
/// todas as plataformas (na VM Windows cai para a winsqlite3.dll do
/// sistema via hook) — sem setup manual de loader.
Database openTestDatabase() {
  final db = sqlite3.openInMemory();
  db.execute('PRAGMA foreign_keys = ON;');
  AppDatabase.initialize(db);
  return db;
}

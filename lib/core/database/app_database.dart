/// Facade da persistência SQLite.
///
/// A implementação real (`app_database_io.dart`) usa `dart:ffi`
/// (`package:sqlite3`), que **não existe na web** — por isso o import
/// condicional: na web entra a `app_database_stub.dart`, que declara o
/// SQLite indisponível e o ServiceLocator usa os datasources em memória.
/// Facade da persistência SQLite (import condicional io/stub).
library;

export 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart';

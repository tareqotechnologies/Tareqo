/// Exclusão de backup dos arquivos locais do app (auditoria 2026-08 — V9).
///
/// No iOS, o iCloud/iTunes faz backup do diretório Documents por padrão —
/// o `dumbhanengue.db` (dados financeiros + PII) e as fotos dos produtos
/// iriam para o backup do usuário sem necessidade. Este helper marca esses
/// caminhos como excluídos (`NSURLIsExcludedFromBackupKey`) via method
/// channel. No Android a exclusão já é global (`allowBackup=false`); aqui
/// a chamada é um no-op silencioso.
///
/// A implementação real usa o channel nativo (`backup_exclusion_io.dart`);
/// na web entra a stub. Segue o mesmo padrão de import condicional do
/// `app_database.dart`.
library;

export 'backup_exclusion_stub.dart'
    if (dart.library.io) 'backup_exclusion_io.dart';

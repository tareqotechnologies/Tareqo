/// Fonte de sinais de REALTIME do vínculo do funcionário.
///
/// Emite um sinal sempre que a linha do usuário em `store_employees`
/// muda (ex.: o dono desativou/reativou em outro dispositivo). Quem
/// consome (o `AuthGate`) re-busca os vínculos e reavalia o bloqueio —
/// bloqueio INSTANTÂNEO, sem depender de polling.
///
/// No modo Supabase a implementação usa `postgres_changes` (canal por
/// usuário, filtro `user_id = auth.uid()` — RLS só entrega o próprio
/// vínculo). No modo local (SQLite/memória) o ServiceLocator registra a
/// implementação vazia (stream que nunca emite): não há servidor para
/// ouvir — o polling do `AuthGate` continua cobrindo esse caso.
abstract interface class IEmployeeRealtimeSignalSource {
  /// Sinal emitido quando o vínculo do usuário muda no servidor.
  ///
  /// O valor do sinal é irrelevante (evento = re-verificar). Deve
  /// terminar quando o canal fecha; nunca deve lançar.
  Stream<void> get signals;
}

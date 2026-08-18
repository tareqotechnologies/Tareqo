import '../../domain/repositories/i_employee_realtime_signal_source.dart';

/// Implementação VAZIA do [IEmployeeRealtimeSignalSource] para os modos
/// locais (SQLite/memória — sem Supabase não há servidor para ouvir).
///
/// A stream nunca emite: o bloqueio reativo continua pelo POLLING do
/// `AuthGate` (fallback), que re-busca os vínculos periodicamente.
final class EmptyEmployeeRealtimeSignalSource
 implements IEmployeeRealtimeSignalSource {
 const EmptyEmployeeRealtimeSignalSource();

 @override
 Stream<void> get signals => const Stream<void>.empty();
}

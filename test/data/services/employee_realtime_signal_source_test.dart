import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/data/services/empty_employee_realtime_signal_source.dart';
import 'package:dumbhanengue/data/services/supabase_employee_realtime_signal_source.dart';

void main() {
 group('EmptyEmployeeRealtimeSignalSource (modo local)', () {
 test('nunca emite sinais', () async {
 final source = const EmptyEmployeeRealtimeSignalSource();
 var signals = 0;
 source.signals.listen((_) => signals++);
 await Future<void>.delayed(const Duration(milliseconds: 20));
 expect(signals, 0);
 });
 });

 group('SupabaseEmployeeRealtimeSignalSource (fail-closed sem Supabase)', () {
 test('sem cliente inicializado, a stream encerra sem lançar', () async {
 // Em testes unitários o `Supabase.instance` não está inicializado: a
 // fonte deve ENCERRAR silenciosamente (fail-closed) — o polling do
 // AuthGate assume como fallback. Nunca pode lançar.
 final source = SupabaseEmployeeRealtimeSignalSource();
 var signals = 0;
 var done = false;
 Object? error;

 source.signals.listen(
 (_) => signals++,
 onError: (Object e) => error = e,
 onDone: () => done = true,
 );
 await Future<void>.delayed(const Duration(milliseconds: 50));

 expect(signals, 0);
 expect(done, isTrue);
 expect(error, isNull);
 });
 });
}

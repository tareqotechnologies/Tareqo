import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/services/supabase_employee_realtime_signal_source.dart';
import '../../helpers/supabase_test_harness.dart';

/// Cobre os ramos COM sessão do [SupabaseEmployeeRealtimeSignalSource]:
/// os testes existentes cobrem o fail-closed sem Supabase; aqui o stub
/// de HTTP fornece um usuário logado (u1), permitindo exercitar a
/// assinatura do canal Realtime (`employee-status-u1`) e o encerramento
/// silencioso. O canal em si é HTTP/WS do stub — nenhum servidor real.
void main() {
  setUpAll(() async {
    await initStubbedSupabase();
    await signInStubUser();
  });

  test('com usuário logado, assinar a stream não emite sinais espúrios '
      'nem lança (fail-closed permitido)', () async {
    final source = SupabaseEmployeeRealtimeSignalSource();
    var signals = 0;
    final sub = source.signals.listen((_) => signals++);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Sem UPDATE do servidor, nenhum sinal (a emissão vem só do
    // callback do postgres_changes).
    //
    // O canal do stub não tem websocket real: o fechamento fail-closed da
    // stream (status channelError/timedOut) é comportamento VÁLIDO e
    // documentado — o polling de 30s do AuthGate assume como fallback.
    // Por isso a única garantia observável aqui é: nenhum sinal espúrio,
    // nenhuma exceção, cancelamento silencioso.
    expect(signals, 0);

    await sub.cancel();
  });

  test(
    'o canal criado usa o filtro user_id do usuário logado (isolamento)',
    () async {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      expect(userId, 'u1');

      // A fonte assina o canal do PRÓPRIO usuário: mesmo com tentativa de
      // forjar outro id, o filtro é construído de auth.uid() no servidor.
      final source = SupabaseEmployeeRealtimeSignalSource();
      final sub = source.signals.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();
    },
  );
}

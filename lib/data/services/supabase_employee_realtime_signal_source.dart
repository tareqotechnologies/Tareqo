import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/i_employee_realtime_signal_source.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Implementação Supabase do [IEmployeeRealtimeSignalSource] via
/// **`postgres_changes`** (Realtime): um canal por usuário escuta mudanças
/// na linha dele em `store_employees` (filtro `user_id = auth.uid()`).
///
/// Quando o DONO desativa/reativa o funcionário em OUTRO dispositivo, o
/// evento chega na hora (o RLS de `store_employees` permite o próprio
/// usuário ler o próprio vínculo, então ele recebe a mudança mesmo após a
/// desativação) — o `AuthGate` re-busca os vínculos e bloqueia/desbloqueia
/// INSTANTANEAMENTE, sem polling.
///
/// Requisito de deploy: a tabela precisa estar publicada no Realtime —
/// `ALTER PUBLICATION supabase_realtime ADD TABLE store_employees;`
/// (Parte 20 do `supabase/upgrade.sql`; também no `schema.sql`).
///
/// Falhas são **fail-closed**: se o Supabase não estiver inicializado ou o
/// canal falhar (websocket fora do ar), a stream apenas encerra — o
/// Realtime não se recupera até o app reiniciar, mas o POLLING do
/// `AuthGate` (30s) cobre o período como fallback.
final class SupabaseEmployeeRealtimeSignalSource
 implements IEmployeeRealtimeSignalSource {
 SupabaseEmployeeRealtimeSignalSource() {
 // Assina no primeiro listener e libera o canal quando o último sai
 // (ou no dispose). Sem listener, NENHUM canal é aberto.
 _controller.onListen = _ensureSubscribed;
 _controller.onCancel = _closeQuietly;
 }

 final StreamController<void> _controller = StreamController<void>.broadcast();
 RealtimeChannel? _channel;

 @override
 Stream<void> get signals => _controller.stream;

 /// Cria o canal e assina — chamado no primeiro listener.
 void _ensureSubscribed() {
 if (_channel != null) return;

 final client = _clientOrNull();
 if (client == null) {
 _closeQuietly();
 return;
 }

 final userId = client.auth.currentUser?.id;
 if (userId == null) {
 _closeQuietly();
 return;
 }

 final channel = client
 .channel('employee-status-$userId')
 .onPostgresChanges(
 event: PostgresChangeEvent.update,
 schema: 'public',
 table: 'store_employees',
 filter: PostgresChangeFilter(
 type: PostgresChangeFilterType.eq,
 column: 'user_id',
 value: userId,
 ),
 callback: (payload) {
 // Qualquer UPDATE no próprio vínculo (is_active, cargo, loja)
 // é motivo para re-verificar o acesso.
 if (!_controller.isClosed) {
 _controller.add(null);
 }
 },
 );
 _channel = channel;
 channel.subscribe(
 (status, error) {
 // Fail-closed: se o canal falhar (rede/websocket), encerra a
 // stream — o polling do AuthGate assume como fallback.
 if (status == RealtimeSubscribeStatus.channelError ||
 status == RealtimeSubscribeStatus.closed ||
 status == RealtimeSubscribeStatus.timedOut) {
 _closeQuietly();
 }
 },
 );
 }

 /// Encerra sem propagar exceção (fail-closed silencioso).
 void _closeQuietly() {
 // Desatribui os handlers ANTES de fechar: num broadcast controller,
 // atribuir `onListen`/`onCancel` de novo após o fechamento lançaria
 // StateError num eventual novo listener.
 _controller.onListen = null;
 _controller.onCancel = null;
 final channel = _channel;
 _channel = null;
 if (channel != null) {
 final client = _clientOrNull();
 if (client != null) {
 unawaited(client.removeChannel(channel));
 }
 }
 if (!_controller.isClosed) {
 _controller.close();
 }
 }

 /// Cliente Supabase — `null` se não inicializado (nunca lança).
 SupabaseClient? _clientOrNull() {
 try {
 return supabaseClient;
 } catch (_) {
 return null;
 }
 }
}

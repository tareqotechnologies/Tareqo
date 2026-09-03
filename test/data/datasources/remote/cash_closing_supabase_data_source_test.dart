import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/data/datasources/remote/supabase_cash_closing_data_source.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';

/// Teste de CONTRATO da RPC `close_cash_register` do datasource remoto de
/// fecho de caixa — verifica o payload EXATO enviado ao servidor (loja,
/// dia como início do dia LOCAL em UTC, contagem física em centavos) via
/// seam `rpc` injetável, o mapeamento do retorno JSONB para [CashClosing]
/// e a propagação de erros do servidor.
void main() {
 group('CashClosingSupabaseDataSourceImpl.closeCashRegister', () {
 test('chama a RPC com loja, dia (início local em UTC) e contagem em centavos',
 () async {
 final dateTime = DateTime(2026, 8, 10, 14, 30); // hora LOCAL
 late Map<String, dynamic> capturedParams;

 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 expect(fn, 'close_cash_register');
 capturedParams = params;
 return {
 'id': 'cc-st1-20260810',
 'store_id': 'st1',
 'closing_date': '2026-08-10T00:00:00.000Z',
 'total_sales': 4050,
 'expected_cash': 1100,
 'counted_cash': 1100,
 // PostgREST decodifica colunas jsonb para Map na resposta JSON.
 'sales_by_method': {'cash': 1100, 'mPesa': 2950},
 'closed_at': '2026-08-10T19:00:00.000Z',
 };
 }

 final ds = CashClosingSupabaseDataSourceImpl(rpc: rpc);

 final closing = await ds.closeCashRegister(
 storeId: 'st1',
 day: dateTime,
 countedCashCents: 1100,
 );

 // Payload: o dia é normalizado para o INÍCIO do dia LOCAL convertido
 // a UTC (a janela do RPC é [p_day, p_day + 1 dia) no fuso do cliente).
 // O valor esperado é calculado com a MESMA normalização do datasource
 // — independe do fuso horário da máquina que roda o teste.
 final expectedDayUtc = DateTime(2026, 8, 10).toUtc().toIso8601String();
 expect(capturedParams, {
 'p_store_id': 'st1',
 'p_day': expectedDayUtc,
 'p_counted_cash_cents': 1100,
 });

 // Mapeamento do JSONB de volta para a entidade.
 expect(closing.id, 'cc-st1-20260810');
 expect(closing.storeId, 'st1');
 expect(closing.totalSalesCents, 4050);
 expect(closing.expectedCashCents, 1100);
 expect(closing.countedCashCents, 1100);
 expect(closing.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
 });

 test('aceita sales_by_method como String JSON (formato defensivo)',
 () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 return {
 'id': 'cc-st1-20260810',
 'store_id': 'st1',
 'closing_date': '2026-08-10T00:00:00.000Z',
 'total_sales': 4050,
 'expected_cash': 1100,
 'counted_cash': 1200,
 'sales_by_method': '{"cash": 1100, "mPesa": 2950}',
 'closed_at': '2026-08-10T19:00:00.000Z',
 };
 }

 final ds = CashClosingSupabaseDataSourceImpl(rpc: rpc);

 final closing = await ds.closeCashRegister(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: 1200,
 );

 // Os dois formatos (Map e String) mapeiam para o mesmo mapa.
 expect(closing.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
 });

 test('PostgrestException da RPC propaga como está (sem tradução)',
 () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Apenas o dono ou um gerente podem fechar o caixa.',
 code: 'P0001',
 );
 }

 final ds = CashClosingSupabaseDataSourceImpl(rpc: rpc);

 await expectLater(
 ds.closeCashRegister(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 countedCashCents: 1100,
 ),
 throwsA(
 isA<PostgrestException>().having(
 (error) => error.message,
 'message',
 contains('Apenas o dono ou um gerente'),
 ),
 ),
 );
 });
 });
}

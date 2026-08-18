import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:dumbhanengue/data/repositories/supabase_cash_closing_summary_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_closing_summary_use_case.dart';

/// Teste de CONTRATO da RPC `get_cash_closing_summary` (prévia do Z-report
/// agregada no servidor, H2) — verifica o payload EXATO enviado (loja e
/// dia como início do dia LOCAL em UTC), o mapeamento do retorno JSONB para
/// [CashClosingSummary] (incluindo o fecho já registrado e a abertura por
/// forma nos formatos Map e String que o PostgREST pode entregar) e a
/// propagação de erros do servidor.
void main() {
 group('SupabaseCashClosingSummaryRepository.fetchSummary', () {
 Map<String, dynamic> jsonbPayload({bool withClosing = true}) => {
 'day': '2026-08-10T00:00:00.000Z',
 'total_sales_cents': 4050,
 'expected_cash_cents': 1100,
 // PostgREST decodifica colunas jsonb para Map na resposta JSON.
 'sales_by_method_cents': {'cash': 1100, 'mPesa': 2950},
 if (withClosing)
 'existing_closing': {
 'id': 'cc-st1-20260810',
 'closing_date': '2026-08-10T00:00:00.000Z',
 'total_sales': 4050,
 'expected_cash': 1100,
 'counted_cash': 1100,
 'sales_by_method': {'cash': 1100, 'mPesa': 2950},
 'closed_at': '2026-08-10T19:00:00.000Z',
 },
 };

 test('chama a RPC com loja e dia (início local em UTC)', () async {
 final dateTime = DateTime(2026, 8, 10, 14, 30); // hora LOCAL
 late Map<String, dynamic> capturedParams;

 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 expect(fn, 'get_cash_closing_summary');
 capturedParams = params;
 return jsonbPayload();
 }

 final repo = SupabaseCashClosingSummaryRepository(rpc: rpc);

 final summary = await repo.fetchSummary(
 storeId: 'st1',
 day: dateTime,
 );

 // Payload: o dia é normalizado para o INÍCIO do dia LOCAL convertido
 // a UTC (a janela da RPC é [p_day, p_day + 1 dia) — mesma semântica
 // do close_cash_register). Calculado com a MESMA normalização do
 // repositório — independe do fuso da máquina que roda o teste.
 final expectedDayUtc = DateTime(2026, 8, 10).toUtc().toIso8601String();
 expect(capturedParams, {'p_store_id': 'st1', 'p_day': expectedDayUtc});

 // Mapeamento do JSONB para o summary.
 expect(summary.day, DateTime.parse('2026-08-10T00:00:00.000Z').toLocal());
 expect(summary.totalSalesCents, 4050);
 expect(summary.expectedCashCents, 1100);
 expect(summary.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
 });

 test('mapeia o fecho já registrado (existingClosing) e o dia aberto',
 () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 return jsonbPayload();
 }

 final repo = SupabaseCashClosingSummaryRepository(rpc: rpc);

 final summary = await repo.fetchSummary(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 );

 expect(summary.isClosed, isTrue);
 final existing = summary.existingClosing!;
 expect(existing.id, 'cc-st1-20260810');
 expect(existing.totalSalesCents, 4050);
 expect(existing.expectedCashCents, 1100);
 expect(existing.countedCashCents, 1100);
 expect(existing.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});

 // Dia SEM fecho registrado (existing_closing null → isClosed false).
 Future<dynamic> rpcOpen(String fn, Map<String, dynamic> params) async {
 return jsonbPayload(withClosing: false);
 }

 final open = await SupabaseCashClosingSummaryRepository(
 rpc: rpcOpen,
 ).fetchSummary(storeId: 'st1', day: DateTime(2026, 8, 10));
 expect(open.isClosed, isFalse);
 expect(open.existingClosing, isNull);
 });

 test('aceita sales_by_method_cents como String JSON (formato defensivo) '
 'e o retorno como lista (defensivo)', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 final payload = jsonbPayload();
 payload['sales_by_method_cents'] =
 '{"cash": 1100, "mPesa": 2950}'; // String JSON
 return [payload]; // formato lista (RETURNS TABLE no futuro)
 }

 final repo = SupabaseCashClosingSummaryRepository(rpc: rpc);

 final summary = await repo.fetchSummary(
 storeId: 'st1',
 day: DateTime(2026, 8, 10),
 );

 expect(summary.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
 expect(summary.totalSalesCents, 4050);
 });

 test('PostgrestException da RPC propaga como está (sem tradução)',
 () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Acesso negado a esta loja.',
 code: 'P0001',
 );
 }

 final repo = SupabaseCashClosingSummaryRepository(rpc: rpc);

 await expectLater(
 repo.fetchSummary(storeId: 'st1', day: DateTime(2026, 8, 10)),
 throwsA(
 isA<PostgrestException>().having(
 (error) => error.message,
 'message',
 contains('Acesso negado'),
 ),
 ),
 );
 });
 });
}

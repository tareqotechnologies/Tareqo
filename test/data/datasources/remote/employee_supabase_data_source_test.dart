import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/data/datasources/remote/supabase_employee_data_source.dart';

/// Teste de CONTRATO do datasource remoto para a RPC `set_employee_active`:
/// verifica o que o app promete ao chamar o servidor (parâmetros exatos) e a
/// tradução das mensagens da RPC (secção 6b/Parte 19 do schema) em
/// `StateError` amigável — sem depender do cliente real (mesmo padrão de
/// injeção do `SupabaseEmployeeProcessor`).
void main() {
  group(
    'EmployeeSupabaseDataSourceImpl.setActive (RPC set_employee_active)',
    () {
      test('chama a RPC com o id do vínculo e o status', () async {
        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          expect(fn, 'set_employee_active');
          expect(params['p_employee_id'], 'e1');
          expect(params['p_is_active'], false);
          return null;
        }

        final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

        await ds.setActive(employeeId: 'e1', isActive: false);
      });

      test(
        'chama a RPC também para a reativação (p_is_active: true)',
        () async {
          Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
            expect(fn, 'set_employee_active');
            expect(params['p_employee_id'], 'e2');
            expect(params['p_is_active'], true);
            return null;
          }

          final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

          await ds.setActive(employeeId: 'e2', isActive: true);
        },
      );

      test(
        'não-dono da RPC vira StateError amigável (nunca a mensagem crua)',
        () async {
          Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
            throw const PostgrestException(
              message:
                  'Apenas o dono do tenant pode ativar/desativar funcionários.',
              code: 'P0001',
            );
          }

          final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

          await expectLater(
            ds.setActive(employeeId: 'e1', isActive: false),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'Apenas o dono do tenant pode ativar/desativar funcionários.',
              ),
            ),
          );
        },
      );

      test('vínculo inexistente da RPC vira StateError amigável', () async {
        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          throw const PostgrestException(
            message: 'Funcionário não encontrado.',
            code: 'P0002',
          );
        }

        final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

        await expectLater(
          ds.setActive(employeeId: 'x', isActive: true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Funcionário não encontrado. Atualize a lista e tente novamente.',
            ),
          ),
        );
      });

      test('erro inesperado da RPC vira mensagem amigável padrão', () async {
        Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
          throw const PostgrestException(
            message: 'internal server error',
            code: '500',
          );
        }

        final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

        await expectLater(
          ds.setActive(employeeId: 'e1', isActive: true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Não foi possível atualizar o funcionário. Tente novamente.',
            ),
          ),
        );
      });

      test(
        'erro NÃO-Postgrest propaga como está (só a RPC é traduzida)',
        () async {
          Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
            throw const NetworkFailure();
          }

          final ds = EmployeeSupabaseDataSourceImpl(rpc: rpc);

          // O contrato: apenas `PostgrestException` é traduzida; qualquer outra
          // exceção (rede, serialização...) chega intacta ao chamador.
          await expectLater(
            ds.setActive(employeeId: 'e1', isActive: true),
            throwsA(isA<NetworkFailure>()),
          );
        },
      );
    },
  );
}

/// Erro arbitrário de rede para o teste de propagação.
class NetworkFailure implements Exception {
  const NetworkFailure();
}

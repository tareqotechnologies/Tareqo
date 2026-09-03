import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/repositories/i_employee_account_service.dart';
import 'package:tareqo/data/services/supabase_employee_processor.dart';

StoreEmployee _employee({String role = 'employee'}) => StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: '', // preenchido pelo servidor (conta + vínculo atômicos)
 fullName: 'Funcionário',
 email: 'func@loja.com',
 role: EmployeeRole.values.byName(role),
 );

void main() {
 group('SupabaseEmployeeProcessor (RPC create_employee_account)', () {
 test('chama a RPC com vínculo/senha e devolve o id do usuário', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 expect(fn, 'create_employee_account');
 expect(params['p_employee_id'], 'e1');
 expect(params['p_email'], 'func@loja.com');
 expect(params['p_password'], 'senha-forte');
 expect(params['p_full_name'], 'Funcionário');
 expect(params['p_store_id'], 'st1');
 expect(params['p_role'], 'manager');
 return 'employee-1';
 }

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 final userId = await processor.create(
 employee: _employee(role: 'manager'),
 password: 'senha-forte',
 );

 expect(userId, 'employee-1');
 });

 test('traduz e-mail duplicado da RPC em mensagem amigável', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Já existe uma conta com este e-mail.',
 code: 'P0001',
 );
 }

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 await expectLater(
 processor.create(employee: _employee(), password: 'senha-forte'),
 throwsA(
 isA<EmployeeAccountCreationException>().having(
 (error) => error.message,
 'message',
 contains('Já existe uma conta'),
 ),
 ),
 );
 });

 test('traduz não-dono da RPC em mensagem amigável', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Apenas o dono do tenant pode cadastrar funcionários.',
 code: 'P0001',
 );
 }

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 await expectLater(
 processor.create(employee: _employee(), password: 'senha-forte'),
 throwsA(
 isA<EmployeeAccountCreationException>().having(
 (error) => error.message,
 'message',
 contains('Apenas o dono'),
 ),
 ),
 );
 });

 test('traduz loja inválida da RPC em mensagem amigável', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(
 message: 'Escolha uma loja do seu tenant.',
 code: 'P0001',
 );
 }

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 await expectLater(
 processor.create(employee: _employee(), password: 'senha-forte'),
 throwsA(
 isA<EmployeeAccountCreationException>().having(
 (error) => error.message,
 'message',
 contains('Escolha uma loja'),
 ),
 ),
 );
 });

 test('erro genérico da RPC vira mensagem genérica amigável', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async {
 throw PostgrestException(message: 'internal server error', code: 'P0001');
 }

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 await expectLater(
 processor.create(employee: _employee(), password: 'senha-forte'),
 throwsA(
 isA<EmployeeAccountCreationException>().having(
 (error) => error.message,
 'message',
 contains('Não foi possível criar a conta'),
 ),
 ),
 );
 });

 test('lança exceção amigável quando a RPC não devolve id', () async {
 Future<dynamic> rpc(String fn, Map<String, dynamic> params) async => null;

 final processor = SupabaseEmployeeProcessor(rpc: rpc);

 await expectLater(
 processor.create(employee: _employee(), password: 'senha-forte'),
 throwsA(isA<EmployeeAccountCreationException>()),
 );
 });
 });
}

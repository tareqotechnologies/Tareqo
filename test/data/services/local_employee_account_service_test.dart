import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/ids.dart';
import 'package:tareqo/data/services/local_employee_account_service.dart';

void main() {
  group('LocalEmployeeAccountService.createAccount', () {
    test(
      'deve gerar id com prefixo emp para conta criada localmente',
      () async {
        // given — serviço local de dev (sem Supabase) que nunca falha.
        const service = LocalEmployeeAccountService();

        // when
        final id = await service.createAccount(
          email: 'maria@loja.co.mz',
          password: 'senha-forte-123',
          fullName: 'Maria Chaúque',
        );

        // then
        expect(id, startsWith('emp'));
      },
    );

    test(
      'deve seguir o formato do gerador de ids do app (prefixo + _ + entropia)',
      () async {
        // given — o vínculo existe só em memória; o id precisa ser válido
        // para as demais entidades referenciarem o funcionário.
        const service = LocalEmployeeAccountService();

        // when
        final id = await service.createAccount(
          email: 'joao@loja.co.mz',
          password: 'outra-senha',
          fullName: 'João Sitoe',
        );

        // then — mesmo contrato de [AppIds.newId]: `<prefixo><micros>_<entropia>`.
        final idOfReferencia = AppIds.newId('emp');
        expect(id, matches(RegExp(r'^emp[0-9a-z]+_[0-9a-f]{6}$')));
        expect(idOfReferencia, matches(RegExp(r'^emp[0-9a-z]+_[0-9a-f]{6}$')));
      },
    );

    test('deve gerar ids únicos para chamadas consecutivas', () async {
      // given — colisão de id quebraria a chave primária do vínculo.
      const service = LocalEmployeeAccountService();

      // when
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add(
          await service.createAccount(
            email: 'func$i@loja.co.mz',
            password: 'senha',
            fullName: 'Funcionário $i',
          ),
        );
      }

      // then — 50 chamadas, 50 ids distintos.
      expect(ids, hasLength(50));
    });

    test(
      'deve aceitar campos vazios e nulos-preserváveis (modo dev não valida)',
      () async {
        // given — a validação de e-mail/senha é responsabilidade do
        // repositório remoto/fluxo de UI; o serviço local apenas gera o id.
        const service = LocalEmployeeAccountService();

        // when / then — não lança, apenas devolve o id sintético.
        final id = await service.createAccount(
          email: '',
          password: '',
          fullName: '',
        );
        expect(id, startsWith('emp'));
      },
    );
  });
}

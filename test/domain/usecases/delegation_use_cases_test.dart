import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/audit_entry.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_admin_message_repository.dart';
import 'package:tareqo/domain/repositories/i_audit_log_repository.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_request_repository.dart';
import 'package:tareqo/domain/repositories/i_purchase_repository.dart';
import 'package:tareqo/domain/repositories/i_store_repository.dart';
import 'package:tareqo/domain/repositories/i_tenant_repository.dart';
import 'package:tareqo/domain/usecases/get_audit_log_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:tareqo/domain/usecases/reset_password_use_case.dart';
import 'package:tareqo/domain/usecases/send_admin_message_use_case.dart';

/// Varredura dos casos de uso de delegação do domínio: o contrato é
/// repassar os parâmetros **intactos** ao repositório e devolver o
/// resultado sem transformação — a regra de negócio vive nas RPCs do
/// banco (ex.: `get_audit_log` valida `is_super_admin()`). O teste
/// garante que nenhum use case "come" ou altera argumentos no caminho.
void main() {
  group('GetAuditLogUseCase', () {
    test(
      'deve repassar o limite padrão de 100 entradas ao repositório',
      () async {
        // given
        final repo = _FakeAuditLogRepository();
        final useCase = GetAuditLogUseCase(repo);

        // when
        await useCase();

        // then
        expect(repo.capturedLimits, [100]);
      },
    );

    test('deve repassar limite customizado ao repositório', () async {
      // given — painel com paginação usa limites menores.
      final repo = _FakeAuditLogRepository();
      final useCase = GetAuditLogUseCase(repo);

      // when
      await useCase(limit: 25);

      // then
      expect(repo.capturedLimits, [25]);
    });

    test(
      'deve devolver as entradas do repositório sem transformação',
      () async {
        // given
        final entry = AuditEntry(
          id: 42,
          action: 'tenant_decision',
          entityType: 'tenants',
          entityId: 'tn1',
          detail: const {'status': 'approved'},
          createdAt: DateTime.parse('2026-09-01T10:00:00Z'),
        );
        final repo = _FakeAuditLogRepository()..nextResult = [entry];
        final useCase = GetAuditLogUseCase(repo);

        // when / then
        expect(await useCase(), same(repo.nextResult));
      },
    );

    test('deve devolver lista vazia quando o registo está vazio', () async {
      // given — super admin novo, sem ações registradas.
      final repo = _FakeAuditLogRepository()..nextResult = const [];
      final useCase = GetAuditLogUseCase(repo);

      // when / then
      expect(await useCase(), isEmpty);
    });

    test('deve propagar o erro do repositório (ex.: sem permissão)', () async {
      // given — RPC do banco nega `is_super_admin()`.
      final repo = _FakeAuditLogRepository()
        ..nextError = StateError('sem permissão');
      final useCase = GetAuditLogUseCase(repo);

      // when / then — a exceção chega ao caller intacta.
      await expectLater(useCase(), throwsStateError);
    });
  });

  group('GetMyPlanRequestsUseCase', () {
    test('deve repassar o tenantId ao repositório', () async {
      // given
      final repo = _FakePlanRequestRepository();
      final useCase = GetMyPlanRequestsUseCase(repo);

      // when
      await useCase('tn7');

      // then
      expect(repo.capturedTenantIds, ['tn7']);
    });

    test('deve devolver os pedidos do repositório sem alteração', () async {
      // given
      final request = PlanRequest(
        id: 'pr1',
        tenantId: 'tn7',
        currentPlanId: 'pl1',
        requestedPlanId: 'pl2',
        createdAt: DateTime.parse('2026-09-01T10:00:00Z'),
      );
      final repo = _FakePlanRequestRepository()..nextResult = [request];
      final useCase = GetMyPlanRequestsUseCase(repo);

      // when / then
      final result = await useCase('tn7');
      expect(result, hasLength(1));
      expect(result.single.id, 'pr1');
      expect(result.single.status, PlanRequestStatus.pending);
    });
  });

  group('GetPurchasesUseCase', () {
    test('deve repassar o storeId ao repositório', () async {
      // given — o escopo por loja é o que isola dados entre lojas.
      final repo = _FakePurchaseRepository();
      final useCase = GetPurchasesUseCase(repo);

      // when
      await useCase(storeId: 'st2');

      // then
      expect(repo.capturedStoreIds, ['st2']);
    });

    test('deve devolver as compras da loja sem alteração', () async {
      // given
      final purchase = Purchase(
        id: 'pc1',
        supplierName: 'Distribuidora X',
        items: const [],
        totalAmountCents: 150000,
        dateTime: DateTime.parse('2026-09-02T08:00:00Z'),
      );
      final repo = _FakePurchaseRepository()..nextResult = [purchase];
      final useCase = GetPurchasesUseCase(repo);

      // when / then
      final result = await useCase(storeId: 'st2');
      expect(result.single.totalAmountCents, 150000);
      expect(result.single.paymentMethod, PaymentMethod.cash);
    });
  });

  group('GetStoresUseCase', () {
    test('deve repassar o tenantId ao repositório', () async {
      // given
      final repo = _FakeStoreRepository();
      final useCase = GetStoresUseCase(repo);

      // when
      await useCase('tn1');

      // then
      expect(repo.capturedTenantIds, ['tn1']);
    });

    test('deve devolver as lojas do tenant sem alteração', () async {
      // given
      final repo = _FakeStoreRepository()
        ..nextResult = const [
          Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
          Store(id: 'st2', tenantId: 'tn1', name: 'Loja Praia'),
        ];
      final useCase = GetStoresUseCase(repo);

      // when / then
      final result = await useCase('tn1');
      expect(result.map((s) => s.name), ['Loja Centro', 'Loja Praia']);
    });
  });

  group('MarkTransactionAsPaidUseCase', () {
    test('deve repassar id da transação E loja ao repositório', () async {
      // given — a baixa é escopada pela loja: trocar a loja no caminho
      // marcaria transação de outra loja (bug de isolamento).
      final repo = _FakeFinancialTransactionRepository();
      final useCase = MarkTransactionAsPaidUseCase(repo);

      // when
      await useCase('tx9', storeId: 'st3');

      // then
      expect(repo.capturedCalls, [const (id: 'tx9', storeId: 'st3')]);
    });

    test('deve propagar erro quando a transação não existe na loja', () async {
      // given — id de outra loja não pode ser baixado silenciosamente.
      final repo = _FakeFinancialTransactionRepository()
        ..nextError = StateError('transação não encontrada');
      final useCase = MarkTransactionAsPaidUseCase(repo);

      // when / then
      await expectLater(
        useCase('tx-inexistente', storeId: 'st1'),
        throwsStateError,
      );
    });
  });

  group('ResetPasswordUseCase', () {
    test('deve repassar o e-mail ao repositório', () async {
      // given — o anti-enumeração (nunca revelar se a conta existe) é
      // contrato do repositório; o use case apenas encaminha.
      final repo = _FakeAuthRepository();
      final useCase = ResetPasswordUseCase(repo);

      // when
      await useCase(email: 'dono@loja.co.mz');

      // then
      expect(repo.capturedEmails, ['dono@loja.co.mz']);
    });

    test('deve propagar erro de e-mail inválido do repositório', () async {
      // given — validação de formato vive antes (formulário) e no auth
      // remoto; o use case não engole nem reinventa o erro.
      final repo = _FakeAuthRepository()
        ..nextError = ArgumentError('e-mail inválido');
      final useCase = ResetPasswordUseCase(repo);

      // when / then
      await expectLater(useCase(email: 'sema-arroba'), throwsArgumentError);
    });
  });

  group('SendAdminMessageUseCase', () {
    test(
      'deve lançar StateError quando o tenant não existe e não criar mensagem',
      () async {
        // given — guard de existência: sem tenant, nada é persistido.
        final messages = _FakeAdminMessageRepository();
        final tenants = _FakeTenantRepository()..nextGetById = null;
        final useCase = SendAdminMessageUseCase(messages, tenants);

        // when / then
        await expectLater(
          useCase(
            tenantId: 'tn-fantasma',
            type: AdminMessageType.general,
            title: 'Olá',
            body: 'Mensagem',
          ),
          throwsStateError,
        );
        // A mensagem NÃO pode ter sido criada.
        expect(messages.created, isEmpty);
      },
    );

    test(
      'deve incluir o id do tenant inexistente na mensagem de erro',
      () async {
        // given — diagnosticar o erro no painel exige saber qual id falhou.
        final messages = _FakeAdminMessageRepository();
        final tenants = _FakeTenantRepository()..nextGetById = null;
        final useCase = SendAdminMessageUseCase(messages, tenants);

        // when / then
        await expectLater(
          useCase(
            tenantId: 'tn-404',
            type: AdminMessageType.general,
            title: 'Olá',
            body: 'Mensagem',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('tn-404'),
            ),
          ),
        );
      },
    );

    test('deve criar e devolver a mensagem quando o tenant existe', () async {
      // given
      final messages = _FakeAdminMessageRepository();
      final tenants = _FakeTenantRepository()..nextGetById = _tenant('tn1');
      final useCase = SendAdminMessageUseCase(messages, tenants);

      // when
      final message = await useCase(
        tenantId: 'tn1',
        type: AdminMessageType.billingQuote,
        title: 'Cotação Profissional',
        body: '999 MT/mês',
      );

      // then — mensagem devolvida é a mesma persistida, com os campos
      // preservados e id no contrato do AppIds (prefixo + tempo + entropia).
      expect(messages.created, hasLength(1));
      expect(identical(message, messages.created.single), isTrue);
      expect(message.id, startsWith('am'));
      expect(message.id, matches(RegExp(r'^am[0-9a-z]+_[0-9a-f]{6}$')));
      expect(message.tenantId, 'tn1');
      expect(message.type, AdminMessageType.billingQuote);
      expect(message.title, 'Cotação Profissional');
      expect(message.body, '999 MT/mês');
    });

    test('deve gerar createdAt dentro da janela da chamada', () async {
      // given
      final messages = _FakeAdminMessageRepository();
      final tenants = _FakeTenantRepository()..nextGetById = _tenant('tn1');
      final useCase = SendAdminMessageUseCase(messages, tenants);

      // when — janela inclusiva evita corrida com o relógio.
      final before = DateTime.now();
      final message = await useCase(
        tenantId: 'tn1',
        type: AdminMessageType.general,
        title: 'Aviso',
        body: 'Manutenção',
      );
      final after = DateTime.now();

      // then
      expect(message.createdAt.isBefore(before), isFalse);
      expect(message.createdAt.isAfter(after), isFalse);
    });

    test(
      'deve gerar ids únicos para 200 mensagens consecutivas (sem colisão)',
      () async {
        // given — colisão de id corrompe a chave primária (insert falha no
        // banco / mensagem sobrescrita no cache local). O relógio do Windows
        // ticka a ~15,6ms: 200 chamadas em loop apertado cruzam vários ticks
        // e provam que a entropia criptográfica resolve a colisão.
        final messages = _FakeAdminMessageRepository();
        final tenants = _FakeTenantRepository()..nextGetById = _tenant('tn1');
        final useCase = SendAdminMessageUseCase(messages, tenants);

        // when
        final ids = <String>{};
        for (var i = 0; i < 200; i++) {
          final m = await useCase(
            tenantId: 'tn1',
            type: AdminMessageType.general,
            title: 'm$i',
            body: 'b',
          );
          ids.add(m.id);
        }

        // then — 200 chamadas, 200 ids distintos (regressão do bug do
        // gerador baseado só no relógio).
        expect(ids, hasLength(200));
      },
    );

    test('deve propagar erro de persistência do repositório', () async {
      // given — falha no banco não pode ser transformada em sucesso.
      final messages = _FakeAdminMessageRepository()
        ..nextError = StateError('falha de gravação');
      final tenants = _FakeTenantRepository()..nextGetById = _tenant('tn1');
      final useCase = SendAdminMessageUseCase(messages, tenants);

      // when / then
      await expectLater(
        useCase(
          tenantId: 'tn1',
          type: AdminMessageType.planExpiringSoon,
          title: 'Expira',
          body: 'Renove',
        ),
        throwsStateError,
      );
    });
  });
}

// ---------- Fakes ----------

class _FakeAuditLogRepository implements IAuditLogRepository {
  final capturedLimits = <int>[];
  List<AuditEntry> nextResult = const [];
  Object? nextError;

  @override
  Future<List<AuditEntry>> getAuditLog({int limit = 100}) async {
    capturedLimits.add(limit);
    final error = nextError;
    if (error != null) throw error;
    return nextResult;
  }
}

class _FakePlanRequestRepository implements IPlanRequestRepository {
  final capturedTenantIds = <String>[];
  List<PlanRequest> nextResult = const [];

  @override
  Future<List<PlanRequest>> getByTenant(String tenantId) async {
    capturedTenantIds.add(tenantId);
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakePurchaseRepository implements IPurchaseRepository {
  final capturedStoreIds = <String>[];
  List<Purchase> nextResult = const [];

  @override
  Future<List<Purchase>> getAll({required String storeId}) async {
    capturedStoreIds.add(storeId);
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakeStoreRepository implements IStoreRepository {
  final capturedTenantIds = <String>[];
  List<Store> nextResult = const [];

  @override
  Future<List<Store>> getByTenant(String tenantId) async {
    capturedTenantIds.add(tenantId);
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakeFinancialTransactionRepository
    implements IFinancialTransactionRepository {
  final capturedCalls = <({String id, String storeId})>[];
  Object? nextError;

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    capturedCalls.add((id: id, storeId: storeId));
    final error = nextError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakeAuthRepository implements IAuthRepository {
  final capturedEmails = <String>[];
  Object? nextError;

  @override
  Future<void> resetPassword({required String email}) async {
    capturedEmails.add(email);
    final error = nextError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakeAdminMessageRepository implements IAdminMessageRepository {
  final created = <AdminMessage>[];
  Object? nextError;

  @override
  Future<AdminMessage> create(AdminMessage message) async {
    final error = nextError;
    if (error != null) throw error;
    created.add(message);
    return message;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado: ${invocation.memberName}');
}

class _FakeTenantRepository implements ITenantRepository {
  Tenant? nextGetById;

  @override
  Future<Tenant?> getById(String id) async => nextGetById;

  // Métodos fora do caminho testado — devolvem falha explícita em vez
  // de um noSuchMethod silencioso, para caught bugs em tempo de teste.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'não usado neste teste: ${invocation.memberName}',
  );
}

Tenant _tenant(String id) => Tenant(
  id: id,
  ownerUserId: 'u1',
  businessName: 'Padaria Pão Quente',
  planId: 'pl1',
  status: TenantStatus.approved,
  createdAt: DateTime.parse('2026-01-15T09:00:00Z'),
);

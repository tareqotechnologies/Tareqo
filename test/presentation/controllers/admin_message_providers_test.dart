import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/admin_message.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_admin_messages_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_message_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';

class _FakeMessages implements GetTenantAdminMessagesUseCase {
  _FakeMessages(this._messages);
  final List<AdminMessage> _messages;

  @override
  Future<List<AdminMessage>> call(String tenantId) async => _messages;
}

/// Tenant ainda não resolvido (o caso de uso devolve null — p.ex. dono
/// aguardando aprovação): a lista de mensagens fica vazia, sem erro.
class _NullTenant implements GetMyTenantUseCase {
  const _NullTenant();

  @override
  Future<Tenant?> call(String userId) async => null;
}

AdminMessage _msg(String id, {bool read = false}) => AdminMessage(
  id: id,
  tenantId: 'tn1',
  type: AdminMessageType.billingQuote,
  title: 'Cotação de Plano',
  body: 'Proposta do plano Premium para a loja.',
  isRead: read,
  createdAt: DateTime(2026, 9, 10),
);

Tenant _approvedTenant() => Tenant(
  id: 'tn1',
  ownerUserId: 'u1',
  businessName: 'Comercial Demo',
  planId: 'pl2',
  status: TenantStatus.approved,
  createdAt: DateTime(2026, 8, 1),
);

/// Resolve a sessão e o tenant ANTES de ler o notifier — o build reage às
/// dependências em cadeia (auth → tenant → mensagens), e ler sem esperar
/// devolveria o estado intermediário vazio.
///
/// Riverpod 3: um StreamProvider só processa a fonte enquanto tem listener
/// ativo. Em teste não há widget ouvindo `authStateProvider`, e
/// `container.read(.future)` não conta como listener — o futuro fica em
/// loading para sempre (no app real funciona porque as telas observam o
/// provider). A assinatura abaixo mantém o stream vivo durante o teste; o
/// `container.dispose` do tearDown a cancela.
Future<void> _warmSession(ProviderContainer container) async {
  container.listen(authStateProvider, (_, _) {});
  await container.read(authStateProvider.future);
  await container.read(myTenantProvider('u1').future);
}

List<dynamic> _overrides({
  GetMyTenantUseCase? tenant,
  required GetTenantAdminMessagesUseCase messages,
}) => [
  authStateProvider.overrideWith(
    (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
  ),
  if (tenant != null)
    getMyTenantUseCaseProvider.overrideWithValue(tenant),
  getTenantAdminMessagesUseCaseProvider.overrideWithValue(messages),
];

void main() {
  group('tenantAdminMessagesProvider', () {
    test('carrega as mensagens do tenant aprovado', () async {
      final messages = [_msg('am1'), _msg('am2', read: true)];
      final container = ProviderContainer(
        overrides: [
          ..._overrides(
            tenant: FakeGetMyTenantUseCase(_approvedTenant()),
            messages: _FakeMessages(messages),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _warmSession(container);
      final state = await container.read(tenantAdminMessagesProvider.future);
      expect(state, messages);
    });

    test('sem usuário logado a lista fica vazia (sem tocar no caso de uso)',
        () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(tenantAdminMessagesProvider.future);
      expect(state, isEmpty);
    });

    test('tenant sem valor (dono pendente) → lista vazia, sem erro', () async {
      final container = ProviderContainer(
        overrides: [
          ..._overrides(
            tenant: const _NullTenant(),
            messages: _FakeMessages([_msg('am1')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _warmSession(container);
      final state = await container.read(tenantAdminMessagesProvider.future);
      expect(state, isEmpty);
    });

    test('refresh() recarrega o estado', () async {
      final container = ProviderContainer(
        overrides: [
          ..._overrides(
            tenant: FakeGetMyTenantUseCase(_approvedTenant()),
            messages: _FakeMessages([_msg('am1')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _warmSession(container);
      await container.read(tenantAdminMessagesProvider.future);
      final notifier = container.read(tenantAdminMessagesProvider.notifier);

      await notifier.refresh();
      final state = await container.read(tenantAdminMessagesProvider.future);
      expect(state.single.id, 'am1');
    });
  });

  group('unreadAdminMessagesCountProvider', () {
    test('conta só as mensagens não lidas', () async {
      final container = ProviderContainer(
        overrides: [
          ..._overrides(
            tenant: FakeGetMyTenantUseCase(_approvedTenant()),
            messages: _FakeMessages([
              _msg('am1'),
              _msg('am2', read: true),
              _msg('am3'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _warmSession(container);
      final count = await container.read(
        unreadAdminMessagesCountProvider.future,
      );
      expect(count, 2);
    });

    test('sem usuário logado a contagem é 0', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(
        unreadAdminMessagesCountProvider.future,
      );
      expect(count, 0);
    });
  });
}

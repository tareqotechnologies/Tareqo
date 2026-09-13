import '../../core/utils/ids.dart';
import '../entities/admin_message.dart';
import '../repositories/i_admin_message_repository.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: super admin envia uma mensagem para o dono do tenant.
///
/// Usado para cotações, notificações de alteração de validade, avisos
/// gerais, etc.
class SendAdminMessageUseCase {
  const SendAdminMessageUseCase(this._repository, this._tenantRepository);

  final IAdminMessageRepository _repository;
  final ITenantRepository _tenantRepository;

  Future<AdminMessage> call({
    required String tenantId,
    required AdminMessageType type,
    required String title,
    required String body,
  }) async {
    // Verificar se o tenant existe.
    final tenant = await _tenantRepository.getById(tenantId);
    if (tenant == null) {
      throw StateError('Tenant $tenantId não encontrado.');
    }

    // AppIds.newId combina carimbo de tempo + 24 bits de entropia
    // criptográfica: o gerador anterior usava apenas o relógio e colidia
    // quando duas mensagens eram criadas no mesmo tick (Windows ~15,6ms),
    // corrompendo a chave primária (insert falha no banco / mensagem
    // sobrescrita no cache local).
    final id = AppIds.newId('am');

    final message = AdminMessage(
      id: id,
      tenantId: tenantId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );

    return _repository.create(message);
  }
}

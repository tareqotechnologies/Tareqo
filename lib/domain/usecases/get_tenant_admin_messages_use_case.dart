import '../entities/admin_message.dart';
import '../repositories/i_admin_message_repository.dart';

/// Caso de uso: obter mensagens do admin para um tenant específico.
class GetTenantAdminMessagesUseCase {
  const GetTenantAdminMessagesUseCase(this._repository);

  final IAdminMessageRepository _repository;

  Future<List<AdminMessage>> call(String tenantId) =>
      _repository.getByTenant(tenantId);
}

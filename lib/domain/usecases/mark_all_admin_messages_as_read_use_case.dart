import '../repositories/i_admin_message_repository.dart';

/// Caso de uso: marcar todas as mensagens do admin como lidas para um tenant.
class MarkAllAdminMessagesAsReadUseCase {
  const MarkAllAdminMessagesAsReadUseCase(this._repository);

  final IAdminMessageRepository _repository;

  Future<void> call(String tenantId) =>
      _repository.markAllAsRead(tenantId);
}

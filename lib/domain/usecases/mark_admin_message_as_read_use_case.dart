import '../repositories/i_admin_message_repository.dart';

/// Caso de uso: marcar uma mensagem do admin como lida.
class MarkAdminMessageAsReadUseCase {
  const MarkAdminMessageAsReadUseCase(this._repository);

  final IAdminMessageRepository _repository;

  Future<void> call(String messageId) => _repository.markAsRead(messageId);
}

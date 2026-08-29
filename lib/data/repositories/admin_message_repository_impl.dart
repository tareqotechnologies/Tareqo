import '../../../domain/entities/admin_message.dart';
import '../../../domain/repositories/i_admin_message_repository.dart';
import '../datasources/local/admin_message_local_data_source.dart';

/// Implementação de [IAdminMessageRepository] que delega ao datasource
/// (Supabase remoto ou local/memória).
final class AdminMessageRepositoryImpl implements IAdminMessageRepository {
  const AdminMessageRepositoryImpl(this._dataSource);

  final AdminMessageLocalDataSource _dataSource;

  @override
  Future<AdminMessage> create(AdminMessage message) =>
      _dataSource.create(message);

  @override
  Future<List<AdminMessage>> getByTenant(String tenantId) =>
      _dataSource.getByTenant(tenantId);

  @override
  Future<int> getUnreadCount(String tenantId) =>
      _dataSource.getUnreadCount(tenantId);

  @override
  Future<void> markAsRead(String messageId) =>
      _dataSource.markAsRead(messageId);

  @override
  Future<void> markAllAsRead(String tenantId) =>
      _dataSource.markAllAsRead(tenantId);
}

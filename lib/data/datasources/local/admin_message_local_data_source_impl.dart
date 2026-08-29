import '../../../domain/entities/admin_message.dart';
import 'admin_message_local_data_source.dart';

/// Implementação em memória do [AdminMessageLocalDataSource] (dev/testes).
///
/// Dados não persistem entre sessões — apenas para o fluxo de desenvolvimento
/// local sem Supabase.
final class AdminMessageLocalDataSourceImpl
    implements AdminMessageLocalDataSource {
  AdminMessageLocalDataSourceImpl();

  final _messages = <String, AdminMessage>{};

  @override
  Future<AdminMessage> create(AdminMessage message) async {
    _messages[message.id] = message;
    return message;
  }

  @override
  Future<List<AdminMessage>> getByTenant(String tenantId) async {
    return _messages.values
        .where((m) => m.tenantId == tenantId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getUnreadCount(String tenantId) async {
    return _messages.values
        .where((m) => m.tenantId == tenantId && !m.isRead)
        .length;
  }

  @override
  Future<void> markAsRead(String messageId) async {
    final msg = _messages[messageId];
    if (msg != null) {
      _messages[messageId] = msg.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    final now = DateTime.now();
    for (final entry in _messages.entries) {
      if (entry.value.tenantId == tenantId && !entry.value.isRead) {
        _messages[entry.key] = entry.value.copyWith(
          isRead: true,
          readAt: now,
        );
      }
    }
  }
}

import '../../../core/utils/ids.dart';
import '../../../domain/entities/addon.dart';
import 'addon_local_data_source.dart';

/// Implementação em memória do [AddOnLocalDataSource].
///
/// Usado em modo local (SQLite) e em testes. Em modo Supabase, a
/// implementação remota é registada pelo ServiceLocator.
final class AddOnLocalDataSourceImpl implements AddOnLocalDataSource {
  AddOnLocalDataSourceImpl({List<TenantAddOn> seed = const []})
      : _records = [...seed];

  final List<TenantAddOn> _records;

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async {
    return Set.unmodifiable(
      _records
          .where((r) => r.tenantId == tenantId && r.isActive)
          .map((r) => r.addOnId),
    );
  }

  @override
  Future<void> activate(String tenantId, String addOnId) async {
    final existing = _find(tenantId, addOnId);
    if (existing != null) {
      // Re-activar se estava expirado/desactivado.
      final idx = _records.indexOf(existing);
      _records[idx] = existing.copyWith(isActive: true);
      return;
    }
    _records.add(
      TenantAddOn(
        id: AppIds.newId('ao'),
        tenantId: tenantId,
        addOnId: addOnId,
        activatedAt: DateTime.now(),
        isActive: true,
      ),
    );
  }

  @override
  Future<void> deactivate(String tenantId, String addOnId) async {
    final existing = _find(tenantId, addOnId);
    if (existing != null) {
      final idx = _records.indexOf(existing);
      _records[idx] = existing.copyWith(isActive: false);
    }
  }

  @override
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  }) async {
    _records.add(
      TenantAddOn(
        id: AppIds.newId('ao'),
        tenantId: tenantId,
        addOnId: addOnId,
        activatedAt: DateTime.now(),
        expiresAt: expiresAt,
        isActive: true,
      ),
    );
  }

  @override
  Future<bool> isActive(String tenantId, String addOnId) async {
    final record = _find(tenantId, addOnId);
    if (record == null || !record.isActive) return false;
    // Verificar expiração.
    if (record.expiresAt != null && DateTime.now().isAfter(record.expiresAt!)) {
      return false;
    }
    return true;
  }

  @override
  Future<List<TenantAddOn>> getByTenant(String tenantId) async {
    return List.unmodifiable(
      _records.where((r) => r.tenantId == tenantId).toList(),
    );
  }

  @override
  Future<int> deactivateExpired() async {
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      if (r.isActive &&
          r.expiresAt != null &&
          now.isAfter(r.expiresAt!)) {
        _records[i] = r.copyWith(isActive: false);
        count++;
      }
    }
    return count;
  }

  @override
  Future<List<TenantAddOn>> getExpired() async {
    final now = DateTime.now();
    return List.unmodifiable(
      _records.where((r) =>
          r.expiresAt != null &&
          r.isActive &&
          now.isAfter(r.expiresAt!)),
    );
  }

  TenantAddOn? _find(String tenantId, String addOnId) {
    for (final r in _records) {
      if (r.tenantId == tenantId && r.addOnId == addOnId) return r;
    }
    return null;
  }
}

import '../../../domain/entities/tenant.dart';
import 'tenant_local_data_source.dart';

/// Implementação em memória do [TenantLocalDataSource].
///
/// Inicia vazia por padrão (testes dependem disso); o seed de demonstração
/// é injetado pelo ServiceLocator.
final class TenantLocalDataSourceImpl implements TenantLocalDataSource {
  TenantLocalDataSourceImpl({
    List<Tenant> seed = const [],
    List<String> employeeUserIds = const [],
  })  : _tenants = [...seed],
        _employeeUserIds = {...employeeUserIds};

  final List<Tenant> _tenants;

  /// Ids de usuários que são funcionários de algum tenant do seed (paridade
  /// com o datasource Supabase, que resolve via `store_employees`).
  final Set<String> _employeeUserIds;

  @override
  Future<Tenant?> getMyTenant(String userId) async {
    // Dono primeiro; senão funcionário vinculado (seed injeta os ids).
    for (final tenant in _tenants) {
      if (tenant.ownerUserId == userId) return tenant;
    }
    if (_employeeUserIds.contains(userId) && _tenants.isNotEmpty) {
      return _tenants.first;
    }
    return null;
  }

  @override
  Future<Tenant?> getById(String id) async {
    for (final tenant in _tenants) {
      if (tenant.id == id) return tenant;
    }
    return null;
  }

  @override
  Future<Tenant> requestAccess({
    required String ownerUserId,
    required String businessName,
    required String planId,
    required String currencyCode,
    required String language,
  }) async {
    final tenant = Tenant(
      id: 'tn_${DateTime.now().microsecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      businessName: businessName,
      planId: planId,
      status: TenantStatus.pending,
      createdAt: DateTime.now(),
      currencyCode: currencyCode,
      language: language,
    );
    _tenants.add(tenant);
    return tenant;
  }

  @override
  Future<void> updateSettings(
    String id, {
    required String currencyCode,
    required String language,
  }) async {
    await _update(
      id,
      (tenant) => tenant.copyWith(
        currencyCode: currencyCode,
        language: language,
      ),
    );
  }

  @override
  Future<void> approve(String id) async {
    await _update(id, (tenant) => tenant.copyWith(
          status: TenantStatus.approved,
          approvedAt: DateTime.now(),
          rejectionReason: null,
        ));
  }

  @override
  Future<void> reject(String id, String reason) async {
    await _update(id, (tenant) => tenant.copyWith(
          status: TenantStatus.rejected,
          rejectionReason: reason,
        ));
  }

  @override
  Future<void> updatePlan(String id, String planId) async {
    await _update(id, (tenant) => tenant.copyWith(planId: planId));
  }

  Future<void> _update(
    String id,
    Tenant Function(Tenant) transform,
  ) async {
    final index = _tenants.indexWhere((tenant) => tenant.id == id);
    if (index < 0) {
      throw StateError('Tenant $id não encontrado.');
    }
    _tenants[index] = transform(_tenants[index]);
  }

  @override
  Future<List<Tenant>> getPending() async => List.unmodifiable(
        _tenants
            .where((tenant) => tenant.status == TenantStatus.pending)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );

  @override
  Future<List<Tenant>> getAll() async => List.unmodifiable(
        [..._tenants]
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );
}

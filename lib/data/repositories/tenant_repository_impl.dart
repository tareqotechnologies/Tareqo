import '../../domain/entities/tenant.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../datasources/local/tenant_local_data_source.dart';

/// Implementação de [ITenantRepository] sobre um [TenantLocalDataSource].
final class TenantRepositoryImpl implements ITenantRepository {
 const TenantRepositoryImpl(this._localDataSource);

 final TenantLocalDataSource _localDataSource;

 @override
 Future<Tenant?> getMyTenant(String userId) =>
 _localDataSource.getMyTenant(userId);

 @override
 Future<Tenant?> getById(String id) => _localDataSource.getById(id);

 @override
 Future<Tenant> requestAccess({
 required String ownerUserId,
 required String businessName,
 required String planId,
 required String currencyCode,
 required String language,
 }) =>
 _localDataSource.requestAccess(
 ownerUserId: ownerUserId,
 businessName: businessName,
 planId: planId,
 currencyCode: currencyCode,
 language: language,
 );

 @override
 Future<void> updateSettings(
 String id, {
 required String currencyCode,
 required String language,
 }) =>
 _localDataSource.updateSettings(
 id,
 currencyCode: currencyCode,
 language: language,
 );

 @override
 Future<void> approve(String id) => _localDataSource.approve(id);

 @override
 Future<void> reject(String id, String reason) =>
 _localDataSource.reject(id, reason);

 @override
 Future<void> updatePlan(String id, String planId) =>
 _localDataSource.updatePlan(id, planId);

 @override
 Future<List<Tenant>> getPending() => _localDataSource.getPending();

 @override
 Future<List<Tenant>> getAll() => _localDataSource.getAll();
}

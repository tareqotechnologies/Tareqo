import '../entities/plan.dart';
import '../entities/store.dart';
import '../entities/tenant.dart';
import '../repositories/i_plan_repository.dart';
import '../repositories/i_store_repository.dart';
import '../repositories/i_tenant_repository.dart';

/// Exceção de domínio: limite do plano atingido.
final class PlanLimitExceededException implements Exception {
 const PlanLimitExceededException(this.message);

 final String message;

 @override
 String toString() => 'PlanLimitExceededException: $message';
}

/// Exceção de domínio: operação exige tenant aprovado.
final class TenantNotApprovedException implements Exception {
 const TenantNotApprovedException(this.message);

 final String message;

 @override
 String toString() => 'TenantNotApprovedException: $message';
}

/// Exceção de domínio: loja inválida (dados de entrada).
final class InvalidStoreException implements Exception {
 const InvalidStoreException(this.message);

 final String message;

 @override
 String toString() => 'InvalidStoreException: $message';
}

/// Caso de uso: criar uma loja no tenant do dono.
///
/// Aplica o limite de lojas do [Plan] contratado pelo tenant: se o número
/// de lojas já atingiu `maxStores`, lança [PlanLimitExceededException].
class AddStoreUseCase {
 const AddStoreUseCase(
 this._storeRepository,
 this._tenantRepository,
 this._planRepository,
 );

 final IStoreRepository _storeRepository;
 final ITenantRepository _tenantRepository;
 final IPlanRepository _planRepository;

 Future<void> call(Store store) async {
 if (store.name.trim().isEmpty) {
 throw const InvalidStoreException('Informe o nome da loja.');
 }

 final tenant = await _tenantRepository.getById(store.tenantId);
 if (tenant == null || tenant.status != TenantStatus.approved) {
 throw const TenantNotApprovedException(
 'Seu acesso ao ERP ainda não foi aprovado.',
 );
 }

 final plan = await _planRepository.getById(tenant.planId);
 final stores = await _storeRepository.getByTenant(tenant.id);
 if (plan != null && stores.length >= plan.maxStores) {
 throw PlanLimitExceededException(
 'O plano ${plan.name} permite até ${plan.maxStores} '
 '${plan.maxStores == 1 ? 'loja' : 'lojas'}. '
 'Solicite um upgrade de plano para criar mais.',
 );
 }

 await _storeRepository.add(store);
 }
}

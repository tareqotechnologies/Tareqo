import 'dart:async';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/repositories/i_admin_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_my_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_stores_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';

/// Fake do [GetMyTenantUseCase] que retorna um tenant aprovado.
class FakeGetMyTenantUseCase implements GetMyTenantUseCase {
 FakeGetMyTenantUseCase(this._tenant);

 final Tenant _tenant;

 @override
 Future<Tenant?> call(String userId) async => _tenant;
}

/// Fake do [GetStoresUseCase] que retorna as lojas fornecidas.
class FakeGetStoresUseCase implements GetStoresUseCase {
 FakeGetStoresUseCase(this._stores);

 final List<Store> _stores;

 @override
 Future<List<Store>> call(String tenantId) async => List.unmodifiable(_stores);
}

/// Fake do [IAdminRepository] — por padrão ninguém é super admin; passe
/// `isAdmin: true` para simular o papel concedido (testes do AuthGate).
class FakeAdminRepository implements IAdminRepository {
 const FakeAdminRepository({this.isAdmin = false});

 final bool isAdmin;

 @override
 Future<bool> isSuperAdmin() async => isAdmin;
}

/// Tenant aprovado de exemplo (mesmo id do seed demo).
Tenant approvedTenant({String ownerUserId = '1'}) => Tenant(
 id: 'tn1',
 ownerUserId: ownerUserId,
 businessName: 'Comercial Demo',
 planId: 'pl2',
 status: TenantStatus.approved,
 approvedAt: DateTime.now(),
 createdAt: DateTime.now(),
 );

/// Contexto padrão de loja para testes de widget.
///
/// A Fase 2 do multi-tenancy escopa todos os módulos pela loja ativa
/// ([activeStoreIdProvider], que observa o usuário → tenant → lojas).
/// Este helper fornece os três níveis de uma vez:
/// - sessão ([authStateProvider]) com [userId];
/// - tenant aprovado ([getMyTenantUseCaseProvider]);
/// - lojas do tenant ([getStoresUseCaseProvider]).
List<dynamic> storeContextOverrides({
 String userId = '1',
 List<Store> stores = const [
 Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
 ],
}) {
 return [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: userId, email: 'dono@loja.com')),
 ),
 getMyTenantUseCaseProvider
 .overrideWithValue(FakeGetMyTenantUseCase(approvedTenant(ownerUserId: userId))),
 getStoresUseCaseProvider.overrideWithValue(FakeGetStoresUseCase(stores)),
 // Papel de super admin: sem o ServiceLocator inicializado nos testes, o
 // AuthGate cairia no estado de erro do provider — override explícito
 // (ninguém é super admin) mantém o roteamento determinístico.
 adminRepositoryProvider.overrideWithValue(const FakeAdminRepository()),
 ];
}

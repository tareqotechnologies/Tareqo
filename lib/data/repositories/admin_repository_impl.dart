import '../../domain/repositories/i_admin_repository.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Implementação [IAdminRepository] sobre o Supabase.
///
/// Chama a função RPC `is_super_admin` (`SECURITY DEFINER` no banco): o
/// papel vive na tabela `public.super_admins`, nunca em e-mail hardcoded.
/// A função responde com base na sessão do usuário logado (JWT).
final class AdminRepositoryImpl implements IAdminRepository {
 const AdminRepositoryImpl();

 @override
 Future<bool> isSuperAdmin() async {
 final result = await supabaseClient.rpc('is_super_admin');
 return result == true;
 }
}

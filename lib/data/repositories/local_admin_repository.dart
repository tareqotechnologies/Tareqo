import '../../domain/repositories/i_admin_repository.dart';

/// Implementação local (dev sem Supabase) do [IAdminRepository].
///
/// Sem o Supabase não há sessão nem banco de papéis — ninguém é super
/// admin. O painel administrativo só é alcançável no modo SaaS.
final class LocalAdminRepository implements IAdminRepository {
 const LocalAdminRepository();

 @override
 Future<bool> isSuperAdmin() async => false;
}

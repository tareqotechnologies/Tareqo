/// Contrato do papel de **super admin** (camada de domínio).
///
/// O papel é resolvido no servidor (tabela `public.super_admins` no
/// Supabase via RPC `is_super_admin`) — nunca por e-mail hardcoded no
/// cliente. A implementação concreta vive na camada `data`.
abstract interface class IAdminRepository {
  /// Retorna `true` se o usuário atualmente logado é super admin.
  Future<bool> isSuperAdmin();
}

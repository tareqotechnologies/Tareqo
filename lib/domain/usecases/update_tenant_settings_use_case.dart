import '../../core/config/app_settings.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: o dono atualiza as preferências de apresentação do tenant
/// (**moeda**, **idioma**) e a EXIGÊNCIA de MFA no servidor (P1 — auditoria:
/// a flag de MFA do app era apenas client-side; agora o dono pode ativar a
/// guarda `aal2` do RLS para as escritas de dinheiro do tenant).
///
/// Valores fora do conjunto suportado ([AppSettings]) são normalizados
/// para os padrões (BRL / pt) — defesa contra clientes externos.
class UpdateTenantSettingsUseCase {
  const UpdateTenantSettingsUseCase(this._repository);

  final ITenantRepository _repository;

  Future<void> call({
    required String tenantId,
    required String currencyCode,
    required String language,
    bool? mfaEnforced,
  }) {
    final safeCurrency = AppSettings.isValidCurrency(currencyCode)
        ? currencyCode
        : 'MZN';
    final safeLanguage = AppSettings.isValidLanguage(language)
        ? language
        : 'pt';
    return _repository.updateSettings(
      tenantId,
      currencyCode: safeCurrency,
      language: safeLanguage,
      mfaEnforced: mfaEnforced,
    );
  }
}

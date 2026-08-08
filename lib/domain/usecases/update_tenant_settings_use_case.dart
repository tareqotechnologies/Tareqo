import '../../core/config/app_settings.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: o dono atualiza as preferências de apresentação do tenant
/// (**moeda** e **idioma**) em Lojas → Ajustes.
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
  }) {
    final safeCurrency =
        AppSettings.isValidCurrency(currencyCode) ? currencyCode : 'MZN';
    final safeLanguage =
        AppSettings.isValidLanguage(language) ? language : 'pt';
    return _repository.updateSettings(
      tenantId,
      currencyCode: safeCurrency,
      language: safeLanguage,
    );
  }
}

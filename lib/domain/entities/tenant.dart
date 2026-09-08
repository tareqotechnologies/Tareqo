import 'package:freezed_annotation/freezed_annotation.dart';

part 'tenant.freezed.dart';
part 'tenant.g.dart';

/// Situação da solicitação de acesso do dono ao ERP.
enum TenantStatus {
  /// Aguardando aprovação manual do super admin (prazo de até 24h).
  pending,

  /// Aprovado — o dono pode criar lojas e funcionários.
  approved,

  /// Rejeitado — [Tenant.rejectionReason] explica o motivo.
  rejected,
}

/// Tenant (empresa) do ERP — a unidade organizacional por trás do acesso.
///
/// Fluxo: o dono se cadastra na app e solicita acesso (`pending`); o super
/// admin aprova ou rejeita manualmente; aprovado, o dono passa a gerenciar
/// lojas e funcionários dentro do tenant, limitados pelo [Plan] contratado.
@freezed
abstract class Tenant with _$Tenant {
  const factory Tenant({
    required String id,
    required String ownerUserId,
    required String businessName,
    required String planId,
    required TenantStatus status,
    String? rejectionReason,
    DateTime? approvedAt,
    required DateTime createdAt,

    /// Data de expiração do plano actual (renovação mensal a partir de
    /// [approvedAt]). Quando atinge esta data, o plano do tenant expira
    /// e o acesso pode ser desactivado.
    DateTime? planExpiresAt,

    /// Data em que a próxima factura de renovação deve ser gerada.
    /// Normalmente 7 dias antes de [planExpiresAt]. O cronJob ou
    /// verificação no app compara com a data actual para gerar a factura.
    DateTime? nextInvoiceAt,

    /// Moeda padrão dos valores (BRL, USD, EUR, MZN) — escolhida pelo dono
    /// no onboarding e alterável em Lojas → Ajustes. Novos tenants nascem
    /// com MZN (mercado-alvo Moçambique).
    @Default('MZN') String currencyCode,

    /// Idioma do aplicativo (`pt` ou `en`) — escolhido pelo dono.
    @Default('pt') String language,
  }) = _Tenant;

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);
}

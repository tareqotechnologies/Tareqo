import 'package:freezed_annotation/freezed_annotation.dart';

part 'addon.freezed.dart';
part 'addon.g.dart';

/// Categorias de add-ons disponíveis no marketplace.
enum AddOnCategory {
  invoice('Facturação'),
  quotation('Cotação'),
  reports('Relatórios'),
  employees('Funcionários'),
  multiStore('Multi-Loja'),
  payments('Pagamentos');

  const AddOnCategory(this.label);
  final String label;
}

/// Add-on (serviço extra) que o tenant pode activar além do plano base.
///
/// Cada add-on tem um preço mensal em centavos e uma categoria.
/// O tenant activa/desactiva add-ons de forma independente do plano base.
@freezed
abstract class AddOn with _$AddOn {
  const factory AddOn({
    required String id,
    required String name,
    required String description,
    required AddOnCategory category,

    /// Preço mensal em CENTAVOS inteiros.
    required int priceMonthlyCents,

    /// Ícone do add-on.
    @Default('') String iconName,

    /// Se o add-on está disponível para compra (pode ser descontinuado).
    @Default(true) bool isAvailable,
  }) = _AddOn;

  factory AddOn.fromJson(Map<String, dynamic> json) => _$AddOnFromJson(json);
}

/// Estado de um add-on activo num tenant.
@freezed
abstract class TenantAddOn with _$TenantAddOn {
  const factory TenantAddOn({
    required String id,
    required String tenantId,
    required String addOnId,
    required DateTime activatedAt,
    DateTime? expiresAt,
    @Default(true) bool isActive,
  }) = _TenantAddOn;

  factory TenantAddOn.fromJson(Map<String, dynamic> json) =>
      _$TenantAddOnFromJson(json);
}

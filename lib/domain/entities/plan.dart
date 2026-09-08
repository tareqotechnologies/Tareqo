import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan.freezed.dart';
part 'plan.g.dart';

/// Plano de assinatura do ERP — define os limites estruturais de cada
/// tenant (número de lojas, funcionários, etc.).
///
/// Criado e editado **pelo super admin** no painel administrativo. Os
/// limites são aplicados pelos casos de uso (`AddStoreUseCase`,
/// `AddEmployeeUseCase`) e também podem ser reforçados no banco (Fase 2).
@freezed
abstract class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String name,
    @Default('') String description,
    // Preço mensal em CENTAVOS inteiros (W4 — migração de dinheiro para
    // centavos; o banco persiste BIGINT/INTEGER).
    @Default(0) int priceMonthlyCents,
    @Default(1) int maxStores,
    @Default(1) int maxEmployees,
    @Default(true) bool isActive,
    // IDs dos add-ons incluídos neste plano (ex.: ['ao_advanced_reports']).
    // Tenants neste plano recebem estes add-ons automaticamente.
    @Default(<String>[]) List<String> bundledAddOns,
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}

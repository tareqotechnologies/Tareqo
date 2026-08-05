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
    @Default(0) double priceMonthly,
    @Default(1) int maxStores,
    @Default(1) int maxEmployees,
    @Default(true) bool isActive,
  }) = _Plan;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}

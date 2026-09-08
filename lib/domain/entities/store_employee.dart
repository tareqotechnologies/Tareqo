import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_employee.freezed.dart';
part 'store_employee.g.dart';

/// Cargo do funcionário dentro de uma loja.
enum EmployeeRole {
  /// Gerente — gerencia loja/funcionários (além do dono do tenant).
  manager,

  /// Funcionário comum — opera vendas/estoque da loja.
  employee,
}

/// Funcionário de uma loja: vínculo entre uma conta de usuário e uma loja
/// de um tenant, com cargo definido pelo dono.
///
/// O dono cria a conta (nome + e-mail + senha) e escolhe a loja e o cargo;
/// o funcionário apenas faz login depois (Fase 1). Na Fase 2 os módulos de
/// negócio passam a ser filtrados pelas lojas onde o usuário atua.
///
/// **Ativação:** o dono pode DESATIVAR um funcionário ([isActive] `false`)
/// — o app bloqueia o acesso (AuthGate) e o servidor nega as operações
/// (`is_my_store`/`is_manager_of_store` passam a exigir vínculo ativo).
@freezed
abstract class StoreEmployee with _$StoreEmployee {
  const factory StoreEmployee({
    required String id,
    required String tenantId,
    required String storeId,
    required String userId,
    required String fullName,
    required String email,
    @Default(EmployeeRole.employee) EmployeeRole role,

    /// Vínculo ATIVO? `false` = funcionário desativado (conta suspensa).
    @Default(true) bool isActive,
  }) = _StoreEmployee;

  factory StoreEmployee.fromJson(Map<String, dynamic> json) =>
      _$StoreEmployeeFromJson(json);
}

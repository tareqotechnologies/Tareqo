import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// Entidade de domínio que representa um cliente cadastrado.
///
/// Imutável por construção (Freezed). As dívidas ("fiado") podem referenciar
/// o cliente via [Debt.customerId] — o [name] também é "snapshotado" no
/// [Debt.personName] para preservar o histórico mesmo se o cadastro mudar.
@freezed
abstract class Customer with _$Customer {
  const factory Customer({
    required String id,
    // Loja que cadastrou o cliente (Fase 2 do multi-tenancy) — o fiado
    // referencia clientes da mesma loja.
    @Default('st1') String storeId,
    required String name,
    @Default('') String phone,
    @Default('') String email,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_request.freezed.dart';
part 'plan_request.g.dart';

/// Situação de um pedido de upgrade de plano.
enum PlanRequestStatus {
 /// Aguardando decisão do super admin.
 pending,

 /// Aprovado — o tenant passa a usar o plano solicitado.
 approved,

 /// Rejeitado pelo super admin.
 rejected;
}

/// Pedido de upgrade de plano feito pelo dono do tenant e decidido
/// manualmente pelo super admin.
///
/// Ao aprovar, o plano atual do tenant muda para o solicitado. Um novo
/// pedido só pode ser criado quando não existe outro `pending` do mesmo
/// tenant (regra no caso de uso).
@freezed
abstract class PlanRequest with _$PlanRequest {
 const factory PlanRequest({
 required String id,
 required String tenantId,
 required String currentPlanId,
 required String requestedPlanId,
 @Default(PlanRequestStatus.pending) PlanRequestStatus status,
 DateTime? decidedAt,
 required DateTime createdAt,
 }) = _PlanRequest;

 factory PlanRequest.fromJson(Map<String, dynamic> json) =>
 _$PlanRequestFromJson(json);
}

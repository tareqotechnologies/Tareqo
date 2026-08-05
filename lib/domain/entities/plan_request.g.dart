// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanRequest _$PlanRequestFromJson(Map<String, dynamic> json) => _PlanRequest(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  currentPlanId: json['currentPlanId'] as String,
  requestedPlanId: json['requestedPlanId'] as String,
  status:
      $enumDecodeNullable(_$PlanRequestStatusEnumMap, json['status']) ??
      PlanRequestStatus.pending,
  decidedAt: json['decidedAt'] == null
      ? null
      : DateTime.parse(json['decidedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PlanRequestToJson(_PlanRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'currentPlanId': instance.currentPlanId,
      'requestedPlanId': instance.requestedPlanId,
      'status': _$PlanRequestStatusEnumMap[instance.status]!,
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$PlanRequestStatusEnumMap = {
  PlanRequestStatus.pending: 'pending',
  PlanRequestStatus.approved: 'approved',
  PlanRequestStatus.rejected: 'rejected',
};

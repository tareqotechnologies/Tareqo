// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_management.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeAttendance _$EmployeeAttendanceFromJson(Map<String, dynamic> json) =>
    _EmployeeAttendance(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      userId: json['userId'] as String,
      workDate: json['workDate'] as String,
      clockIn: DateTime.parse(json['clockIn'] as String),
      clockOut: json['clockOut'] == null
          ? null
          : DateTime.parse(json['clockOut'] as String),
      recordedBy: json['recordedBy'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EmployeeAttendanceToJson(_EmployeeAttendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'userId': instance.userId,
      'workDate': instance.workDate,
      'clockIn': instance.clockIn.toIso8601String(),
      'clockOut': instance.clockOut?.toIso8601String(),
      'recordedBy': instance.recordedBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_EmployeeCommissionRate _$EmployeeCommissionRateFromJson(
  Map<String, dynamic> json,
) => _EmployeeCommissionRate(
  id: json['id'] as String,
  storeId: json['storeId'] as String,
  userId: json['userId'] as String,
  rateBps: (json['rateBps'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$EmployeeCommissionRateToJson(
  _EmployeeCommissionRate instance,
) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'userId': instance.userId,
  'rateBps': instance.rateBps,
  'createdAt': instance.createdAt.toIso8601String(),
};

_EmployeeTarget _$EmployeeTargetFromJson(Map<String, dynamic> json) =>
    _EmployeeTarget(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      userId: json['userId'] as String,
      month: json['month'] as String,
      targetCents: (json['targetCents'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EmployeeTargetToJson(_EmployeeTarget instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'userId': instance.userId,
      'month': instance.month,
      'targetCents': instance.targetCents,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_EmployeeCommissionSummaryEntry _$EmployeeCommissionSummaryEntryFromJson(
  Map<String, dynamic> json,
) => _EmployeeCommissionSummaryEntry(
  userId: json['userId'] as String,
  fullName: json['fullName'] as String,
  salesCents: (json['salesCents'] as num).toInt(),
  rateBps: (json['rateBps'] as num?)?.toInt() ?? 0,
  commissionCents: (json['commissionCents'] as num).toInt(),
);

Map<String, dynamic> _$EmployeeCommissionSummaryEntryToJson(
  _EmployeeCommissionSummaryEntry instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'fullName': instance.fullName,
  'salesCents': instance.salesCents,
  'rateBps': instance.rateBps,
  'commissionCents': instance.commissionCents,
};

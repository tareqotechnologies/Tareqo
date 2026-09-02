// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeAttendance _$EmployeeAttendanceFromJson(Map<String, dynamic> json) =>
    _EmployeeAttendance(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      storeId: json['storeId'] as String,
      clockIn: DateTime.parse(json['clockIn'] as String),
      clockOut: json['clockOut'] == null
          ? null
          : DateTime.parse(json['clockOut'] as String),
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      isManualOverride: json['isManualOverride'] as bool? ?? false,
      overrideNote: json['overrideNote'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$EmployeeAttendanceToJson(_EmployeeAttendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'storeId': instance.storeId,
      'clockIn': instance.clockIn.toIso8601String(),
      'clockOut': instance.clockOut?.toIso8601String(),
      'totalMinutes': instance.totalMinutes,
      'isManualOverride': instance.isManualOverride,
      'overrideNote': instance.overrideNote,
      'date': instance.date.toIso8601String(),
    };

_EmployeeTarget _$EmployeeTargetFromJson(Map<String, dynamic> json) =>
    _EmployeeTarget(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      storeId: json['storeId'] as String,
      period: json['period'] as String,
      salesTargetCents: (json['salesTargetCents'] as num).toInt(),
      commissionBps: (json['commissionBps'] as num?)?.toInt() ?? 500,
      salesAchievedCents: (json['salesAchievedCents'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EmployeeTargetToJson(_EmployeeTarget instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'storeId': instance.storeId,
      'period': instance.period,
      'salesTargetCents': instance.salesTargetCents,
      'commissionBps': instance.commissionBps,
      'salesAchievedCents': instance.salesAchievedCents,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_EmployeeCommission _$EmployeeCommissionFromJson(Map<String, dynamic> json) =>
    _EmployeeCommission(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      saleId: json['saleId'] as String,
      amountCents: (json['amountCents'] as num).toInt(),
      rateBps: (json['rateBps'] as num).toInt(),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$EmployeeCommissionToJson(_EmployeeCommission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'saleId': instance.saleId,
      'amountCents': instance.amountCents,
      'rateBps': instance.rateBps,
      'isPaid': instance.isPaid,
      'paidAt': instance.paidAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

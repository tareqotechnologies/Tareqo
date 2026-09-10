import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/audit_entry.dart';
import 'package:tareqo/domain/entities/employee_management.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/stock_transfer.dart';

void main() {
  group('AuditEntry (espelho da tabela audit_log)', () {
    AuditEntry buildEntry({
      String action = 'tenant_decision',
      String entityType = 'tenants',
    }) => AuditEntry(
      id: 7,
      actorUserId: 'admin-uuid',
      action: action,
      entityType: entityType,
      entityId: 'tn1',
      detail: const {'status': 'approved'},
      createdAt: DateTime(2026, 8, 16, 12),
    );

    test('toJson/fromJson faz round-trip fiel (com actor e detail)', () {
      final entry = buildEntry();

      final restored = AuditEntry.fromJson(entry.toJson());

      expect(restored.id, 7);
      expect(restored.actorUserId, 'admin-uuid');
      expect(restored.action, 'tenant_decision');
      expect(restored.entityType, 'tenants');
      expect(restored.entityId, 'tn1');
      expect(restored.detail, {'status': 'approved'});
      expect(restored.createdAt, entry.createdAt);
    });

    test('toJson/fromJson com campos nulos (sem actor/entity/detail)', () {
      final entry = AuditEntry(
        id: 1,
        action: 'plan_change',
        entityType: 'plans',
        createdAt: DateTime(2026, 8, 16, 12),
      );

      final restored = AuditEntry.fromJson(entry.toJson());

      expect(restored.actorUserId, isNull);
      expect(restored.entityId, isNull);
      expect(restored.detail, isNull);
    });

    test('createdAt é serializado em UTC e restaurado em local', () {
      final entry = buildEntry();
      final json = entry.toJson();

      // O JSON carrega o instante em UTC (mesmo instante, outra repr):
      expect(json['created_at'], endsWith('Z'));
      expect(
        DateTime.parse(json['created_at'] as String).toUtc(),
        entry.createdAt.toUtc(),
      );
      // E o fromJson devolve o MESMO instante (em local):
      expect(AuditEntry.fromJson(json).createdAt, entry.createdAt);
    });

    test('actionLabel cobre os três tipos de ação e o fallback', () {
      expect(
        buildEntry(action: 'tenant_decision').actionLabel,
        'Tenant decision',
      );
      expect(
        buildEntry(action: 'plan_request_decision').actionLabel,
        'Plan request decision',
      );
      expect(buildEntry(action: 'plan_change').actionLabel, 'Plan change');
      // Ação nova (app antigo recebendo log novo) → rótulo cru, sem crash:
      expect(buildEntry(action: 'acao_futura').actionLabel, 'acao_futura');
    });

    test('entityTypeLabel cobre os três tipos e o fallback', () {
      expect(buildEntry(entityType: 'tenants').entityTypeLabel, 'Tenant');
      expect(
        buildEntry(entityType: 'plan_requests').entityTypeLabel,
        'Plan request',
      );
      expect(buildEntry(entityType: 'plans').entityTypeLabel, 'Plan');
      expect(buildEntry(entityType: 'outra').entityTypeLabel, 'outra');
    });
  });

  group('LotConsumption (fotografia FIFO da venda)', () {
    test('igualdade e hashCode por (lotId, productId, quantity)', () {
      const a = LotConsumption(lotId: 'l1', productId: 'p1', quantity: 5000);
      const b = LotConsumption(lotId: 'l1', productId: 'p1', quantity: 5000);
      const c = LotConsumption(lotId: 'l2', productId: 'p1', quantity: 5000);
      const d = LotConsumption(lotId: 'l1', productId: 'p2', quantity: 5000);
      const e = LotConsumption(lotId: 'l1', productId: 'p1', quantity: 5001);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
      expect(a, isNot(equals(e)));
    });

    test('toString carrega os campos (debug)', () {
      const consumption = LotConsumption(
        lotId: 'l1',
        productId: 'p1',
        quantity: 5000,
      );
      expect(consumption.toString(), contains('l1'));
      expect(consumption.toString(), contains('5000'));
    });
  });

  group('StockTransfer e StockTransferStatus', () {
    StockTransfer buildTransfer({
      StockTransferStatus status = StockTransferStatus.pending,
    }) => StockTransfer(
      id: 'tr1',
      productId: 'p1',
      productName: 'Arroz',
      fromStoreId: 'st1',
      fromStoreName: 'Matriz',
      toStoreId: 'st2',
      toStoreName: 'Filial',
      quantityMilli: 2500,
      unitLabel: 'kg',
      status: status,
      createdAt: DateTime(2026, 8, 16),
    );

    test('copyWith muda APENAS o status (imutável)', () {
      final transfer = buildTransfer();

      final received = transfer.copyWith(status: StockTransferStatus.received);

      expect(received.status, StockTransferStatus.received);
      expect(received.id, 'tr1');
      expect(received.productId, 'p1');
      expect(received.quantityMilli, 2500);
      expect(transfer.status, StockTransferStatus.pending); // original intacto
    });

    test('copyWith SEM status preserva o atual (parâmetro opcional)', () {
      final transfer = buildTransfer(status: StockTransferStatus.inTransit);

      final copied = transfer.copyWith();

      expect(copied.status, StockTransferStatus.inTransit);
      expect(copied.id, transfer.id);
    });

    test('labels dos quatro estados', () {
      expect(StockTransferStatus.pending.label, 'Pendente');
      expect(StockTransferStatus.inTransit.label, 'Em Trânsito');
      expect(StockTransferStatus.received.label, 'Recebida');
      expect(StockTransferStatus.cancelled.label, 'Cancelada');
    });
  });

  group('EmployeeManagement entidades (freezed + JSON)', () {
    test('EmployeeAttendance fromJson/toJson round-trip', () {
      final attendance = EmployeeAttendance(
        id: 'att1',
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-08-16',
        clockIn: DateTime(2026, 8, 16, 8),
        recordedBy: 'boss',
        createdAt: DateTime(2026, 8, 16, 8),
      );

      final restored = EmployeeAttendance.fromJson(attendance.toJson());

      expect(restored.id, 'att1');
      expect(restored.workDate, '2026-08-16');
      expect(restored.clockIn, attendance.clockIn);
      expect(restored.recordedBy, 'boss');
      expect(restored.clockOut, isNull);
    });

    test('EmployeeCommissionRate fromJson/toJson round-trip', () {
      final rate = EmployeeCommissionRate(
        id: 'crate1',
        storeId: 'st1',
        userId: 'u1',
        rateBps: 500,
        createdAt: DateTime(2026, 8, 1),
      );

      final restored = EmployeeCommissionRate.fromJson(rate.toJson());

      expect(restored.rateBps, 500);
      expect(restored.storeId, 'st1');
    });

    test('EmployeeTarget fromJson/toJson round-trip', () {
      final target = EmployeeTarget(
        id: 'tgt1',
        storeId: 'st1',
        userId: 'u1',
        month: '2026-08',
        targetCents: 1000000,
        createdAt: DateTime(2026, 8, 1),
      );

      final restored = EmployeeTarget.fromJson(target.toJson());

      expect(restored.month, '2026-08');
      expect(restored.targetCents, 1000000);
    });

    test('EmployeeCommissionSummaryEntry fromJson/toJson round-trip', () {
      const entry = EmployeeCommissionSummaryEntry(
        userId: 'u1',
        fullName: 'Maria',
        salesCents: 500000,
        rateBps: 700,
        commissionCents: 35000,
      );

      final restored = EmployeeCommissionSummaryEntry.fromJson(entry.toJson());

      expect(restored.commissionCents, 35000);
      expect(restored.fullName, 'Maria');
    });
  });
}

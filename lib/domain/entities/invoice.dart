import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

/// Estado de uma factura de cobrança do tenant.
enum InvoiceStatus {
  /// Factura gerada mas ainda não paga.
  pending,

  /// Factura paga pelo tenant.
  paid,

  /// Factura expirada (não foi paga até à data de vencimento).
  expired,

  /// Factura cancelada pelo super admin.
  cancelled,
}

/// Factura de cobrança gerada para renovação mensal do plano do tenant.
///
/// O ciclo de facturação é automático: a partir da data de aprovação do
/// tenant (`Tenant.approvedAt`), o plano renova mensalmente. 7 dias antes
/// da data de expiração, uma nova factura é gerada e o dono do tenant
/// é notificado.
///
/// Cada factura liga-se ao tenant e ao plano contratado, registando o
/// valor a cobrar (em centavos) no momento da geração.
@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,

    /// Número sequencial da factura (ex.: INV-00001, INV-00002).
    /// Atribuído pelo banco no insert — SQLite: MAX+1 por tenant;
    /// Supabase: RPC ou gen_random_uuid().
    @Default(0) int number,

    /// Tenant a quem a factura se destina.
    required String tenantId,

    /// Plano contratado no momento da geração (snapshot).
    required String planId,

    /// Valor em CENTAVOS inteiros (mesma unidade do Plan.priceMonthlyCents).
    required int amountCents,

    /// Estado actual da factura.
    @Default(InvoiceStatus.pending) InvoiceStatus status,

    /// Data de vencimento — quando a factura expira se não for paga.
    required DateTime dueDate,

    /// Período que a factura cobre (ex.: "Janeiro 2026").
    @Default('') String period,

    /// Data de pagamento (carimbada quando o super admin marca como paga).
    DateTime? paidAt,

    /// Observações do super admin sobre a factura.
    String? notes,

    required DateTime createdAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

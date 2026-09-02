// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomInvoice _$CustomInvoiceFromJson(Map<String, dynamic> json) =>
    _CustomInvoice(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      storeId: json['storeId'] as String,
      clientName: json['clientName'] as String,
      clientPhone: json['clientPhone'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      clientAddress: json['clientAddress'] as String? ?? '',
      clientTaxId: json['clientTaxId'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => CustomInvoiceItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CustomInvoiceItem>[],
      totalAmountCents: (json['totalAmountCents'] as num).toInt(),
      discountCents: (json['discountCents'] as num?)?.toInt() ?? 0,
      taxCents: (json['taxCents'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentReference: json['paymentReference'] as String? ?? '',
      exportedPdf: json['exportedPdf'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CustomInvoiceToJson(_CustomInvoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'storeId': instance.storeId,
      'clientName': instance.clientName,
      'clientPhone': instance.clientPhone,
      'clientEmail': instance.clientEmail,
      'clientAddress': instance.clientAddress,
      'clientTaxId': instance.clientTaxId,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalAmountCents': instance.totalAmountCents,
      'discountCents': instance.discountCents,
      'taxCents': instance.taxCents,
      'notes': instance.notes,
      'paymentMethod': instance.paymentMethod,
      'paymentReference': instance.paymentReference,
      'exportedPdf': instance.exportedPdf,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_CustomInvoiceItem _$CustomInvoiceItemFromJson(Map<String, dynamic> json) =>
    _CustomInvoiceItem(
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPriceCents: (json['unitPriceCents'] as num).toInt(),
      subtotalCents: (json['subtotalCents'] as num).toInt(),
      unit: json['unit'] as String? ?? 'un',
    );

Map<String, dynamic> _$CustomInvoiceItemToJson(_CustomInvoiceItem instance) =>
    <String, dynamic>{
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unitPriceCents': instance.unitPriceCents,
      'subtotalCents': instance.subtotalCents,
      'unit': instance.unit,
    };

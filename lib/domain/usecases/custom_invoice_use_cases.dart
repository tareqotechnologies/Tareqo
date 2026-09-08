import '../entities/custom_invoice.dart';

/// Caso de uso para criar facturas personalizadas.
class CreateCustomInvoiceUseCase {
  const CreateCustomInvoiceUseCase();

  CustomInvoice call({
    required String storeId,
    required String clientName,
    String clientPhone = '',
    String clientEmail = '',
    String clientAddress = '',
    String clientTaxId = '',
    required List<CustomInvoiceItemInput> items,
    int discountCents = 0,
    int taxCents = 0,
    String notes = '',
    String paymentMethod = '',
  }) {
    if (items.isEmpty) {
      throw ArgumentError('A factura deve ter pelo menos um item.');
    }
    if (clientName.trim().isEmpty) {
      throw ArgumentError('O nome do cliente é obrigatório.');
    }
    if (discountCents < 0) {
      throw ArgumentError('O desconto não pode ser negativo.');
    }
    if (taxCents < 0) {
      throw ArgumentError('O imposto não pode ser negativo.');
    }
    for (final item in items) {
      if (item.productName.trim().isEmpty) {
        throw ArgumentError('Todo item deve ter um nome.');
      }
      if (item.quantity <= 0) {
        throw ArgumentError(
          'A quantidade de cada item deve ser maior que zero.',
        );
      }
      if (item.unitPriceCents < 0) {
        throw ArgumentError('O preço unitário não pode ser negativo.');
      }
    }

    final invoiceItems = <CustomInvoiceItem>[];
    int totalCents = 0;

    for (final item in items) {
      final subtotal = item.quantity * item.unitPriceCents;
      totalCents += subtotal;
      invoiceItems.add(
        CustomInvoiceItem(
          productName: item.productName,
          quantity: item.quantity,
          unitPriceCents: item.unitPriceCents,
          subtotalCents: subtotal,
          unit: item.unit,
        ),
      );
    }

    totalCents -= discountCents;
    totalCents += taxCents;
    if (totalCents < 0) totalCents = 0;

    return CustomInvoice(
      id: '', // Atribuído pelo banco
      storeId: storeId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientAddress: clientAddress,
      clientTaxId: clientTaxId,
      items: invoiceItems,
      totalAmountCents: totalCents,
      discountCents: discountCents,
      taxCents: taxCents,
      notes: notes,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
  }
}

/// Input para itens de factura personalizada.
class CustomInvoiceItemInput {
  const CustomInvoiceItemInput({
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
    this.unit = 'un',
  });

  final String productName;
  final int quantity;
  final int unitPriceCents;
  final String unit;
}

/// Caso de uso para gerar dados da factura como texto formatado
/// (para preview, compartilhamento ou exportação futura).
class GenerateInvoicePreviewUseCase {
  const GenerateInvoicePreviewUseCase();

  /// Gera um preview textual da factura (pode ser enviado por WhatsApp
  /// ou exportado como PDF no futuro).
  String call(CustomInvoice invoice) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════');
    buffer.writeln('        FACTURA');
    buffer.writeln('═══════════════════════════════');
    buffer.writeln('Nº: ${invoice.number}');
    buffer.writeln('Data: ${_formatDate(invoice.createdAt)}');
    buffer.writeln();
    buffer.writeln('CLIENTE:');
    buffer.writeln('  ${invoice.clientName}');
    if (invoice.clientPhone.isNotEmpty) {
      buffer.writeln('  Tel: ${invoice.clientPhone}');
    }
    if (invoice.clientTaxId.isNotEmpty) {
      buffer.writeln('  NIF: ${invoice.clientTaxId}');
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────');

    for (final item in invoice.items) {
      buffer.writeln(
        '  ${item.productName}  ${_formatQty(item.quantity)} x ${_formatMoney(item.unitPriceCents)}',
      );
      buffer.writeln('    Subtotal: ${_formatMoney(item.subtotalCents)}');
    }

    buffer.writeln('───────────────────────────────');
    if (invoice.discountCents > 0) {
      buffer.writeln('  Desconto:  -${_formatMoney(invoice.discountCents)}');
    }
    if (invoice.taxCents > 0) {
      buffer.writeln('  IVA:       +${_formatMoney(invoice.taxCents)}');
    }
    buffer.writeln('  TOTAL:     ${_formatMoney(invoice.totalAmountCents)}');
    buffer.writeln('═══════════════════════════════');

    if (invoice.notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(invoice.notes);
    }

    return buffer.toString();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatMoney(int cents) {
    final v = cents / 100;
    return '${v.toStringAsFixed(2)} MT';
  }

  String _formatQty(int millesimos) {
    if (millesimos % 1000 == 0) return '${millesimos ~/ 1000}';
    return (millesimos / 1000).toStringAsFixed(1);
  }
}

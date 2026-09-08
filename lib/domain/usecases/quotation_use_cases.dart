import '../entities/quotation.dart';
import '../entities/customer.dart';

/// Caso de uso para criar uma nova cotação/orçamento.
class CreateQuotationUseCase {
  const CreateQuotationUseCase();

  /// Cria uma cotação a partir dos itens e dados do cliente.
  Quotation call({
    required String storeId,
    required Customer customer,
    required List<QuotationItemInput> items,
    int discountCents = 0,
    String notes = '',
    int validityDays = 7,
  }) {
    if (items.isEmpty) {
      throw ArgumentError('A cotação deve ter pelo menos um item.');
    }
    if (customer.name.trim().isEmpty) {
      throw ArgumentError('O nome do cliente é obrigatório.');
    }
    if (discountCents < 0) {
      throw ArgumentError('O desconto não pode ser negativo.');
    }
    if (validityDays <= 0) {
      throw ArgumentError(
        'A validade da cotação deve ser de pelo menos 1 dia.',
      );
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

    int totalCents = 0;
    final quotationItems = <QuotationItem>[];

    for (final item in items) {
      final subtotal = item.quantity * item.unitPriceCents;
      totalCents += subtotal;
      quotationItems.add(
        QuotationItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPriceCents: item.unitPriceCents,
        ),
      );
    }

    totalCents -= discountCents;
    if (totalCents < 0) totalCents = 0;

    final now = DateTime.now();
    return Quotation(
      id: '', // Atribuído pelo banco
      storeId: storeId,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      items: quotationItems,
      totalAmountCents: totalCents,
      discountCents: discountCents,
      notes: notes,
      validUntil: now.add(Duration(days: validityDays)),
      createdAt: now,
    );
  }
}

/// Input para itens de cotação durante a criação.
class QuotationItemInput {
  const QuotationItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPriceCents;
}

/// Caso de uso para converter uma cotação aceite numa venda.
class ConvertQuotationToSaleUseCase {
  const ConvertQuotationToSaleUseCase();

  /// Retorna os itens formatados para inserção directa no processamento
  /// de venda. O caller deve usar o `ProcessSaleUseCase` para finalizar.
  List<SaleItemInput> prepareSaleItems(Quotation quotation) {
    if (quotation.status != QuotationStatus.accepted) {
      throw StateError('Só é possível converter cotações com status "Aceite".');
    }
    if (quotation.items.isEmpty) {
      throw StateError('A cotação aceite deve ter itens para converter.');
    }
    for (final item in quotation.items) {
      if (item.quantity <= 0 || item.unitPriceCents < 0) {
        throw StateError('Item inválido na cotação aceite.');
      }
    }
    return quotation.items
        .map(
          (item) => SaleItemInput(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            unitPriceCents: item.unitPriceCents,
          ),
        )
        .toList();
  }
}

/// Input para itens de venda (reutilizável).
class SaleItemInput {
  const SaleItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCents,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPriceCents;
}

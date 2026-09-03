/// Transferência de estoque entre lojas — regista a movimentação de
/// produto de uma loja para outra dentro do mesmo tenant.
class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.productId,
    required this.productName,
    required this.fromStoreId,
    required this.fromStoreName,
    required this.toStoreId,
    required this.toStoreName,
    required this.quantityMilli,
    required this.unitLabel,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String fromStoreId;
  final String fromStoreName;
  final String toStoreId;
  final String toStoreName;
  final int quantityMilli;
  final String unitLabel;
  final StockTransferStatus status;
  final DateTime createdAt;

  StockTransfer copyWith({StockTransferStatus? status}) {
    return StockTransfer(
      id: id,
      productId: productId,
      productName: productName,
      fromStoreId: fromStoreId,
      fromStoreName: fromStoreName,
      toStoreId: toStoreId,
      toStoreName: toStoreName,
      quantityMilli: quantityMilli,
      unitLabel: unitLabel,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

enum StockTransferStatus {
  pending,
  inTransit,
  received,
  cancelled;

  String get label {
    switch (this) {
      case StockTransferStatus.pending:
        return 'Pendente';
      case StockTransferStatus.inTransit:
        return 'Em Trânsito';
      case StockTransferStatus.received:
        return 'Recebida';
      case StockTransferStatus.cancelled:
        return 'Cancelada';
    }
  }
}

import '../entities/store_transfer.dart';

/// Caso de uso para criar uma transferência entre lojas.
class CreateStoreTransferUseCase {
  const CreateStoreTransferUseCase();

  StoreTransfer call({
    required String fromStoreId,
    required String fromStoreName,
    required String toStoreId,
    required String toStoreName,
    required List<StoreTransferItemInput> items,
    String notes = '',
    String authorizedByUserId = '',
  }) {
    if (items.isEmpty) {
      throw ArgumentError('A transferência deve ter pelo menos um item.');
    }
    if (fromStoreId == toStoreId) {
      throw ArgumentError('Não é possível transferir para a mesma loja.');
    }

    final transferItems = items
        .map(
          (item) => StoreTransferItem(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
          ),
        )
        .toList();

    return StoreTransfer(
      id: '', // Atribuído pelo banco
      fromStoreId: fromStoreId,
      fromStoreName: fromStoreName,
      toStoreId: toStoreId,
      toStoreName: toStoreName,
      items: transferItems,
      notes: notes,
      authorizedByUserId: authorizedByUserId,
      createdAt: DateTime.now(),
    );
  }
}

/// Input para itens de transferência.
class StoreTransferItemInput {
  const StoreTransferItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final int quantity;
}

/// Caso de uso para confirmar recebimento de transferência.
class ConfirmTransferReceiveUseCase {
  const ConfirmTransferReceiveUseCase();

  /// Marca a transferência como recebida. O estoque de origem já foi
  /// debitado ao enviar; agora o destino é creditado.
  StoreTransfer call(StoreTransfer transfer) {
    if (transfer.status != TransferStatus.inTransit) {
      throw StateError('Só é possível receber transferências em trânsito.');
    }
    return transfer.copyWith(
      status: TransferStatus.received,
      receivedAt: DateTime.now(),
    );
  }
}

/// Caso de uso para despachar (enviar) uma transferência.
class DispatchTransferUseCase {
  const DispatchTransferUseCase();

  StoreTransfer call(StoreTransfer transfer) {
    if (transfer.status != TransferStatus.pending) {
      throw StateError('Só é possível despachar transferências pendentes.');
    }
    return transfer.copyWith(
      status: TransferStatus.inTransit,
      shippedAt: DateTime.now(),
    );
  }
}

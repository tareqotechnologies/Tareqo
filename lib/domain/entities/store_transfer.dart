import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_transfer.freezed.dart';
part 'store_transfer.g.dart';

/// Estado de uma transferência entre lojas.
enum TransferStatus {
  pending('Pendente'),
  inTransit('Em Trânsito'),
  received('Recebida'),
  cancelled('Cancelada');

  const TransferStatus(this.label);
  final String label;
}

/// Transferência de estoque entre lojas do mesmo tenant.
///
/// Permite mover produtos de uma loja para outra, mantendo a rastreabilidade
/// completa do estoque em ambas as pontas.
@freezed
abstract class StoreTransfer with _$StoreTransfer {
  const factory StoreTransfer({
    required String id,
    @Default(0) int number,
    required String fromStoreId,
    required String fromStoreName,
    required String toStoreId,
    required String toStoreName,
    @Default(<StoreTransferItem>[]) List<StoreTransferItem> items,
    @Default(TransferStatus.pending) TransferStatus status,

    /// Notas/justificativa da transferência.
    @Default('') String notes,
    DateTime? shippedAt,
    DateTime? receivedAt,

    /// ID do funcionário que autorizou.
    @Default('') String authorizedByUserId,
    required DateTime createdAt,
  }) = _StoreTransfer;

  factory StoreTransfer.fromJson(Map<String, dynamic> json) =>
      _$StoreTransferFromJson(json);
}

/// Item de uma transferência.
@freezed
abstract class StoreTransferItem with _$StoreTransferItem {
  const factory StoreTransferItem({
    required String productId,
    required String productName,

    /// Quantidade em milésimos.
    required int quantity,
  }) = _StoreTransferItem;

  factory StoreTransferItem.fromJson(Map<String, dynamic> json) =>
      _$StoreTransferItemFromJson(json);
}

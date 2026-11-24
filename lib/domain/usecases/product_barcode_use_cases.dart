import '../../core/utils/ids.dart';
import '../entities/product_barcode.dart';
import '../repositories/i_product_barcode_repository.dart';

/// Exceção de domínio: embalagem inválida (barcode vazio, fator ≤ 0 ou
/// código repetido dentro do mesmo produto).
final class InvalidProductBarcodeException implements Exception {
  const InvalidProductBarcodeException(this.message);

  final String message;

  @override
  String toString() => 'InvalidProductBarcodeException: $message';
}

/// Lê os códigos de barras da loja ou de um produto específico.
class GetProductBarcodesUseCase {
  const GetProductBarcodesUseCase(this._repository);

  final IProductBarcodeRepository _repository;

  Future<List<ProductBarcode>> call({
    required String storeId,
    String? productId,
  }) {
    if (productId == null) {
      return _repository.getAll(storeId: storeId);
    }
    return _repository.getForProduct(productId, storeId: storeId);
  }
}

/// Guarda a lista COMPLETA de embalagens de um produto, calculando o diff
/// em relação ao que já estava persistido.
///
/// A validação de negócio vive aqui (camada de domínio); os datasources
/// apenas persistem. O código principal em `products.barcode` não é tocado.
class SaveProductBarcodesUseCase {
  const SaveProductBarcodesUseCase(this._repository);

  final IProductBarcodeRepository _repository;

  Future<List<ProductBarcode>> call({
    required String productId,
    required String storeId,
    required List<ProductBarcode> original,
    required List<ProductBarcode> desired,
  }) async {
    final normalized = <String>{};
    final prepared = <ProductBarcode>[];

    for (final item in desired) {
      final barcode = item.barcode.trim();
      if (barcode.isEmpty) {
        throw const InvalidProductBarcodeException(
          'O código de barras não pode ficar vazio.',
        );
      }
      if (barcode.length > 512) {
        throw const InvalidProductBarcodeException(
          'O código de barras deve ter no máximo 512 caracteres.',
        );
      }
      if (item.qtyFactor <= 0) {
        throw const InvalidProductBarcodeException(
          'O fator da embalagem deve ser maior que zero.',
        );
      }
      final key = barcode.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (!normalized.add(key)) {
        throw InvalidProductBarcodeException(
          'O código $barcode está repetido neste produto.',
        );
      }
      prepared.add(
        item.copyWith(
          id: item.id.isEmpty ? AppIds.newId('pb') : item.id,
          storeId: storeId,
          productId: productId,
          barcode: barcode,
        ),
      );
    }

    final desiredIds = {for (final item in prepared) item.id};
    for (final old in original) {
      if (!desiredIds.contains(old.id)) {
        await _repository.delete(old.id, storeId: storeId);
      }
    }

    final originalById = {for (final item in original) item.id: item};
    for (final item in prepared) {
      if (originalById.containsKey(item.id)) {
        await _repository.update(item);
      } else {
        await _repository.add(item);
      }
    }
    return List.unmodifiable(prepared);
  }
}

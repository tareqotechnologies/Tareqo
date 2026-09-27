import '../entities/production_order.dart';
import '../entities/recipe.dart';
import '../repositories/i_production_repository.dart';
import '../repositories/i_unit_of_work.dart';

/// Exceção de domínio: ficha técnica inválida (sem produto, sem
/// componentes, rendimento/quantidades não positivos ou autocomposição).
final class InvalidRecipeException implements Exception {
  const InvalidRecipeException(this.message);

  final String message;

  @override
  String toString() => 'InvalidRecipeException: $message';
}

/// Caso de uso: listar as fichas técnicas da loja (mais recentes primeiro).
class GetRecipesUseCase {
  const GetRecipesUseCase(this._repository);

  final IProductionRepository _repository;

  Future<List<Recipe>> call({required String storeId}) =>
      _repository.getRecipes(storeId: storeId);
}

/// Caso de uso: listar o histórico de ordens de produção da loja.
class GetProductionOrdersUseCase {
  const GetProductionOrdersUseCase(this._repository);

  final IProductionRepository _repository;

  Future<List<ProductionOrder>> call({required String storeId}) =>
      _repository.getProductionOrders(storeId: storeId);
}

/// Caso de uso: gravar (criar/editar) uma ficha técnica, validando as regras
/// de negócio antes de persistir (dentro de [IUnitOfWork], para que ficha +
/// itens sejam gravados juntos).
class SaveRecipeUseCase {
  const SaveRecipeUseCase(this._repository, this._unitOfWork);

  final IProductionRepository _repository;
  final IUnitOfWork _unitOfWork;

  Future<void> call(Recipe recipe) async {
    _validate(recipe);
    await _unitOfWork.run(() => _repository.saveRecipe(recipe));
  }

  void _validate(Recipe recipe) {
    if (recipe.productId.trim().isEmpty) {
      throw const InvalidRecipeException(
        'A ficha técnica precisa de um produto acabado.',
      );
    }
    if (recipe.yieldQuantity <= 0) {
      throw const InvalidRecipeException(
        'O rendimento da ficha técnica deve ser maior que zero.',
      );
    }
    if (recipe.items.isEmpty) {
      throw const InvalidRecipeException(
        'A ficha técnica deve conter ao menos um componente.',
      );
    }
    final seen = <String>{};
    for (final item in recipe.items) {
      if (item.quantity <= 0) {
        throw const InvalidRecipeException(
          'A quantidade de cada componente deve ser maior que zero.',
        );
      }
      if (item.productId == recipe.productId) {
        throw const InvalidRecipeException(
          'O produto acabado não pode ser componente da própria ficha.',
        );
      }
      if (!seen.add(item.productId)) {
        throw const InvalidRecipeException(
          'Um componente não pode aparecer duas vezes na ficha técnica.',
        );
      }
    }
  }
}

/// Caso de uso: remover uma ficha técnica da loja.
class DeleteRecipeUseCase {
  const DeleteRecipeUseCase(this._repository);

  final IProductionRepository _repository;

  Future<void> call(String recipeId, {required String storeId}) =>
      _repository.deleteRecipe(recipeId, storeId: storeId);
}

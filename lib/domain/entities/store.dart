import 'package:freezed_annotation/freezed_annotation.dart';

part 'store.freezed.dart';
part 'store.g.dart';

/// Loja de um tenant — cada loja terá seus próprios funcionários e, na
/// Fase 2, seu próprio estoque e vendas (escopo por `store_id`).
@freezed
abstract class Store with _$Store {
 const factory Store({
 required String id,
 required String tenantId,
 required String name,
 @Default('') String address,
 @Default('') String phone,
 @Default('') String email,
 @Default('') String nuit,
 @Default('') String city,
 }) = _Store;

 factory Store.fromJson(Map<String, dynamic> json) => _$StoreFromJson(json);
}

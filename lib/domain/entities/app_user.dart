import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// Usuário autenticado do aplicativo (entidade de domínio).
///
/// Objeto **personalizado** — abstrai o `User` do Supabase/gotrue para que
/// o domínio e a UI não dependam do provedor de autenticação.
@freezed
abstract class AppUser with _$AppUser {
 const factory AppUser({
 required String id,
 required String email,
 @Default('') String fullName,
 }) = _AppUser;

 factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

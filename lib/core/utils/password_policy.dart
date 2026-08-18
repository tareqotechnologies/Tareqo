/// Política de senha e validação de e-mail — compartilhada entre o login,
/// o cadastro e os fluxos de troca/redefinição de senha (o mesmo contrato
/// do provedor GoTrue/Supabase, validado ANTES do envio).
library;

/// Validação de e-mail rigorosa (exige domínio e TLD) — evita aceitar
/// 'a@b' como endereço válido.
final RegExp emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Classes de caracteres exigidas pela política de senha do provedor:
/// pelo menos uma minúscula, uma maiúscula, um número e um símbolo.
final RegExp _lowercaseRegExp = RegExp(r'[a-z]');
final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
final RegExp _digitRegExp = RegExp(r'[0-9]');
final RegExp _symbolRegExp = RegExp(
 "[!@#\$%^&*()_+\\-=\\[\\]{};:'\",.?`~<>/\\\\|]",
);

bool _isStrongPassword(String value) =>
 _lowercaseRegExp.hasMatch(value) &&
 _uppercaseRegExp.hasMatch(value) &&
 _digitRegExp.hasMatch(value) &&
 _symbolRegExp.hasMatch(value);

/// Motivo pelo qual a senha não passa na política local (ou `null` se
/// válida). [requireStrong] ativa a política completa (4 classes) — no
/// login apenas o mínimo de 8 caracteres.
enum PasswordIssue {
 /// Menos de 8 caracteres.
 tooShort,

 /// 8+ caracteres mas sem as 4 classes exigidas no cadastro.
 weak,
}

PasswordIssue? passwordIssue(String value, {required bool requireStrong}) {
 if (value.length < 8) return PasswordIssue.tooShort;
 if (requireStrong && !_isStrongPassword(value)) return PasswordIssue.weak;
 return null;
}

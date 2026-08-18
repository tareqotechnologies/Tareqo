import 'package:flutter/widgets.dart';

/// Preferências de apresentação do **tenant** (escolhidas pelo dono):
/// a moeda usada nos valores e o idioma do aplicativo (pt/en/fr).
///
/// Vive na tabela `tenants` (`currency_code`, `language`) — o dono escolhe
/// no onboarding e pode alterar em Lojas → Ajustes. Funcionários herdam a
/// configuração do dono (a escolha é do negócio, não do usuário).
class AppSettings {
 const AppSettings({required this.currencyCode, required this.language});

 /// Código ISO da moeda: `BRL`, `USD`, `EUR` ou `MZN`.
 final String currencyCode;

 /// Idioma do app: `pt`, `en` ou `fr`.
 final String language;

 /// Moedas suportadas (escolha do dono).
 static const List<String> supportedCurrencies = ['BRL', 'USD', 'EUR', 'MZN'];

 /// Idiomas suportados (escolha do dono).
 static const List<String> supportedLanguages = ['pt', 'en', 'fr'];

 /// Locale derivado do idioma escolhido.
 Locale get locale => Locale(language);

 static bool isValidCurrency(String code) =>
 supportedCurrencies.contains(code);

 static bool isValidLanguage(String lang) => supportedLanguages.contains(lang);
}

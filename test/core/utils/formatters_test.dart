import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/formatters.dart';

void main() {
 tearDown(() {
 // Volta ao padrão para não vazar estado entre testes.
 Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
 });

 group('currency (recebe CENTAVOS inteiros — W4)', () {
 test('padrão: BRL + pt (sem configuração)', () {
 expect(Formatters.currentCurrencyCode, 'BRL');
 expect(Formatters.currentLanguage, 'pt');
 expect(Formatters.currency(123456), 'R\$ 1.234,56');
 });

 test('USD + en usa separador de milhar norte-americano', () {
 Formatters.applySettings(currencyCode: 'USD', language: 'en');
 expect(Formatters.currency(123456), 'US\$ 1,234.56');
 });

 test('EUR mantém vírgula decimal em pt', () {
 Formatters.applySettings(currencyCode: 'EUR', language: 'pt');
 expect(Formatters.currency(123450), '€ 1.234,50');
 });

 test('MZN (metical) tem símbolo próprio', () {
 Formatters.applySettings(currencyCode: 'MZN', language: 'en');
 expect(Formatters.currency(500000), 'MZN 5,000.00');
 });

 test('currencyFor formata numa moeda EXPLÍCITA (usado no onboarding)', () {
 // Independe do estado global: formata a moeda pedida (pt).
 expect(Formatters.currencyFor('MZN', 50000), 'MZN 500,00');
 expect(Formatters.currencyFor('BRL', 50000), 'R\$ 500,00');
 expect(Formatters.currencyFor('USD', 100000), 'US\$ 1.000,00');
 // O idioma também pode ser explicitado (onboarding en):
 expect(
 Formatters.currencyFor('MZN', 100000, language: 'en'),
 'MZN 1,000.00',
 );
 // O estado global continua o que era (BRL default estático).
 expect(Formatters.currentCurrencyCode, 'BRL');
 });
 });

 group('day (idioma ativo)', () {
 test('hoje segue o idioma pt', () {
 expect(Formatters.day(DateTime.now()), 'Hoje');
 });

 test('hoje segue o idioma en', () {
 Formatters.applySettings(currencyCode: 'USD', language: 'en');
 expect(Formatters.day(DateTime.now()), 'Today');
 });
 });

 group('time (HH:mm)', () {
 test('formata hora e minuto com zero à esquerda', () {
 expect(Formatters.time(DateTime(2026, 8, 3, 9, 5)), '09:05');
 expect(Formatters.time(DateTime(2026, 8, 3, 14, 30)), '14:30');
 expect(Formatters.time(DateTime(2026, 8, 3, 0, 0)), '00:00');
 expect(Formatters.time(DateTime(2026, 8, 3, 23, 59)), '23:59');
 });

 test('independe do idioma ativo (só hora local)', () {
 Formatters.applySettings(currencyCode: 'USD', language: 'en');
 expect(Formatters.time(DateTime(2026, 8, 3, 11, 4)), '11:04');
 });
 });

 group('entityNumber (id amigável, estável e sem banco)', () {
 test('formato: # + 6 dígitos com zero à esquerda', () {
 expect(Formatters.entityNumber('s1'), matches(RegExp(r'^#\d{6}$')));
 });

 test('determinístico: mesma entidade, mesmo número', () {
 const id = 'shl34bebegm_bdd308';
 expect(Formatters.entityNumber(id), Formatters.entityNumber(id));
 });

 test('ids distintos geram números distintos', () {
 expect(
 Formatters.entityNumber('s1'),
 isNot(Formatters.entityNumber('s2')),
 );
 });

 test('vale para qualquer entidade (venda, compra, dívida, caixa)', () {
 // Venda, compra, dívida e movimentação com ids de teste.
 expect(Formatters.entityNumber('s1'), '#573449');
 expect(Formatters.entityNumber('c1'), '#445657');
 expect(Formatters.entityNumber('d1'), '#607014');
 expect(Formatters.entityNumber('t1'), '#734806');
 });

 test('valores fixos (algoritmo FNV-1a 32-bit)', () {
 expect(Formatters.entityNumber('shl34bebegm_bdd308'), '#640185');
 });
 });

 group('saleLabel (número SEQUENCIAL por loja — S-00001)', () {
 test('formata com 5 dígitos e zero à esquerda', () {
 expect(Formatters.saleLabel(1), 'S-00001');
 expect(Formatters.saleLabel(42), 'S-00042');
 expect(Formatters.saleLabel(99999), 'S-99999');
 });

 test('não trunca números acima de 5 dígitos', () {
 expect(Formatters.saleLabel(100000), 'S-100000');
 });

 test('número 0 (default, nunca persistido) formata S-00000', () {
 expect(Formatters.saleLabel(0), 'S-00000');
 });
 });

 group('purchaseLabel (número SEQUENCIAL por loja — C-00001)', () {
 test('formata com 5 dígitos e zero à esquerda', () {
 expect(Formatters.purchaseLabel(1), 'C-00001');
 expect(Formatters.purchaseLabel(42), 'C-00042');
 expect(Formatters.purchaseLabel(99999), 'C-99999');
 });

 test('não trunca números acima de 5 dígitos', () {
 expect(Formatters.purchaseLabel(100000), 'C-100000');
 });

 test('número 0 (default, nunca persistido) formata C-00000', () {
 expect(Formatters.purchaseLabel(0), 'C-00000');
 });
 });

 group('debtLabel (número SEQUENCIAL por loja — D-00001)', () {
 test('formata com 5 dígitos e zero à esquerda', () {
 expect(Formatters.debtLabel(1), 'D-00001');
 expect(Formatters.debtLabel(42), 'D-00042');
 expect(Formatters.debtLabel(99999), 'D-99999');
 });

 test('não trunca números acima de 5 dígitos', () {
 expect(Formatters.debtLabel(100000), 'D-100000');
 });

 test('número 0 (default, nunca persistido) formata D-00000', () {
 expect(Formatters.debtLabel(0), 'D-00000');
 });
 });
}

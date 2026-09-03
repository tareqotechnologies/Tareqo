import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/ids.dart';

void main() {
 test('newId gera ids distintos entre chamadas consecutivas', () {
 final first = AppIds.newId('p');
 final second = AppIds.newId('p');
 final third = AppIds.newId('p');

 expect(first, isNot(second));
 expect(second, isNot(third));
 expect(first, isNot(third));
 });

 test('newId usa o prefixo informado', () {
 expect(AppIds.newId('s'), startsWith('s'));
 expect(AppIds.newId('t'), startsWith('t'));
 expect(AppIds.newId('pc'), startsWith('pc'));
 });

 test('newId não contém caracteres inválidos para chave primária TEXT', () {
 // Base 36 (a-z0-9) + separador '_' — seguro para TEXT PK e URLs.
 final id = AppIds.newId('s');
 expect(RegExp(r'^[a-z0-9_]+$').hasMatch(id), isTrue);
 expect(id.length, greaterThan(10));
 });

 test('ids de categorias diferentes nunca colidem (prefixo distinto)', () {
 expect(AppIds.newId('s'), isNot(AppIds.newId('t')));
 });
}

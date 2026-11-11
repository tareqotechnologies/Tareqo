import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

/// Auditoria P0-2 (tipografia): o pacote `pdf` NÃO seleciona o eixo `wght`
/// da Outfit variável (instância padrão Thin, w100) — os PDFs embutem as
/// estáticas Regular (corpo) e Bold (títulos). Sem uma fonte `bold`
/// registrada em `pw.ThemeData.withFont`, todo `pw.FontWeight.bold` caía na
/// base e as facturas/relatórios saíam sem hierarquia de peso.
///
/// Este teste trava a correção: com `bold:` registrado, o documento embute
/// (e usa) o TTF estático Outfit-Bold — visível no nome BaseFont dentro do
/// PDF. Sem o registro, só a base aparece.
bool _contains(List<int> haystack, List<int> needle) {
  if (needle.length > haystack.length) return false;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

List<int> _latin(String s) => s.codeUnits;

Future<Uint8List> _buildDoc({required bool registerBold}) async {
  final baseData = File('assets/fonts/Outfit-Regular.ttf').readAsBytesSync();
  final boldData = File('assets/fonts/Outfit-Bold.ttf').readAsBytesSync();
  final base = pw.Font.ttf(ByteData.view(baseData.buffer));
  final bold = pw.Font.ttf(ByteData.view(boldData.buffer));

  final doc = pw.Document(
    theme: registerBold
        ? pw.ThemeData.withFont(base: base, bold: bold)
        : pw.ThemeData.withFont(base: base),
  );
  doc.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Paragraph(
            text: 'Total',
            style: const pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Paragraph(text: '1 x Fatura 1.500,00 MZN'),
        ],
      ),
    ),
  );
  return doc.save();
}

void main() {
  test(
    'Outfit-Bold.ttf é um TTF estático válido (instância, não variável)',
    () {
      final bytes = File('assets/fonts/Outfit-Bold.ttf').readAsBytesSync();
      // Magic number TTF: 0x00010000.
      expect(bytes[0], 0x00);
      expect(bytes[1], 0x01);
      expect(bytes[2], 0x00);
      expect(bytes[3], 0x00);
      // Instância ESTÁTICA: não contém a tabela `fvar` (eixos variáveis).
      // É isso que o dart_pdf precisa — ele não seleciona o eixo wght.
      expect(
        _contains(bytes, _latin('fvar')),
        isFalse,
        reason: 'Outfit-Bold deve ser uma instância estática (sem tabela fvar)',
      );
    },
  );

  test(
    'sem bold registrado, o PDF só embute a base (estado antigo — bug)',
    () async {
      final bytes = await _buildDoc(registerBold: false);
      expect(_contains(bytes, _latin('Outfit')), isTrue);
      expect(
        _contains(bytes, _latin('Outfit-Bold')),
        isFalse,
        reason: 'sem withFont(bold:) o bold cai na base — é o bug corrigido',
      );
    },
  );

  test(
    'com bold registrado, os pesos bold embutem o Outfit-Bold real',
    () async {
      final bytes = await _buildDoc(registerBold: true);
      expect(
        _contains(bytes, _latin('Outfit')),
        isTrue,
        reason: 'base Regular continua embutida para o texto normal',
      );
      expect(
        _contains(bytes, _latin('Outfit-Bold')),
        isTrue,
        reason: 'os títulos em bold devem usar o TTF estático Outfit-Bold',
      );
    },
  );
}

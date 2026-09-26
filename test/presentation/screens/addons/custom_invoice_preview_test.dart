import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/screens/addons/custom_invoice_preview.dart';

import '../../../helpers/test_app.dart';

/// Testes do preview estático da factura personalizada — o mesmo desenho
/// do PDF exportado, renderizado dentro do sheet de modelo.
void main() {
  Widget buildPreview({
    String businessName = 'Farmácia Vida',
    String businessAddress = 'Av. Julius Nyerere, 123',
    String businessPhone = '84 123 4567',
    String businessTaxId = '123456789',
  }) {
    return testApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CustomInvoicePreview(
            businessName: businessName,
            businessAddress: businessAddress,
            businessPhone: businessPhone,
            businessTaxId: businessTaxId,
            primaryColor: const Color(0xFF3D4D55),
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza empresa, cliente, itens e total de amostra', (
    tester,
  ) async {
    await tester.pumpWidget(buildPreview());
    await tester.pumpAndSettle();

    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Av. Julius Nyerere, 123'), findsOneWidget);
    expect(find.text('84 123 4567'), findsOneWidget);
    expect(find.text('NIF: 123456789'), findsOneWidget);
    // Badge e cliente fixos da amostra.
    expect(find.text('FACTURA'), findsOneWidget);
    expect(find.text('CLIENTE'), findsOneWidget);
    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Tel: 84 123 4567'), findsOneWidget);
    // Itens de amostra com preços fixos.
    expect(find.text('Produto A'), findsOneWidget);
    expect(find.text('Produto B'), findsOneWidget);
    expect(find.text('TOTAL: 550,00 MT'), findsOneWidget);
    expect(find.text('Gerado pelo TAREQO'), findsOneWidget);
    // Número sequencial fixo + data DINÂMICA (não mais 03/09/2026 fixa).
    expect(find.textContaining('Nº 00001'), findsOneWidget);
    expect(find.text('03/09/2026'), findsNothing);
  });

  testWidgets('símbolo monetário segue o parâmetro (default MT)', (
    tester,
  ) async {
    // Default: amostra do metical (moeda base do produto).
    await tester.pumpWidget(buildPreview());
    await tester.pumpAndSettle();
    expect(find.text('TOTAL: 550,00 MT'), findsOneWidget);

    // Símbolo explícito: moeda ativa do tenant aparece nos preços.
    await tester.pumpWidget(
      testApp(
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CustomInvoicePreview(
              businessName: 'Loja Teste',
              businessAddress: '',
              businessPhone: '',
              businessTaxId: '',
              primaryColor: Color(0xFF3D4D55),
              currencySymbol: r'R$',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r'TOTAL: 550,00 R$'), findsOneWidget);
    expect(find.text(r'150,00 R$'), findsOneWidget);
  });

  testWidgets('nome vazio cai no fallback "Nome da Empresa"', (tester) async {
    await tester.pumpWidget(buildPreview(businessName: ''));
    await tester.pumpAndSettle();

    expect(find.text('Nome da Empresa'), findsOneWidget);
  });

  testWidgets('campos opcionais vazios não renderizam linha', (tester) async {
    await tester.pumpWidget(
      buildPreview(businessAddress: '', businessPhone: '', businessTaxId: ''),
    );
    await tester.pumpAndSettle();

    // Sem endereço/NIF do negócio; a linha "Tel:" do cliente fixo
    // (João Silva, amostra) continua — só a do CABEÇALHO desaparece,
    // que é indistinguível por texto (mesma string) — validamos por
    // contagem: 1 linha "Tel:" (cliente) em vez de 2 (cliente + negócio).
    expect(find.text('Av. Julius Nyerere, 123'), findsNothing);
    expect(find.text('NIF: 123456789'), findsNothing);
    expect(find.text('Tel: 84 123 4567'), findsOneWidget);
    expect(find.text('84 123 4567'), findsNothing);
    expect(find.text('João Silva'), findsOneWidget);
  });
}

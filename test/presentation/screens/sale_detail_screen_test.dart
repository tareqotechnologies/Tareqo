import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/presentation/screens/sales/sale_detail_screen.dart';

void main() {
  testWidgets('exibe resumo, itens com preço unitário e subtotais', (
    tester,
  ) async {
    final sale = Sale(
      id: 's1',
      items: const [
        SaleItem(
          productId: 'p1',
          productName: 'Caneta',
          quantity: 2,
          unitPriceCents: 200,
        ),
        SaleItem(
          productId: 'p2',
          productName: 'Caderno',
          quantity: 1,
          unitPriceCents: 990,
        ),
      ],
      totalAmountCents: 1390,
      paymentMethod: PaymentMethod.pix,
      dateTime: DateTime(2026, 8, 3, 14, 30),
    );

    await tester.pumpWidget(testApp(home: SaleDetailScreen(sale: sale)));

    // Resumo.
    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Venda s1'), findsOneWidget);
    expect(find.text('Pix'), findsOneWidget);

    // Itens com quantidade × preço unitário e subtotal.
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('2 × R\$ 2,00'), findsOneWidget);
    expect(find.text('R\$ 4,00'), findsOneWidget); // subtotal de Caneta
    expect(find.text('Caderno'), findsOneWidget);
    expect(find.text('1 × R\$ 9,90'), findsOneWidget);

    // Total (resumo + rodapé) e nota de snapshot.
    expect(find.text('R\$ 13,90'), findsNWidgets(2));
    expect(find.text('Preços congelados no momento da venda.'), findsOneWidget);
  });
}

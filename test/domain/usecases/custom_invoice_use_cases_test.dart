import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/usecases/custom_invoice_use_cases.dart';

void main() {
 group('CreateCustomInvoiceUseCase', () {
  const useCase = CreateCustomInvoiceUseCase();

  test('calcula totais em centavos (subtotal + IVA - desconto)', () {
   final invoice = useCase.call(
    storeId: 's1',
    clientName: 'Loja Central',
    items: const [
     CustomInvoiceItemInput(
      productName: 'Caneta',
      quantity: 2,
      unitPriceCents: 1500, // MZN 15,00
     ),
     CustomInvoiceItemInput(
      productName: 'Caderno',
      quantity: 1,
      unitPriceCents: 4500, // MZN 45,00
     ),
    ],
    discountCents: 500, // MZN 5,00
    taxCents: 1000, // MZN 10,00
   );

   // Subtotal 7.500 + IVA 1.000 - desconto 500 = 8.000.
   expect(invoice.totalAmountCents, 8000);
   expect(invoice.discountCents, 500);
   expect(invoice.taxCents, 1000);
   expect(invoice.items, hasLength(2));
   expect(invoice.items.first.subtotalCents, 3000);
   expect(invoice.items.last.subtotalCents, 4500);
  });

  test('desconto maior que o subtotal nunca gera total negativo (clamp 0)',
      () {
   final invoice = useCase.call(
    storeId: 's1',
    clientName: 'Cliente A',
    items: const [
     CustomInvoiceItemInput(
      productName: 'Caneta',
      quantity: 1,
      unitPriceCents: 1000,
     ),
    ],
    discountCents: 5000,
   );

   expect(invoice.totalAmountCents, 0);
  });

  test('rejeita factura sem itens', () {
   expect(
    () => useCase.call(storeId: 's1', clientName: 'A', items: const []),
    throwsArgumentError,
   );
  });

  test('rejeita cliente sem nome', () {
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: '   ',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
    ),
    throwsArgumentError,
   );
  });

  test('rejeita quantidade zero ou negativa', () {
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: 0,
       unitPriceCents: 100,
      ),
     ],
    ),
    throwsArgumentError,
   );
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: -2,
       unitPriceCents: 100,
      ),
     ],
    ),
    throwsArgumentError,
   );
  });

  test('rejeita preço unitário negativo, desconto negativo e IVA negativo',
      () {
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: 1,
       unitPriceCents: -1,
      ),
     ],
    ),
    throwsArgumentError,
   );
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
     discountCents: -1,
    ),
    throwsArgumentError,
   );
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: 'X',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
     taxCents: -1,
    ),
    throwsArgumentError,
   );
  });

  test('rejeita item sem nome', () {
   expect(
    () => useCase.call(
     storeId: 's1',
     clientName: 'A',
     items: const [
      CustomInvoiceItemInput(
       productName: ' ',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
    ),
    throwsArgumentError,
   );
  });
 });
}

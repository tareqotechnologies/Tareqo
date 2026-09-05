import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/quotation.dart';
import 'package:tareqo/domain/usecases/quotation_use_cases.dart';

const _customer = Customer(id: 'c1', name: 'Cliente A', phone: '841234567');

void main() {
 group('CreateQuotationUseCase', () {
  const useCase = CreateQuotationUseCase();

  test('calcula o total em centavos e aplica a validade padrão (7 dias)', () {
   final quote = useCase.call(
    storeId: 's1',
    customer: _customer,
    items: const [
     QuotationItemInput(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 2,
      unitPriceCents: 1500,
     ),
     QuotationItemInput(
      productId: 'p2',
      productName: 'Caderno',
      quantity: 1,
      unitPriceCents: 4500,
     ),
    ],
   );

   expect(quote.totalAmountCents, 7500);
   expect(quote.discountCents, 0);
   expect(quote.customerName, 'Cliente A');
   expect(quote.items, hasLength(2));
   // Validade: agora + 7 dias (no mesmo instante de criação).
   final expected = DateTime.now().add(const Duration(days: 7));
   final delta = quote.validUntil
       .difference(expected)
       .inSeconds
       .abs();
   expect(delta, lessThanOrEqualTo(1));
  });

  test('desconto aplicado em centavos e nunca gera total negativo', () {
   final quote = useCase.call(
    storeId: 's1',
    customer: _customer,
    items: const [
     QuotationItemInput(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1,
      unitPriceCents: 1000,
     ),
    ],
    discountCents: 1500, // desconto maior que o subtotal
   );

   expect(quote.totalAmountCents, 0);
   expect(quote.discountCents, 1500);
  });

  test('rejeita cotação sem itens e cliente sem nome', () {
   expect(
    () => useCase.call(storeId: 's1', customer: _customer, items: const []),
    throwsArgumentError,
   );
   expect(
    () => useCase.call(
     storeId: 's1',
     customer: const Customer(id: 'c2', name: '  '),
     items: const [
      QuotationItemInput(
       productId: 'p1',
       productName: 'X',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
    ),
    throwsArgumentError,
   );
  });

  test('rejeita quantidade/valor inválidos, desconto negativo e validade ≤ 0',
      () {
   expect(
    () => useCase.call(
     storeId: 's1',
     customer: _customer,
     items: const [
      QuotationItemInput(
       productId: 'p1',
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
     customer: _customer,
     items: const [
      QuotationItemInput(
       productId: 'p1',
       productName: 'X',
       quantity: 1,
       unitPriceCents: -5,
      ),
     ],
    ),
    throwsArgumentError,
   );
   expect(
    () => useCase.call(
     storeId: 's1',
     customer: _customer,
     items: const [
      QuotationItemInput(
       productId: 'p1',
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
     customer: _customer,
     items: const [
      QuotationItemInput(
       productId: 'p1',
       productName: 'X',
       quantity: 1,
       unitPriceCents: 100,
      ),
     ],
     validityDays: 0,
    ),
    throwsArgumentError,
   );
  });
 });

 group('ConvertQuotationToSaleUseCase', () {
  const useCase = ConvertQuotationToSaleUseCase();

  Quotation quote(QuotationStatus status) => Quotation(
    id: 'q1',
    storeId: 's1',
    customerId: 'c1',
    customerName: 'Cliente A',
    items: const [
     QuotationItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1,
      unitPriceCents: 1500,
     ),
    ],
    totalAmountCents: 1500,
    status: status,
    validUntil: DateTime.now().add(const Duration(days: 7)),
    createdAt: DateTime.now(),
   );

  test('só converte cotação aceite', () {
   for (final status in QuotationStatus.values) {
    if (status == QuotationStatus.accepted) continue;
    expect(
     () => useCase.prepareSaleItems(quote(status)),
     throwsStateError,
     reason: 'status $status',
    );
   }
  });

  test('converte itens da cotação aceite em itens de venda', () {
   final items = useCase.prepareSaleItems(quote(QuotationStatus.accepted));

   expect(items, hasLength(1));
   expect(items.first.productId, 'p1');
   expect(items.first.productName, 'Caneta');
   expect(items.first.quantity, 1);
   expect(items.first.unitPriceCents, 1500);
  });

  test('rejeita cotação aceite sem itens', () {
   final empty = quote(QuotationStatus.accepted).copyWith(items: const []);

   expect(() => useCase.prepareSaleItems(empty), throwsStateError);
  });
 });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/quotation.dart';
import 'package:tareqo/domain/usecases/quotation_use_cases.dart';

const _customer = Customer(id: 'c1', name: 'Cliente A', phone: '841234567');

void main() {
  group('CreateQuotationUseCase', () {
    const useCase = CreateQuotationUseCase();

    test('calcula o total em centavos (qty em MILÉSIMOS) e validade padrão', () {
      // Quantidade em milésimos (W11): 2000 = 2 unidades, 1000 = 1 kg.
      final quote = useCase.call(
        storeId: 's1',
        customer: _customer,
        items: const [
          QuotationItemInput(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 2000,
            unitPriceCents: 1500,
          ),
          QuotationItemInput(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 1000,
            unitPriceCents: 4500,
          ),
        ],
      );

      // 2 × 15,00 + 1 × 45,00 = 75,00 → 7500 centavos (NÃO 7.500.000 —
      // regressão do bug de unidades onde o total saía 1000× maior).
      expect(quote.totalAmountCents, 7500);
      expect(quote.discountCents, 0);
      expect(quote.customerName, 'Cliente A');
      expect(quote.items, hasLength(2));
      // Validade: agora + 7 dias (no mesmo instante de criação).
      final expected = DateTime.now().add(const Duration(days: 7));
      final delta = quote.validUntil.difference(expected).inSeconds.abs();
      expect(delta, lessThanOrEqualTo(1));
    });

    test('fração de milésimos (peso/granel) calcula subtotal proporcional', () {
      // 1,5 kg × 10,00 = 15,00 → 1500 centavos.
      final quote = useCase.call(
        storeId: 's1',
        customer: _customer,
        items: const [
          QuotationItemInput(
            productId: 'p1',
            productName: 'Arroz a granel',
            quantity: 1500,
            unitPriceCents: 1000,
          ),
        ],
      );

      expect(quote.totalAmountCents, 1500);
      // A entidade preserva a quantidade em milésimos original.
      expect(quote.items.single.quantity, 1500);
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
        discountCents: 1500, // desconto maior que o subtotal (1 un = 1000 mil)
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

    test(
      'rejeita quantidade/valor inválidos, desconto negativo e validade ≤ 0',
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
      },
    );
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

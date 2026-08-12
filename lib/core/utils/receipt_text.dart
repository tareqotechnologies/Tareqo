import '../../domain/entities/sale.dart';
import '../i18n/transaction_descriptions.dart';
import 'formatters.dart';
import 'quantity.dart';

/// Texto PLAIN TEXT do recibo de venda — usado na partilha via WhatsApp
/// (`https://wa.me/?text=...`). Função pura, sem dependência de UI:
/// recebe o idioma ativo (mesma convenção do [TransactionDescriptions], que
/// o domínio usa para descrições gravadas no banco) e formata com os
/// mesmos helpers da tela ([Formatters] e [Quantity]).
///
/// O texto espelha o visual do [SaleReceiptView] (título, número da venda,
/// itens com `quantidade × unitário = subtotal`, total, pagamento e
/// agradecimento) — se um lado mudar, o outro deve mudar junto.
abstract final class ReceiptText {
  /// Monta o recibo em texto. [storeName]/[storeAddress] (opcionais) formam
  /// o cabeçalho do estabelecimento; vendas anuladas ganham a marca
  /// `(ANULADA)` ao lado do título.
  static String build({
    required Sale sale,
    String? storeName,
    String? storeAddress,
    required String language,
  }) {
    final buffer = StringBuffer();
    final cancelled = sale.status == SaleStatus.cancelled;

    // Cabeçalho do estabelecimento (nome + endereço, se disponíveis).
    if (storeName != null && storeName.trim().isNotEmpty) {
      buffer.writeln(storeName.toUpperCase());
      if (storeAddress != null && storeAddress.trim().isNotEmpty) {
        buffer.writeln(storeAddress);
      }
      buffer.writeln();
    }

    buffer.writeln(language == 'en' ? 'SALE RECEIPT' : 'RECIBO DE VENDA');
    final saleLabel = Formatters.saleLabel(sale.number);
    buffer.writeln(
      '${language == 'en' ? 'Sale' : 'Venda'} $saleLabel — '
      '${Formatters.dateTime(sale.dateTime)}',
    );
    if (cancelled) {
      buffer.writeln(language == 'en' ? '(CANCELLED)' : '(ANULADA)');
    }
    buffer.writeln();

    for (final item in sale.items) {
      buffer.writeln(item.productName);
      final qty = Quantity.format(item.quantity, language: language);
      final unit = Formatters.currency(item.unitPriceCents);
      final subtotal = Formatters.currency(
        Quantity.lineTotal(item.quantity, item.unitPriceCents),
      );
      buffer.writeln('  $qty × $unit = $subtotal');
    }
    buffer.writeln();

    buffer.writeln('Total: ${Formatters.currency(sale.totalAmountCents)}');
    buffer.writeln(
      '${language == 'en' ? 'Payment' : 'Pagamento'}: '
      '${TransactionDescriptions.paymentMethodName(language, sale.paymentMethod)}',
    );
    buffer.writeln();
    buffer.writeln(
      language == 'en'
          ? 'Thank you for your purchase!'
          : 'Obrigado pela preferência!',
    );

    return buffer.toString();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/pos/domain/pos_models.dart';
import 'package:invoiceandbilling/features/printing/domain/printer_models.dart';

void main() {
  test('encodes receipt lines as ESC/POS bytes', () {
    final bytes = EscPos58mmEncoder().encode(const [
      ReceiptLine(content: 'Mix & Sip', bold: true, align: 1, format: 3),
    ]);

    expect(bytes.take(2), [0x1B, 0x40]);
    expect(bytes, containsAllInOrder('Mix & Sip'.codeUnits));
    expect(bytes.last, 0x0A);
  });

  test('builds a complete local receipt when the API has no receipt block', () {
    const product = Product(
      id: 1,
      name: 'Coffee',
      code: 'C1',
      price: 5,
      stock: 10,
    );
    final result = SaleResult.fromJson(
      {
        'order': {
          'id': 12,
          'invoice_no': 'INV-12',
          'order_date': '2026-07-16',
          'payment_status': 'Paid',
          'sub_total': 10,
          'vat': 0,
          'discount_percent': 0,
          'discount_amount': 0,
          'pay': 10,
          'due': 0,
          'last_tendered': 20,
          'last_change': 10,
          'total': 10,
          'customer': {'name': 'Walk-in'},
        },
      },
      cart: const [CartLine(product, 2)],
    );

    final text = result.receiptLines.map((line) => line.content).join('\n');
    expect(text, contains('Invoice #INV-12'));
    expect(text, contains('2   Coffee'));
    expect(text, contains('TOTAL: \$10.00'));
  });
}

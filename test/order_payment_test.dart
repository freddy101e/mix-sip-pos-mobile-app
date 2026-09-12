import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/orders/domain/order_payment.dart';

void main() {
  test('parses an immutable order payment', () {
    final payment = OrderPayment.fromJson({
      'id': 4,
      'type': 'balance',
      'amount': '30.00',
      'tendered': 50,
      'change': 20,
      'payment_method': 'Cash',
      'paid_at': '2026-09-04T20:50:00-06:00',
      'user': {'name': 'Cashier'},
    });

    expect(payment.amount, 30);
    expect(payment.change, 20);
    expect(payment.user, 'Cashier');
  });
}

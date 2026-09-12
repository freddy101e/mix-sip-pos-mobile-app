import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/orders/domain/order_summary.dart';

void main() {
  test('reads and formats an order creation timestamp', () {
    final order = OrderSummary.fromJson({
      'id': 485,
      'invoice_no': 'INV-000485',
      'order_date': '2026-09-04',
      'created_at': '2026-09-04T20:50:00',
    });

    expect(order.date, '2026-09-04');
    expect(order.createdTimeLabel, '8:50 PM');
  });

  test('does not show a midnight badge for a date-only order', () {
    final order = OrderSummary.fromJson({
      'id': 485,
      'order_date': '2026-09-04',
    });

    expect(order.createdTimeLabel, isEmpty);
  });

  test('only cash-customer pending orders are editable', () {
    OrderSummary order(String customer, String status) =>
        OrderSummary.fromJson({
          'id': 1,
          'customer': {'name': customer},
          'order_status': status,
        });

    expect(order('BMP-CASH-CUSTOMER', 'pending').canEditPendingOrder, isTrue);
    expect(order('Jasmine Godoy', 'pending').canEditPendingOrder, isFalse);
    expect(order('BMP-CASH-CUSTOMER', 'complete').canEditPendingOrder, isFalse);
  });

  test('reads the receipt print count', () {
    final order = OrderSummary.fromJson({'id': 1, 'print_count': 3});

    expect(order.printCount, 3);
  });

  test('reads the order edit count', () {
    final order = OrderSummary.fromJson({'id': 1, 'edit_count': 2});

    expect(order.editCount, 2);
  });

  test('formats the date an order was completed', () {
    final order = OrderSummary.fromJson({
      'id': 1,
      'completed_at': '2026-09-04T20:50:00',
    });

    expect(order.completedTimeLabel, 'Paid 9/4 8:50 PM');
  });
}

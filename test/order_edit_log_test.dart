import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/orders/domain/order_edit_log.dart';

void main() {
  test('parses before and after order snapshots', () {
    final log = OrderEditLog.fromJson({
      'id': 7,
      'user': {'name': 'Admin'},
      'created_at': '2026-09-04T20:15:00-06:00',
      'before': {
        'total': 7,
        'due': 7,
        'lines': [
          {
            'product_id': '1',
            'product_name': 'Latte',
            'quantity': 1,
            'unitcost': 7,
            'total': 7,
          },
        ],
      },
      'after': {
        'total': 14,
        'due': 14,
        'lines': [
          {
            'product_id': 1,
            'product_name': 'Latte',
            'quantity': 2,
            'unitcost': 7,
            'total': 14,
          },
        ],
      },
    });

    expect(log.editor, 'Admin');
    expect(log.before.lines.single.quantity, 1);
    expect(log.before.lines.single.productId, 1);
    expect(log.after.lines.single.quantity, 2);
    expect(log.after.total, 14);
  });
}

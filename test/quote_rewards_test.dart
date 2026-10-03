import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/core/errors/app_exception.dart';
import 'package:invoiceandbilling/features/pos/domain/pos_models.dart';
import 'package:invoiceandbilling/features/pos/data/pos_repository.dart';
import 'package:invoiceandbilling/features/pos/presentation/controllers/pos_controller.dart';

class DelayedQuotes extends Fake implements PosDataSource {
  final pending = Completer<PosQuote>();
  @override
  Future<PosQuote> quote(Customer customer, List<CartLine> lines) =>
      pending.future;
}

void main() {
  const product = Product(
    id: 1,
    name: 'Nachos',
    code: 'N',
    price: 10,
    stock: 20,
  );
  const customer = Customer(
    id: 26,
    name: 'BMP-CASH-CUSTOMER',
    discountPercent: 0,
  );
  for (final reason in ['birthday', 'loyalty_card']) {
    test('rejects a hosted quote that ignores $reason', () {
      expect(
        () => PosQuote.validateFreeLines(
          {
            'lines': [
              {'product_id': 1, 'quantity': 2, 'unit_price': 10, 'total': 20},
            ],
          },
          [
            CartLine(product, 1),
            CartLine(product, 1, complimentaryReason: reason),
          ],
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => PosQuote.validateFreeLines(
          {
            'lines': [
              {
                'product_id': 1,
                'quantity': 1,
                'complimentary_reason': reason,
                'unit_price': 0,
                'total': 0,
              },
            ],
          },
          [
            CartLine(product, 1),
            CartLine(product, 1, complimentaryReason: reason),
          ],
        ),
        returnsNormally,
      );
    });
  }
  test(
    'does not restore old cart or quote when quantities change during request',
    () async {
      final repository = DelayedQuotes();
      final controller = PosController(repository);
      addTearDown(controller.dispose);
      controller.selectCustomer(customer);
      controller.add(product);
      final pending = controller.quote();
      controller.quantity(0, 2);
      repository.pending.complete(
        const PosQuote(subtotal: 10, discount: 0, tax: 0, total: 10),
      );
      await pending;
      expect(controller.state.cart.single.quantity, 2);
      expect(controller.state.quote, isNull);
      expect(controller.state.submitting, false);
    },
  );
}

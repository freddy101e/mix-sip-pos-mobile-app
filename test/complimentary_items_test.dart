import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/pos/domain/pos_models.dart';
import 'package:invoiceandbilling/features/pos/presentation/controllers/pos_controller.dart';
import 'package:invoiceandbilling/features/pos/data/pos_repository.dart';

class FakePos extends Fake implements PosDataSource {}

void main() {
  const drink = Product(
    id: 1,
    name: 'Drink',
    code: 'D',
    price: 12.5,
    stock: 20,
  );
  test(
    'splits selected units, preserves reasons and restores paid grouping',
    () {
      final controller = PosController(FakePos());
      addTearDown(controller.dispose);
      for (var i = 0; i < 5; i++) {
        controller.add(drink);
      }
      controller.markComplimentary(0, 2, 'birthday');
      controller.markComplimentary(0, 1, 'loyalty_card');
      expect(controller.state.cart.map((e) => e.quantity), [2, 2, 1]);
      expect(controller.state.cart.map((e) => e.total), [25, 0, 0]);
      controller.add(drink);
      expect(controller.state.cart.first.quantity, 3);
      controller.quantity(1, 3);
      expect(controller.state.cart[1].complimentaryReason, 'birthday');
      expect(controller.state.cart[1].total, 0);
      controller.markComplimentary(1, 3, null);
      expect(controller.state.cart.length, 2);
      expect(controller.state.cart.first.quantity, 6);
    },
  );
  test('rejects excess quantity and supports all free units', () {
    final controller = PosController(FakePos());
    addTearDown(controller.dispose);
    controller.add(drink);
    controller.markComplimentary(0, 2, 'birthday');
    expect(controller.state.cart.single.total, 12.5);
    controller.markComplimentary(0, 1, 'birthday');
    expect(controller.state.cart.single.total, 0);
    expect(controller.state.cart.single.complimentaryLabel, 'Birthday treat');
    controller.add(drink);
    expect(controller.state.cart.length, 2);
  });
}

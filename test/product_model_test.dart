import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/pos/domain/pos_models.dart';

void main() {
  test('accepts the nullable stock returned by the Laravel product API', () {
    final product = Product.fromJson({
      'id': 40,
      'product_name': 'Banana oreo 16oz',
      'product_code': 'PC30',
      'selling_price': 9,
      'product_store': null,
    });

    expect(product.stock, 0);
    expect(product.price, 9);
  });
}

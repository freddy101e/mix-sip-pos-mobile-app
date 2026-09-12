import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/core/errors/app_exception.dart';
import 'package:invoiceandbilling/features/pos/data/pos_repository.dart';
import 'package:invoiceandbilling/features/pos/domain/pos_models.dart';
import 'package:invoiceandbilling/features/pos/presentation/controllers/pos_controller.dart';

void main() {
  test('only exposes BMP-CASH-CUSTOMER when creating an order', () async {
    final repository = _RetryingPosDataSource(
      customers: const [
        Customer(id: 1, name: 'Freddy', discountPercent: 0),
        Customer(id: 26, name: 'BMP-CASH-CUSTOMER', discountPercent: 0),
        Customer(id: 2, name: 'Jasmine Godoy', discountPercent: 0),
      ],
    );
    final controller = PosController(repository);

    await controller.load();

    expect(controller.state.customers, [repository.customer]);
    expect(controller.state.customer, repository.customer);
  });

  test('reuses one client reference when checkout is retried', () async {
    final repository = _RetryingPosDataSource();
    final controller = PosController(
      repository,
      referenceFactory: () => 'stable-sale-reference',
    );

    await controller.load();
    controller.add(repository.product);
    await controller.quote();

    expect(
      await controller.checkout('Cash', 10, loyaltyCardStatus: 'given'),
      isNull,
    );
    expect(
      (await controller.checkout(
        'Cash',
        10,
        loyaltyCardStatus: 'given',
      ))?.invoiceNumber,
      'INV-0001',
    );
    expect(repository.loyaltyResponses, ['given', 'given']);
    expect(repository.references, [
      'stable-sale-reference',
      'stable-sale-reference',
    ]);
    expect(controller.state.clientReference, isNull);
  });
}

class _RetryingPosDataSource implements PosDataSource {
  _RetryingPosDataSource({List<Customer>? customers})
    : customersResult =
          customers ??
          const [
            Customer(id: 26, name: 'BMP-CASH-CUSTOMER', discountPercent: 0),
          ];

  final product = const Product(
    id: 1,
    name: 'Test drink',
    code: 'T1',
    price: 10,
    stock: 5,
  );
  Customer get customer => customersResult.singleWhere(
    (customer) => customer.name == PosController.cashCustomerName,
  );
  final List<Customer> customersResult;
  final references = <String>[];
  final loyaltyResponses = <String?>[];

  @override
  Future<List<Customer>> customers() async => customersResult;

  @override
  Future<List<Product>> products(String query) async => [product];

  @override
  Future<PosQuote> quote(Customer customer, List<CartLine> lines) async =>
      const PosQuote(subtotal: 10, discount: 0, tax: 0, total: 10);

  @override
  Future<SaleResult> checkout(
    Customer customer,
    List<CartLine> lines,
    PosQuote quote,
    String method,
    double tendered,
    String orderReference,
    String clientReference, {
    String? loyaltyCardStatus,
  }) async {
    references.add(clientReference);
    loyaltyResponses.add(loyaltyCardStatus);
    if (references.length == 1) {
      throw const AppException('The request timed out. Please try again.');
    }
    return const SaleResult(
      orderId: 1,
      invoiceNumber: 'INV-0001',
      status: 'complete',
      due: 0,
      receiptLines: [],
    );
  }
}

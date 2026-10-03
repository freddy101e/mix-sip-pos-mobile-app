import '../../../core/errors/app_exception.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_error_parser.dart';
import '../domain/pos_models.dart';

abstract interface class PosDataSource {
  Future<List<Product>> products(String query);
  Future<List<Customer>> customers();
  Future<PosQuote> quote(Customer customer, List<CartLine> lines);
  Future<SaleResult> checkout(
    Customer customer,
    List<CartLine> lines,
    PosQuote quote,
    String method,
    double tendered,
    String orderReference,
    String clientReference, {
    String? loyaltyCardStatus,
  });
}

class PosRepository implements PosDataSource {
  const PosRepository(this._api);
  final ApiClient _api;

  Future<bool> loyaltyReminderActive() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/pos/loyalty-cards',
      );
      return (response.data!['data'] as Map<String, dynamic>)['active'] == true;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }

  Future<void> markPrinted(int orderId) async {
    try {
      await _api.dio.post<void>('/orders/$orderId/printed');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<List<Product>> products(String query) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>(
        '/pos/products',
        queryParameters: {'q': query, 'per_page': 40},
      );
      return (r.data!['data'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<List<Customer>> customers() async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>(
        '/pos/customers',
        queryParameters: {'per_page': 50},
      );
      return (r.data!['data'] as List)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }

  Map<String, dynamic> payload(Customer customer, List<CartLine> lines) => {
    'customer_id': customer.id,
    'discount_percent': customer.discountPercent,
    'lines': lines
        .map(
          (e) => {
            'product_id': e.product.id,
            'quantity': e.quantity,
            'complimentary_reason': e.complimentaryReason,
          },
        )
        .toList(),
  };
  @override
  Future<PosQuote> quote(Customer customer, List<CartLine> lines) async {
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/pos/quote',
        data: payload(customer, lines),
      );
      final data = r.data!['data'] as Map<String, dynamic>;
      PosQuote.validateFreeLines(data, lines);
      return PosQuote.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }

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
    try {
      final r = await _api.dio.post<Map<String, dynamic>>(
        '/pos/sales',
        data: {
          ...payload(customer, lines),
          'client_reference': clientReference,
          if (loyaltyCardStatus != null)
            'loyalty_card_status': loyaltyCardStatus,
          'payment_method': method,
          'order_reference': orderReference.trim(),
          // Laravel derives the order status from `due = total - pay`.
          // Applying no more than the invoice total lets a zero or partial
          // tender create a pending sale instead of forcing full payment.
          'pay': tendered.clamp(0, quote.total),
          'tendered': tendered,
        },
      );
      return SaleResult.fromJson(
        r.data!['data'] as Map<String, dynamic>,
        cart: lines,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ApiErrorParser.parse(e);
    }
  }
}

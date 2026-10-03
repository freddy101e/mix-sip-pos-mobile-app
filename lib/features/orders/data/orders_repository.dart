import '../../../core/api/api_client.dart';
import '../../../core/api/api_error_parser.dart';
import '../../printing/domain/printer_models.dart';
import '../domain/order_summary.dart';
import '../domain/order_edit_log.dart';
import '../domain/order_payment.dart';

class OrdersRepository {
  const OrdersRepository(this._api);
  final ApiClient _api;
  Future<List<OrderSummary>> list(
    String filter, {
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>(
        '/orders/$filter',
        queryParameters: {
          'perPage': 50,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
      );
      return (r.data!['data'] as List)
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<Map<String, dynamic>> summary({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>(
        '/orders/summary',
        queryParameters: {
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
      );
      return r.data!['data'] as Map<String, dynamic>;
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<Map<String, dynamic>>> items(int id) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>('/orders/$id/items');
      return (r.data!['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<bool> loyaltyReminderActive() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/orders/loyalty-cards',
      );
      return (response.data!['data'] as Map<String, dynamic>)['active'] == true;
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<void> payDue(
    int id,
    double tendered,
    String method, {
    String? loyaltyCardStatus,
  }) async {
    try {
      await _api.dio.post<void>(
        '/orders/$id/pay-due',
        data: {
          'tendered': tendered,
          'payment_method': method,
          if (loyaltyCardStatus != null)
            'loyalty_card_status': loyaltyCardStatus,
        },
      );
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<void> markPrinted(int id) async {
    try {
      await _api.dio.post<void>('/orders/$id/printed');
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<OrderEditLog>> editHistory(int id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/orders/$id/edit-history',
      );
      return (response.data!['data'] as List)
          .map(
            (entry) =>
                OrderEditLog.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(growable: false);
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<OrderPayment>> payments(int id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/orders/$id');
      final order = response.data!['data'] as Map<String, dynamic>;
      return (order['payments'] as List? ?? const [])
          .map(
            (entry) =>
                OrderPayment.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(growable: false);
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<Map<String, dynamic>>> products(String query) async {
    try {
      final r = await _api.dio.get<Map<String, dynamic>>(
        '/pos/products',
        queryParameters: {'q': query, 'per_page': 30},
      );
      return (r.data!['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<void> updateOrder(int id, List<Map<String, dynamic>> lines) async {
    try {
      await _api.dio.put<void>('/orders/$id', data: {'lines': lines});
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<ReceiptLine>> receipt(
    OrderSummary summary,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/orders/${summary.id}',
      );
      final order = response.data!['data'] as Map<String, dynamic>;
      return _buildReceipt(order, summary, items);
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  List<ReceiptLine> _buildReceipt(
    Map<String, dynamic> order,
    OrderSummary summary,
    List<Map<String, dynamic>> items,
  ) {
    final customer = order['customer'] as Map<String, dynamic>?;
    final discount = _number(order['discount_amount']);
    final discountPercent = _number(order['discount_percent']);
    final tendered = _number(order['last_tendered']);
    final change = _number(order['last_change']);
    final lines = <ReceiptLine>[
      const ReceiptLine(content: 'Mix & Sip', bold: true, align: 1, format: 3),
      const ReceiptLine(content: ' '),
      ReceiptLine(
        content: 'Invoice #${order['invoice_no'] ?? summary.invoice}',
        bold: true,
      ),
      ReceiptLine(
        content: 'Invoice date: ${order['order_date'] ?? summary.date}',
      ),
      ReceiptLine(
        content: 'Customer: ${customer?['name'] ?? summary.customer}',
      ),
      const ReceiptLine(content: ' '),
      const ReceiptLine(content: 'Details', bold: true),
      ReceiptLine(
        content: 'Payment Status: ${order['payment_status'] ?? summary.status}',
      ),
      ReceiptLine(content: 'Sub Total: \$${_money(order['sub_total'])}'),
      ReceiptLine(content: 'GST: \$${_money(order['vat'])}'),
    ];

    if (discount > 0.00001) {
      final percent = discountPercent > 0.00001
          ? ' (${discountPercent.toStringAsFixed(2)}%)'
          : '';
      lines.add(
        ReceiptLine(
          content: 'Discount$percent: -\$${discount.toStringAsFixed(2)}',
        ),
      );
    }

    lines.addAll([
      ReceiptLine(content: 'Total Pay: \$${_money(order['pay'])}'),
      ReceiptLine(content: 'Due: \$${_money(order['due'])}'),
      if (tendered > 0)
        ReceiptLine(content: 'Last Tendered: \$${tendered.toStringAsFixed(2)}'),
      if (change > 0)
        ReceiptLine(content: 'Change: \$${change.toStringAsFixed(2)}'),
      const ReceiptLine(content: ' '),
      const ReceiptLine(content: '--------------------------------'),
      const ReceiptLine(
        content: 'Qty  Item                 Amount',
        bold: true,
      ),
      const ReceiptLine(content: '--------------------------------'),
      for (final item in items) ...[
        ReceiptLine(content: _itemLine(item)),
        if (item['complimentary_label'] != null)
          ReceiptLine(content: '${item['complimentary_label']} - FREE'),
      ],
      const ReceiptLine(content: ' '),
      ReceiptLine(
        content: 'TOTAL: \$${_money(order['total'] ?? summary.total)}',
        bold: true,
        align: 2,
        format: 2,
      ),
    ]);
    return lines;
  }

  static String _itemLine(Map<String, dynamic> item) {
    final rawQuantity = _number(item['quantity']);
    final quantityValue = rawQuantity == rawQuantity.roundToDouble()
        ? rawQuantity.toInt().toString()
        : rawQuantity.toString();
    final quantity = quantityValue.padRight(3).substring(0, 3);
    final rawName = item['product_name']?.toString() ?? '-';
    final name = (rawName.length > 18
        ? rawName.substring(0, 18)
        : rawName.padRight(18));
    final amount = '\$${_money(item['total'])}'.padLeft(7);
    return '$quantity $name $amount';
  }

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String _money(Object? value) => _number(value).toStringAsFixed(2);
}

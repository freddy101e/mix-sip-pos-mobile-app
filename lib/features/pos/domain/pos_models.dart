import '../../../core/errors/app_exception.dart';
import '../../printing/domain/printer_models.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.stock,
    this.imageUrl,
  });
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num).toInt(),
    name: json['product_name'].toString(),
    code: json['product_code']?.toString() ?? '',
    price: (json['selling_price'] as num).toDouble(),
    stock: (json['product_store'] as num?)?.toInt() ?? 0,
    imageUrl: json['image_url']?.toString(),
  );
  final int id, stock;
  final String name, code;
  final String? imageUrl;
  final double price;
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.discountPercent,
  });
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: (json['id'] as num).toInt(),
    name: json['name'].toString(),
    discountPercent: double.tryParse(json['discount_percent'].toString()) ?? 0,
  );
  final int id;
  final String name;
  final double discountPercent;
}

class CartLine {
  const CartLine(this.product, this.quantity, {this.complimentaryReason});
  final Product product;
  final int quantity;
  final String? complimentaryReason;
  String? get complimentaryLabel => switch (complimentaryReason) {
    'birthday' => 'Birthday treat',
    'loyalty_card' => 'Loyalty reward',
    _ => null,
  };
  double get total =>
      complimentaryReason == null ? product.price * quantity : 0;
  CartLine copyWith(int quantity) =>
      CartLine(product, quantity, complimentaryReason: complimentaryReason);
}

class PosQuote {
  const PosQuote({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  });
  factory PosQuote.fromJson(Map<String, dynamic> json) => PosQuote(
    subtotal: (json['sub_total'] as num).toDouble(),
    discount: (json['discount_amount'] as num).toDouble(),
    tax: (json['tax'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
  );
  static void validateFreeLines(
    Map<String, dynamic> json,
    List<CartLine> cart,
  ) {
    final expected = <String, int>{};
    for (final line in cart.where((line) => line.complimentaryReason != null)) {
      final key = '${line.product.id}:${line.complimentaryReason}';
      expected[key] = (expected[key] ?? 0) + line.quantity;
    }
    if (expected.isEmpty) return;
    final actual = <String, int>{};
    for (final raw in json['lines'] as List? ?? const []) {
      final line = Map<String, dynamic>.from(raw as Map);
      final key = '${line['product_id']}:${line['complimentary_reason']}';
      if (!expected.containsKey(key)) continue;
      if (line['unit_price'] != 0 || line['total'] != 0) {
        throw const AppException(
          'Free-item pricing could not be confirmed. Checkout has been paused.',
        );
      }
      actual[key] = (actual[key] ?? 0) + (line['quantity'] as num).toInt();
    }
    if (expected.entries.any((entry) => actual[entry.key] != entry.value)) {
      throw const AppException(
        'Free-item pricing could not be confirmed. Checkout has been paused.',
      );
    }
  }

  final double subtotal, discount, tax, total;
}

class SaleResult {
  const SaleResult({
    required this.orderId,
    required this.invoiceNumber,
    required this.status,
    required this.due,
    required this.receiptLines,
  });

  factory SaleResult.fromJson(
    Map<String, dynamic> json, {
    List<CartLine> cart = const [],
  }) {
    final order = json['order'] as Map<String, dynamic>;
    final receipt = json['receipt'] as Map<String, dynamic>? ?? const {};
    final serverLines = receipt['lines'] as List? ?? const [];
    return SaleResult(
      orderId: (order['id'] as num).toInt(),
      invoiceNumber: order['invoice_no'].toString(),
      status: order['order_status']?.toString() ?? 'unknown',
      due: _number(order['due']),
      receiptLines: serverLines.isNotEmpty
          ? serverLines
                .map(
                  (line) => ReceiptLine.fromJson(
                    Map<String, dynamic>.from(line as Map),
                  ),
                )
                .toList()
          : _fallbackReceipt(order, cart),
    );
  }

  final int orderId;
  final String invoiceNumber;
  final String status;
  final double due;
  final List<ReceiptLine> receiptLines;

  bool get isPending => status == 'pending' || due > 0.00001;

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static List<ReceiptLine> _fallbackReceipt(
    Map<String, dynamic> order,
    List<CartLine> cart,
  ) {
    final customer = order['customer'] as Map<String, dynamic>?;
    final discount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
    final discountPercent =
        (order['discount_percent'] as num?)?.toDouble() ?? 0;
    final tendered = (order['last_tendered'] as num?)?.toDouble() ?? 0;
    final change = (order['last_change'] as num?)?.toDouble() ?? 0;
    final lines = <ReceiptLine>[
      const ReceiptLine(content: 'Mix & Sip', bold: true, align: 1, format: 3),
      const ReceiptLine(content: ' '),
      ReceiptLine(content: 'Invoice #${order['invoice_no']}', bold: true),
      ReceiptLine(content: 'Invoice date: ${order['order_date'] ?? ''}'),
      ReceiptLine(
        content: 'Customer: ${customer?['name'] ?? 'Walk-in / Unknown'}',
      ),
      const ReceiptLine(content: ' '),
      const ReceiptLine(content: 'Details', bold: true),
      ReceiptLine(content: 'Payment Status: ${order['payment_status'] ?? ''}'),
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
      for (final item in cart) ...[
        ReceiptLine(content: _itemLine(item)),
        if (item.complimentaryLabel != null)
          ReceiptLine(content: '${item.complimentaryLabel} - FREE'),
      ],
      const ReceiptLine(content: ' '),
      ReceiptLine(
        content: 'TOTAL: \$${_money(order['total'])}',
        bold: true,
        align: 2,
        format: 2,
      ),
    ]);
    return lines;
  }

  static String _money(Object? value) =>
      ((value as num?)?.toDouble() ?? 0).toStringAsFixed(2);

  static String _itemLine(CartLine line) {
    final quantity = line.quantity.toString().padRight(3).substring(0, 3);
    final name = line.product.name.padRight(18).substring(0, 18);
    final amount = '\$${line.total.toStringAsFixed(2)}'.padLeft(7);
    return '$quantity $name $amount';
  }
}

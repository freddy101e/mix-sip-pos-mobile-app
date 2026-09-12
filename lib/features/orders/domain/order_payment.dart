class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.type,
    required this.amount,
    required this.tendered,
    required this.change,
    required this.method,
    required this.paidAt,
    required this.user,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return OrderPayment(
      id: (json['id'] as num).toInt(),
      type: json['type']?.toString() ?? 'payment',
      amount: _number(json['amount']),
      tendered: _number(json['tendered']),
      change: _number(json['change']),
      method: json['payment_method']?.toString() ?? 'Unknown',
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
      user: user is Map ? user['name']?.toString() : null,
    );
  }

  final int id;
  final String type;
  final double amount;
  final double tendered;
  final double change;
  final String method;
  final DateTime? paidAt;
  final String? user;

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

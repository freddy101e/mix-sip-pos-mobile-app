class OrderSummary {
  static const editableCustomerName = 'BMP-CASH-CUSTOMER';

  const OrderSummary({
    required this.id,
    required this.invoice,
    required this.customer,
    required this.status,
    required this.reference,
    required this.paymentMethod,
    required this.date,
    required this.total,
    required this.due,
    this.createdAt,
    this.completedAt,
    this.printCount = 0,
    this.editCount = 0,
    this.loyaltyCardStatus,
  });
  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return OrderSummary(
      id: (json['id'] as num).toInt(),
      invoice: json['invoice_no']?.toString() ?? '',
      customer:
          customer is Map
              ? customer['name']?.toString() ?? 'Unknown customer'
              : 'Unknown customer',
      status: json['order_status']?.toString() ?? 'unknown',
      reference: json['order_reference']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '—',
      date: json['order_date']?.toString() ?? '',
      total: _asDouble(json['total']),
      due: _asDouble(json['due']),
      createdAt: _createdAt(json),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      printCount: (json['print_count'] as num?)?.toInt() ?? 0,
      editCount: (json['edit_count'] as num?)?.toInt() ?? 0,
      loyaltyCardStatus: json['loyalty_card_status'] as String?,
    );
  }
  final int id;
  final String invoice, customer, status, date, reference, paymentMethod;
  final double total, due;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final int printCount;
  final int editCount;
  final String? loyaltyCardStatus;

  String get loyaltyCardLabel => switch (loyaltyCardStatus) {
    'received' => 'Loyalty card received',
    'given' => 'Loyalty card given',
    'skipped' => 'Loyalty card skipped',
    _ => 'Loyalty card not recorded',
  };

  bool get canEditPendingOrder =>
      status == 'pending' && customer.trim() == editableCustomerName;

  String get createdTimeLabel {
    final timestamp = createdAt?.toLocal();
    if (timestamp == null) return '';
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get completedTimeLabel {
    final timestamp = completedAt?.toLocal();
    if (timestamp == null) return '';
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour < 12 ? 'AM' : 'PM';
    return 'Paid ${timestamp.month}/${timestamp.day} $hour:$minute $period';
  }

  static double _asDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static DateTime? _createdAt(Map<String, dynamic> json) {
    final createdAt = json['created_at']?.toString();
    if (createdAt != null && createdAt.isNotEmpty) {
      return DateTime.tryParse(createdAt);
    }
    final orderDate = json['order_date']?.toString() ?? '';
    final includesTime = orderDate.contains('T') || orderDate.contains(' ');
    return includesTime ? DateTime.tryParse(orderDate) : null;
  }
}

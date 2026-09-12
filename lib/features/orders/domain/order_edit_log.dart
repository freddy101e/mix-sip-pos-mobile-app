class OrderEditLog {
  const OrderEditLog({
    required this.id,
    required this.editor,
    required this.createdAt,
    required this.before,
    required this.after,
  });

  factory OrderEditLog.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return OrderEditLog(
      id: (json['id'] as num).toInt(),
      editor:
          user is Map
              ? user['name']?.toString() ?? 'Unknown user'
              : 'Unknown user',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      before: OrderSnapshot.fromJson(
        Map<String, dynamic>.from(json['before'] as Map? ?? const {}),
      ),
      after: OrderSnapshot.fromJson(
        Map<String, dynamic>.from(json['after'] as Map? ?? const {}),
      ),
    );
  }

  final int id;
  final String editor;
  final DateTime? createdAt;
  final OrderSnapshot before;
  final OrderSnapshot after;
}

class OrderSnapshot {
  const OrderSnapshot({
    required this.total,
    required this.due,
    required this.lines,
  });

  factory OrderSnapshot.fromJson(Map<String, dynamic> json) => OrderSnapshot(
    total: _number(json['total']),
    due: _number(json['due']),
    lines: (json['lines'] as List? ?? const [])
        .map(
          (line) => OrderSnapshotLine.fromJson(
            Map<String, dynamic>.from(line as Map),
          ),
        )
        .toList(growable: false),
  );

  final double total;
  final double due;
  final List<OrderSnapshotLine> lines;

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class OrderSnapshotLine {
  const OrderSnapshotLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.total,
  });

  factory OrderSnapshotLine.fromJson(Map<String, dynamic> json) =>
      OrderSnapshotLine(
        productId: _integer(json['product_id']),
        productName:
            json['product_name']?.toString() ??
            'Product #${json['product_id']}',
        quantity: OrderSnapshot._number(json['quantity']),
        unitCost: OrderSnapshot._number(json['unitcost']),
        total: OrderSnapshot._number(json['total']),
      );

  final int productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double total;

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

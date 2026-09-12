// models/item.dart
class Item {
  final String code;
  final String name;
  final String? uom;
  final num? allStock;
  final num? retail;
  final String? pictureUrl; // keep if you had it

  Item({
    required this.code,
    required this.name,
    this.uom,
    this.allStock,
    this.retail,
    this.pictureUrl,
  });

  factory Item.fromJson(Map<String, dynamic> j) {
    return Item(
      code: j['code'] ?? j['itemCode'] ?? '',
      name: j['name'] ?? j['itemName'] ?? '',
      uom: j['uom'] ?? j['UoM'],
      allStock: j['allStock'] ?? j['allstock'],
      retail: j['retail'] ?? j['price'], // fall back to price if retail absent
      pictureUrl: j['pictureUrl'] as String?,
    );
  }
}

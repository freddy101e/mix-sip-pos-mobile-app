class BluetoothPrinter {
  const BluetoothPrinter({required this.name, required this.address});

  final String name;
  final String address;

  factory BluetoothPrinter.fromMap(Map<Object?, Object?> value) {
    return BluetoothPrinter(
      name: value['name']?.toString() ?? 'Bluetooth device',
      address: value['address']?.toString() ?? '',
    );
  }
}

class ReceiptLine {
  const ReceiptLine({
    required this.content,
    this.bold = false,
    this.align = 0,
    this.format = 0,
  });

  final String content;
  final bool bold;
  final int align;
  final int format;

  factory ReceiptLine.fromJson(Map<String, dynamic> value) => ReceiptLine(
    content: value['content']?.toString() ?? '',
    bold: value['bold'] == 1 || value['bold'] == true,
    align: int.tryParse(value['align']?.toString() ?? '') ?? 0,
    format: int.tryParse(value['format']?.toString() ?? '') ?? 0,
  );
}

class EscPos58mmEncoder {
  List<int> encode(List<ReceiptLine> lines) {
    final output = <int>[0x1B, 0x40];
    for (final line in lines) {
      output.addAll([0x1B, 0x61, line.align.clamp(0, 2)]);
      output.addAll([0x1B, 0x45, line.bold ? 1 : 0]);
      output.addAll([0x1D, 0x21, _sizeForFormat(line.format)]);
      output.addAll(_latin1Safe(line.content));
      output.add(0x0A);
    }
    output.addAll([0x1B, 0x45, 0, 0x1D, 0x21, 0, 0x1B, 0x61, 0]);
    output.addAll([0x0A, 0x0A, 0x0A]);
    return output;
  }

  int _sizeForFormat(int format) => switch (format) {
    1 => 0x10,
    2 => 0x11,
    3 => 0x01,
    _ => 0x00,
  };

  List<int> _latin1Safe(String value) =>
      value.runes.map((rune) => rune <= 0xFF ? rune : 0x3F).toList();
}

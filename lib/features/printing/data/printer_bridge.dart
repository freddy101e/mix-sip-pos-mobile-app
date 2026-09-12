import 'package:flutter/services.dart';

import '../domain/printer_models.dart';

abstract final class PrinterBridge {
  static const _methods = MethodChannel('mix_and_sip_printing/bluetooth');

  static Future<String?> getSavedPrinter() =>
      _methods.invokeMethod<String>('getSavedPrinter');

  static Future<void> savePrinter(String address) =>
      _methods.invokeMethod<void>('savePrinter', {'address': address});

  static Future<List<BluetoothPrinter>> getBondedDevices() async {
    final devices =
        await _methods.invokeListMethod<Object?>('getBondedDevices') ??
        const [];
    return devices
        .map(
          (item) =>
              BluetoothPrinter.fromMap(Map<Object?, Object?>.from(item as Map)),
        )
        .where((item) => item.address.isNotEmpty)
        .toList();
  }

  static Future<void> printBytes(String address, List<int> bytes) => _methods
      .invokeMethod<void>('printBytes', {'address': address, 'bytes': bytes});
}

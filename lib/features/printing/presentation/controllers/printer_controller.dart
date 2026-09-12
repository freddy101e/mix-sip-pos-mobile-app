import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/printer_bridge.dart';
import '../../domain/printer_models.dart';

final printerControllerProvider =
    StateNotifierProvider<PrinterController, PrinterState>(
      (ref) => PrinterController(),
    );

enum PrinterStatus { info, success, warning, error }

class PrinterState {
  const PrinterState({
    this.printers = const [],
    this.selectedAddress,
    this.loading = true,
    this.printing = false,
    this.message = 'Pair your receipt printer, then select it here.',
    this.status = PrinterStatus.info,
  });

  final List<BluetoothPrinter> printers;
  final String? selectedAddress;
  final bool loading;
  final bool printing;
  final String message;
  final PrinterStatus status;

  BluetoothPrinter? get selectedPrinter {
    for (final printer in printers) {
      if (printer.address == selectedAddress) return printer;
    }
    return null;
  }

  PrinterState copyWith({
    List<BluetoothPrinter>? printers,
    String? selectedAddress,
    bool clearSelectedAddress = false,
    bool? loading,
    bool? printing,
    String? message,
    PrinterStatus? status,
  }) => PrinterState(
    printers: printers ?? this.printers,
    selectedAddress:
        clearSelectedAddress ? null : selectedAddress ?? this.selectedAddress,
    loading: loading ?? this.loading,
    printing: printing ?? this.printing,
    message: message ?? this.message,
    status: status ?? this.status,
  );
}

class PrinterController extends StateNotifier<PrinterState> {
  PrinterController() : super(const PrinterState()) {
    initialized = load();
  }

  late final Future<void> initialized;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final printers = await PrinterBridge.getBondedDevices();
      final savedAddress = await PrinterBridge.getSavedPrinter();
      final savedExists = printers.any((item) => item.address == savedAddress);
      state = state.copyWith(
        printers: printers,
        selectedAddress: savedExists ? savedAddress : null,
        clearSelectedAddress: !savedExists,
        loading: false,
        message:
            printers.isEmpty
                ? 'No paired Bluetooth devices found. Pair the printer in Android settings.'
                : savedExists
                ? 'Printer ready.'
                : 'Select the paired receipt printer.',
        status:
            printers.isEmpty
                ? PrinterStatus.warning
                : savedExists
                ? PrinterStatus.success
                : PrinterStatus.info,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        loading: false,
        message: error.message ?? 'Unable to load Bluetooth printers.',
        status: PrinterStatus.error,
      );
    } on MissingPluginException {
      state = state.copyWith(
        loading: false,
        message: 'Bluetooth receipt printing is available on Android.',
        status: PrinterStatus.warning,
      );
    }
  }

  Future<void> select(String? address) async {
    if (address == null) return;
    try {
      await PrinterBridge.savePrinter(address);
      state = state.copyWith(
        selectedAddress: address,
        message: 'Printer saved and ready.',
        status: PrinterStatus.success,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        message: error.message ?? 'Unable to save the printer.',
        status: PrinterStatus.error,
      );
    }
  }

  Future<bool> printReceipt(List<ReceiptLine> lines) async {
    await initialized;
    final address = state.selectedAddress;
    if (address == null) {
      state = state.copyWith(
        message: 'Receipt not printed. Select a printer in Settings.',
        status: PrinterStatus.warning,
      );
      return false;
    }

    state = state.copyWith(
      printing: true,
      message: 'Connecting and printing...',
      status: PrinterStatus.info,
    );
    try {
      await PrinterBridge.printBytes(
        address,
        EscPos58mmEncoder().encode(lines),
      );
      state = state.copyWith(
        printing: false,
        message: 'Receipt printed successfully.',
        status: PrinterStatus.success,
      );
      return true;
    } on PlatformException catch (error) {
      state = state.copyWith(
        printing: false,
        message: error.message ?? 'The printer could not be reached.',
        status: PrinterStatus.error,
      );
      return false;
    } on MissingPluginException {
      state = state.copyWith(
        printing: false,
        message: 'Bluetooth receipt printing is available on Android.',
        status: PrinterStatus.error,
      );
      return false;
    }
  }

  Future<bool> printTestReceipt() => printReceipt(const [
    ReceiptLine(content: 'Mix & Sip', bold: true, align: 1, format: 3),
    ReceiptLine(content: ' '),
    ReceiptLine(content: 'Printer Test', bold: true, align: 1),
    ReceiptLine(content: 'Vretti P501A - 58mm', align: 1),
    ReceiptLine(content: '--------------------------------'),
    ReceiptLine(content: 'Bluetooth connection: OK'),
    ReceiptLine(content: 'ESC/POS formatting: OK'),
    ReceiptLine(content: '--------------------------------'),
    ReceiptLine(content: 'Ready to print receipts!', bold: true, align: 1),
  ]);
}

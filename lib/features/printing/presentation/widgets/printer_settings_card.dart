import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../controllers/printer_controller.dart';

class PrinterSettingsCard extends ConsumerWidget {
  const PrinterSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printerControllerProvider);
    final controller = ref.read(printerControllerProvider.notifier);
    final (statusColor, statusIcon) = switch (state.status) {
      PrinterStatus.success => (AppColors.sage, Icons.check_circle_rounded),
      PrinterStatus.warning => (AppColors.amber, Icons.warning_amber_rounded),
      PrinterStatus.error => (AppColors.danger, Icons.error_rounded),
      PrinterStatus.info => (AppColors.coffee, Icons.info_rounded),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coffee.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    color: AppColors.coffee,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt printer',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('Vretti P501A · 58mm Bluetooth ESC/POS'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh paired devices',
                  onPressed:
                      state.loading || state.printing ? null : controller.load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (state.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: state.selectedAddress,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Paired printer',
                  prefixIcon: Icon(Icons.bluetooth_rounded),
                ),
                hint: const Text('Select receipt printer'),
                items:
                    state.printers
                        .map(
                          (printer) => DropdownMenuItem(
                            value: printer.address,
                            child: Text(
                              '${printer.name} · ${printer.address}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: state.printing ? null : controller.select,
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: .25)),
              ),
              child: Row(
                children: [
                  if (state.printing)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: statusColor,
                      ),
                    )
                  else
                    Icon(statusIcon, color: statusColor, size: 21),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  state.printing || state.selectedAddress == null
                      ? null
                      : () => controller.printTestReceipt(),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Print test receipt'),
            ),
            const SizedBox(height: 10),
            Text(
              'Pair the printer from Android Settings first. Once selected here, receipts print automatically after a successful sale.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

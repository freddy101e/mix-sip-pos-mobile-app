import 'package:flutter/material.dart';
import '../../../pos/presentation/screens/loyalty_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/money.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_edit_log.dart';
import '../../domain/order_payment.dart';
import '../../domain/order_summary.dart';
import '../../../printing/presentation/controllers/printer_controller.dart';
import '../controllers/orders_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersControllerProvider);
    final controller = ref.read(ordersControllerProvider.notifier);
    return Scaffold(
      bottomNavigationBar: const AppBottomBar(currentPath: '/orders'),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Row(
                    children: [
                      const MixSipBrand(compact: true),
                      const Spacer(),
                      if (state.filter == 'complete')
                        IconButton(
                          tooltip: 'Filter dates',
                          onPressed: () async {
                            final selectedFrom =
                                DateTime.tryParse(state.dateFrom ?? '') ??
                                DateTime.now();
                            final selectedTo =
                                DateTime.tryParse(state.dateTo ?? '') ??
                                selectedFrom;
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              initialDateRange: DateTimeRange(
                                start: selectedFrom,
                                end: selectedTo,
                              ),
                            );
                            if (range != null) {
                              controller.load(
                                null,
                                _iso(range.start),
                                _iso(range.end),
                              );
                            }
                          },
                          icon: const Icon(Icons.tune_rounded),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SalesSummary(summary: state.summary),
                      const SizedBox(height: 16),
                      Center(
                        child: SegmentedButton<String>(
                          style: ButtonStyle(
                            visualDensity: VisualDensity.comfortable,
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 18),
                            ),
                          ),
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: 'pending',
                              icon: Icon(Icons.schedule_rounded),
                              label: Text('Pending'),
                            ),
                            ButtonSegment(
                              value: 'complete',
                              icon: Icon(Icons.check_circle_outline_rounded),
                              label: Text('Complete'),
                            ),
                          ],
                          selected: {state.filter},
                          onSelectionChanged: (value) =>
                              controller.load(value.first),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: ErrorBanner(
                      message: state.error!.message,
                      onRetry: controller.load,
                    ),
                  ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: controller.load,
                          child: state.orders.isEmpty
                              ? ListView(
                                  children: const [
                                    AppEmptyState(
                                      icon: Icons.receipt_long_outlined,
                                      title: 'No orders here',
                                      message:
                                          'Orders matching this status will appear here.',
                                    ),
                                  ],
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 760
                                        ? 2
                                        : 1;
                                    return GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        4,
                                        20,
                                        28,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            mainAxisExtent: 176,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                          ),
                                      itemCount: state.orders.length,
                                      itemBuilder: (context, index) {
                                        final order = state.orders[index];
                                        return _OrderCard(
                                          order: order,
                                          onTap: () async {
                                            await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OrderDetailScreen(order),
                                              ),
                                            );
                                            await controller.load();
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _iso(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({required this.summary});
  final Map<String, dynamic> summary;
  double _value(String key) => (summary[key] as num?)?.toDouble() ?? 0;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Metric(
          label: 'Sales',
          value: formatMoney(_value('sales_total')),
          icon: Icons.payments_outlined,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _Metric(
          label: 'Orders',
          value: '${_value('orders_count').toInt()}',
          icon: Icons.receipt_long_outlined,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _Metric(
          label: 'Pending',
          value: formatMoney(_value('pending_due')),
          icon: Icons.schedule_outlined,
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.coffee),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final due = order.due > 0;
    final complete = order.status == 'complete';
    final edited = order.editCount > 0;
    final color = complete ? const Color(0xFF38A887) : AppColors.amber;
    const editColor = Color(0xFF8E5AA7);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: edited
            ? const BorderSide(color: editColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      complete
                          ? Icons.check_rounded
                          : Icons.receipt_long_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.invoice,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                order.date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (order.createdTimeLabel.isNotEmpty) ...[
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 12,
                                      color: color,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      order.createdTimeLabel,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (complete &&
                            order.completedTimeLabel.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  order.completedTimeLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (edited) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: editColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 13,
                            color: editColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '×${order.editCount}',
                            style: const TextStyle(
                              color: editColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                order.customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (order.reference.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.label_outline_rounded,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        order.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      due ? '${formatMoney(order.due)} due' : order.status,
                      style: TextStyle(
                        color: complete
                            ? const Color(0xFF21856A)
                            : AppColors.coffeeDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.paymentMethod,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (order.printCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E6E81).withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.print_rounded,
                            size: 13,
                            color: Color(0xFF4E6E81),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '×${order.printCount}',
                            style: const TextStyle(
                              color: Color(0xFF4E6E81),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    formatMoney(order.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen(this.order, {super.key});
  final OrderSummary order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Future<List<Map<String, dynamic>>> items;
  bool printing = false;

  @override
  void initState() {
    super.initState();
    items = ref.read(ordersRepositoryProvider).items(widget.order.id);
  }

  void retry() {
    setState(() {
      items = ref.read(ordersRepositoryProvider).items(widget.order.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final repository = ref.watch(ordersRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(order.invoice),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load this order',
              message: snapshot.error is AppException
                  ? (snapshot.error! as AppException).message
                  : 'Please check the connection and try again.',
            );
          }
          final data = snapshot.data ?? const <Map<String, dynamic>>[];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${order.status} · ${order.date}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Divider(height: 30),
                          ...data.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.coffee
                                        .withValues(alpha: .14),
                                    foregroundColor: AppColors.coffeeDark,
                                    child: const Icon(
                                      Icons.local_cafe_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['product_name']?.toString() ??
                                              'Product',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${item['quantity']} × ${_itemMoney(item['unitcost'])}${item['complimentary_label'] == null ? '' : ' · ${item['complimentary_label']} — FREE'}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _itemMoney(item['total']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total amount',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                formatMoney(order.total),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.coffee,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.credit_card_rounded),
                    title: Text(order.loyaltyCardLabel),
                  ),
                  if (order.editCount > 0) ...[
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => _OrderEditHistorySheet(
                          order: order,
                          repository: repository,
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded),
                      label: Text('Edit history (${order.editCount})'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (order.total - order.due > .00001) ...[
                    OutlinedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => _PaymentHistorySheet(
                          order: order,
                          repository: repository,
                        ),
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Payment history'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: printing ? null : () => _printReceipt(data),
                    icon: printing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded),
                    label: Text(
                      printing ? 'Printing receipt...' : 'Print receipt',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  if (order.due > 0) ...[
                    const SizedBox(height: 16),
                    if (order.canEditPendingOrder) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final changed = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _PendingOrderEditor(
                              order: order,
                              items: data,
                              repository: repository,
                            ),
                          );
                          if (changed == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit pending order'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: () async {
                        final paid = await showDialog<bool>(
                          context: context,
                          builder: (_) => _PayDueDialog(
                            order: order,
                            repository: repository,
                          ),
                        );
                        if (paid == true && context.mounted) {
                          await _printReceipt(data);
                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text('Pay ${formatMoney(order.due)} due'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _itemMoney(Object? value) {
    final parsed = double.tryParse(value?.toString() ?? '') ?? 0;
    return formatMoney(parsed);
  }

  Future<void> _printReceipt(List<Map<String, dynamic>> orderItems) async {
    setState(() => printing = true);
    try {
      final receipt = await ref
          .read(ordersRepositoryProvider)
          .receipt(widget.order, orderItems);
      final printed = await ref
          .read(printerControllerProvider.notifier)
          .printReceipt(receipt);
      String? trackingError;
      if (printed) {
        try {
          await ref.read(ordersRepositoryProvider).markPrinted(widget.order.id);
        } on AppException catch (error) {
          trackingError = error.message;
        }
      }
      if (!mounted) return;
      final printerMessage = ref.read(printerControllerProvider).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            printed
                ? trackingError == null
                      ? 'Receipt ${widget.order.invoice} printed successfully.'
                      : 'Receipt printed, but its counter could not be updated: $trackingError'
                : printerMessage,
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => printing = false);
    }
  }
}

class _PaymentHistorySheet extends StatefulWidget {
  const _PaymentHistorySheet({required this.order, required this.repository});

  final OrderSummary order;
  final OrdersRepository repository;

  @override
  State<_PaymentHistorySheet> createState() => _PaymentHistorySheetState();
}

class _PaymentHistorySheetState extends State<_PaymentHistorySheet> {
  late Future<List<OrderPayment>> payments;

  @override
  void initState() {
    super.initState();
    payments = widget.repository.payments(widget.order.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Payment history'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ),
    body: FutureBuilder<List<OrderPayment>>(
      future: payments,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load payment history',
            message: snapshot.error is AppException
                ? (snapshot.error! as AppException).message
                : 'Please check the connection and try again.',
          );
        }
        final records = snapshot.data ?? const <OrderPayment>[];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: records.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final payment = records[index];
            final balancePayment = payment.type == 'balance';
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  child: Icon(
                    balancePayment
                        ? Icons.history_rounded
                        : Icons.point_of_sale_rounded,
                  ),
                ),
                title: Text(
                  formatMoney(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${balancePayment
                      ? 'Balance payment'
                      : payment.type == 'legacy'
                      ? 'Historical payment'
                      : 'Initial payment'} · ${payment.method}\n${_editTimestamp(payment.paidAt)}${payment.user == null ? '' : ' · ${payment.user}'}',
                ),
                trailing: payment.change > 0
                    ? Text(
                        '${formatMoney(payment.change)}\nchange',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
              ),
            );
          },
        );
      },
    ),
  );
}

class _OrderEditHistorySheet extends StatefulWidget {
  const _OrderEditHistorySheet({required this.order, required this.repository});

  final OrderSummary order;
  final OrdersRepository repository;

  @override
  State<_OrderEditHistorySheet> createState() => _OrderEditHistorySheetState();
}

class _OrderEditHistorySheetState extends State<_OrderEditHistorySheet> {
  late Future<List<OrderEditLog>> history;

  @override
  void initState() {
    super.initState();
    history = widget.repository.editHistory(widget.order.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Order edit history'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded),
      ),
    ),
    body: FutureBuilder<List<OrderEditLog>>(
      future: history,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load edit history',
            message: snapshot.error is AppException
                ? (snapshot.error! as AppException).message
                : 'Please check the connection and try again.',
          );
        }
        final entries = snapshot.data ?? const <OrderEditLog>[];
        if (entries.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'No edits recorded',
            message: 'This order has not been edited.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: index == 0,
                leading: CircleAvatar(
                  backgroundColor: AppColors.coffee.withValues(alpha: .12),
                  foregroundColor: AppColors.coffee,
                  child: Text('${entries.length - index}'),
                ),
                title: Text(
                  entry.editor,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(_editTimestamp(entry.createdAt)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                children: [
                  _SnapshotCard(label: 'Before', snapshot: entry.before),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(Icons.arrow_downward_rounded, size: 18),
                  ),
                  _SnapshotCard(label: 'After', snapshot: entry.after),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.label, required this.snapshot});

  final String label;
  final OrderSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              'Total ${formatMoney(snapshot.total)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (snapshot.due > 0) ...[
          const SizedBox(height: 2),
          Text(
            '${formatMoney(snapshot.due)} due',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const Divider(height: 18),
        for (final line in snapshot.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    line.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_quantityLabel(line.quantity)} × ${formatMoney(line.unitCost)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

String _quantityLabel(double quantity) => quantity == quantity.roundToDouble()
    ? quantity.toInt().toString()
    : quantity.toString();

String _editTimestamp(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} · $hour:$minute $period';
}

class _PendingOrderEditor extends StatefulWidget {
  const _PendingOrderEditor({
    required this.order,
    required this.items,
    required this.repository,
  });
  final OrderSummary order;
  final List<Map<String, dynamic>> items;
  final OrdersRepository repository;
  @override
  State<_PendingOrderEditor> createState() => _PendingOrderEditorState();
}

class _PendingOrderEditorState extends State<_PendingOrderEditor> {
  late List<Map<String, dynamic>> lines;
  List<Map<String, dynamic>> products = [];
  bool saving = false;
  String? saveError;

  @override
  void initState() {
    super.initState();
    lines = widget.items
        .map(
          (item) => {
            'product_id': item['product_id'],
            'name': item['complimentary_label'] == null
                ? item['product_name']
                : '${item['product_name']} · ${item['complimentary_label']} — FREE',
            'quantity': (item['quantity'] as num).toInt(),
            'complimentary_reason': item['complimentary_reason'],
          },
        )
        .toList();
    _search('');
  }

  Future<void> _search(String query) async {
    try {
      final results = await widget.repository.products(query);
      if (mounted) setState(() => products = results);
    } on AppException catch (error) {
      if (mounted) setState(() => saveError = error.message);
    }
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      saveError = null;
    });
    try {
      await widget.repository.updateOrder(
        widget.order.id,
        lines
            .map(
              (line) => {
                'product_id': line['product_id'],
                'quantity': line['quantity'],
                'complimentary_reason': line['complimentary_reason'],
              },
            )
            .toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          saving = false;
          saveError = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(top: 24),
    bottom: false,
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Edit pending order'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                ...lines.asMap().entries.map((entry) {
                  final line = entry.value;
                  final quantity = line['quantity'] as int;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line['name'].toString()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => line['quantity'] = quantity > 1
                                ? quantity - 1
                                : 1,
                          ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity'),
                        IconButton(
                          onPressed: () =>
                              setState(() => line['quantity'] = quantity + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => lines.removeAt(entry.key)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                TextField(
                  onChanged: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search product to add',
                  ),
                ),
                const SizedBox(height: 8),
                ...products
                    .where(
                      (product) => !lines.any(
                        (line) => line['product_id'] == product['id'],
                      ),
                    )
                    .map(
                      (product) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(product['product_name'].toString()),
                        trailing: const Icon(Icons.add),
                        onTap: () => setState(
                          () => lines.add({
                            'product_id': product['id'],
                            'name': product['product_name'],
                            'quantity': 1,
                          }),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (saveError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ErrorBanner(message: saveError!),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewPaddingOf(context).bottom + 16,
            ),
            child: FilledButton(
              onPressed: saving || lines.isEmpty ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(saving ? 'Saving...' : 'Save changes'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PayDueDialog extends StatefulWidget {
  const _PayDueDialog({required this.order, required this.repository});
  final OrderSummary order;
  final OrdersRepository repository;

  @override
  State<_PayDueDialog> createState() => _PayDueDialogState();
}

class _PayDueDialogState extends State<_PayDueDialog> {
  String? loyaltyCardStatus;
  late final TextEditingController amount;
  bool submitting = false;
  String? error;
  String method = 'Cash';

  @override
  void initState() {
    super.initState();
    amount = TextEditingController(text: widget.order.due.toStringAsFixed(2));
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tendered = double.tryParse(amount.text) ?? 0;
    final change = (tendered - widget.order.due).clamp(0, double.infinity);
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pay outstanding due',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: submitting
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.coffee.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.coffee,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Amount due')),
                    Text(
                      formatMoney(widget.order.due),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.coffee,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Payment method',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Cash', label: Text('Cash')),
                  ButtonSegment(value: 'Card', label: Text('Card')),
                  ButtonSegment(
                    value: 'Transfer',
                    label: Text('Transfer', maxLines: 1),
                  ),
                ],
                selected: {method},
                onSelectionChanged: submitting
                    ? null
                    : (value) => setState(() => method = value.first),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: amount,
                enabled: !submitting,
                onChanged: (_) => setState(() => error = null),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount tendered',
                  prefixText: '\$ ',
                  suffixIcon: IconButton(
                    tooltip: 'Clear tendered amount',
                    onPressed: submitting
                        ? null
                        : () => setState(() => amount.text = '0.00'),
                    icon: const Icon(Icons.backspace_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Customer change',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    formatMoney(change),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                ErrorBanner(message: error!),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_rounded),
                label: Text(
                  submitting
                      ? 'Processing payment...'
                      : 'Pay ${formatMoney(widget.order.due)}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A receipt prints automatically after payment.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final tendered = double.tryParse(amount.text);
    if (tendered == null || tendered < widget.order.due) {
      setState(() => error = 'Tendered amount must cover the full due.');
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final active = await widget.repository.loyaltyReminderActive();
      if (!mounted) return;
      if (active && loyaltyCardStatus == null) {
        loyaltyCardStatus = await showLoyaltyDialog(context);
        if (!mounted || loyaltyCardStatus == null) return;
      }
      await widget.repository.payDue(
        widget.order.id,
        tendered,
        method,
        loyaltyCardStatus: loyaltyCardStatus,
      );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (exception) {
      if (mounted) {
        setState(() {
          submitting = false;
          error = exception.message;
        });
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

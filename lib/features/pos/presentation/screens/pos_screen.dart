import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/money.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../printing/presentation/controllers/printer_controller.dart';
import '../../domain/pos_models.dart';
import '../controllers/pos_controller.dart';
import 'loyalty_dialog.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!wide && state.cart.isNotEmpty)
            _MobileCartBar(onTap: () => _showCart(context)),
          const AppBottomBar(currentPath: '/pos'),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child:
            state.loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child:
                        wide
                            ? const Padding(
                              padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _CatalogPane()),
                                  SizedBox(width: 18),
                                  SizedBox(width: 390, child: _OrderPanel()),
                                ],
                              ),
                            )
                            : const _CatalogPane(),
                  ),
                ),
      ),
    );
  }

  static void _showCart(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder:
          (sheetContext) => FractionallySizedBox(
            heightFactor: .92,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                10,
                14,
                MediaQuery.viewPaddingOf(sheetContext).bottom + 16,
              ),
              child: const _OrderPanel(inSheet: true),
            ),
          ),
    );
  }
}

class _CatalogPane extends ConsumerWidget {
  const _CatalogPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final controller = ref.read(posControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              const MixSipBrand(compact: true),
              const Spacer(),
              Text(
                'New order',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: controller.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search products by name or code',
              isDense: true,
            ),
          ),
        ),
        if (state.error != null && state.cart.isEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ErrorBanner(
              message: state.error!.message,
              onRetry: controller.load,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Expanded(
          child:
              state.products.isEmpty
                  ? const AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    message: 'Try another product name or code.',
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 245,
                          mainAxisExtent: 260,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final line = state.cart.where(
                        (item) => item.product.id == product.id,
                      );
                      return _ProductCard(
                        product: product,
                        selectedQuantity:
                            line.isEmpty ? 0 : line.first.quantity,
                        onTap: () => controller.add(product),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selectedQuantity,
    required this.onTap,
  });

  final Product product;
  final int selectedQuantity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedQuantity > 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color:
          selected
              ? (dark ? const Color(0xFF3B3124) : AppColors.blush)
              : Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              selected
                  ? AppColors.amber
                  : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _ProductImage(product: product),
                  if (selected)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$selectedQuantity in cart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.code.isEmpty ? 'Mix & Sip' : product.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(product.price),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.coffee,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${product.stock} in stock',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: 82,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.plum,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final url = product.imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 82,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder:
            (context, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}

class _MobileCartBar extends ConsumerWidget {
  const _MobileCartBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final quantity = state.cart.fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );
    final total = state.cart.fold<double>(0, (sum, line) => sum + line.total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Material(
        color: AppColors.coffee,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                Badge(
                  label: Text('$quantity'),
                  backgroundColor: AppColors.amber,
                  textColor: AppColors.ink,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'View current order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatMoney(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderPanel extends ConsumerWidget {
  const _OrderPanel({this.inSheet = false});

  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posControllerProvider);
    final controller = ref.read(posControllerProvider.notifier);
    final estimated = state.cart.fold<double>(
      0,
      (sum, line) => sum + line.total,
    );
    final total = state.quote?.total ?? estimated;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Order details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (inSheet)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: DropdownButtonFormField<Customer>(
              initialValue: state.customer,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Customer',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items:
                  state.customers
                      .map(
                        (customer) => DropdownMenuItem(
                          value: customer,
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: controller.selectCustomer,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                state.cart.isEmpty
                    ? const AppEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your order is empty',
                      message: 'Select a product to add it to this sale.',
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.cart.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final line = state.cart[index];
                        return _CartLineTile(
                          line: line,
                          onDecrease:
                              () =>
                                  controller.quantity(index, line.quantity - 1),
                          onIncrease:
                              () =>
                                  controller.quantity(index, line.quantity + 1),
                        );
                      },
                    ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ErrorBanner(message: state.error!.message),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
                if (state.quote != null) ...[
                  _SummaryRow('Subtotal', formatMoney(state.quote!.subtotal)),
                  const SizedBox(height: 7),
                  _SummaryRow(
                    'Discount',
                    '-${formatMoney(state.quote!.discount)}',
                  ),
                  const SizedBox(height: 7),
                  _SummaryRow('Tax', formatMoney(state.quote!.tax)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                ],
                Row(
                  children: [
                    Text(
                      'Total bill',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.coffee,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed:
                      state.submitting ||
                              state.cart.isEmpty ||
                              state.customer == null
                          ? null
                          : () async {
                            if (state.quote == null) {
                              await controller.quote();
                              return;
                            }
                            final sale = await showModalBottomSheet<SaleResult>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder:
                                  (_) => _PaymentSheet(quote: state.quote!),
                            );
                            if (sale == null || !context.mounted) return;
                            final printed =
                                sale.isPending
                                    ? false
                                    : await ref
                                        .read(
                                          printerControllerProvider.notifier,
                                        )
                                        .printReceipt(sale.receiptLines);
                            String? trackingError;
                            if (printed) {
                              try {
                                await ref
                                    .read(posRepositoryProvider)
                                    .markPrinted(sale.orderId);
                              } on AppException catch (error) {
                                trackingError = error.message;
                              }
                            }
                            if (!context.mounted) return;
                            final printerMessage =
                                ref.read(printerControllerProvider).message;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  printed
                                      ? trackingError != null
                                          ? 'Receipt printed, but its counter could not be updated: $trackingError'
                                          : sale.isPending
                                          ? 'Invoice ${sale.invoiceNumber} saved as pending (${formatMoney(sale.due)} due).'
                                          : 'Sale ${sale.invoiceNumber} created and receipt printed.'
                                      : sale.isPending
                                      ? 'Invoice ${sale.invoiceNumber} saved as pending (${formatMoney(sale.due)} due).'
                                      : 'Sale ${sale.invoiceNumber} created. $printerMessage',
                                ),
                              ),
                            );
                            if (inSheet && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                  icon:
                      state.submitting
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            state.quote == null
                                ? Icons.calculate_outlined
                                : Icons.arrow_forward_rounded,
                          ),
                  label: Text(
                    state.quote == null
                        ? 'Review total'
                        : 'Continue to payment',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartLine line;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.coffee.withValues(alpha: .14),
          foregroundColor: AppColors.coffeeDark,
          child: Text(
            line.product.name.isEmpty
                ? '?'
                : line.product.name[0].toUpperCase(),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                formatMoney(line.total),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
        SizedBox(
          width: 32,
          child: Text(
            '${line.quantity}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        _QuantityButton(
          icon: Icons.add_rounded,
          onTap: onIncrease,
          filled: true,
        ),
      ],
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 32,
    child: IconButton.filledTonal(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: filled ? AppColors.coffee : Colors.transparent,
        foregroundColor: filled ? Colors.white : null,
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      icon: Icon(icon, size: 17),
    ),
  );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.quote});

  final PosQuote quote;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  bool checkingLoyalty = false;
  String? loyaltyCardStatus;

  Future<void> saveOrder(double amount) async {
    if (checkingLoyalty) return;
    setState(() => checkingLoyalty = true);
    try {
      final total = ref.read(posControllerProvider).quote!.total;
      final completesOrder = amount >= total;
      final active =
          completesOrder &&
          await ref.read(posRepositoryProvider).loyaltyReminderActive();
      if (!mounted) return;
      if (active && loyaltyCardStatus == null) {
        loyaltyCardStatus = await showLoyaltyDialog(context);
        if (!mounted || loyaltyCardStatus == null) return;
      }
      final sale = await ref
          .read(posControllerProvider.notifier)
          .checkout(
            method,
            amount,
            orderReference: orderReference.text,
            loyaltyCardStatus: completesOrder ? loyaltyCardStatus : null,
          );
      if (sale != null && mounted) Navigator.pop(context, sale);
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => checkingLoyalty = false);
    }
  }

  String method = 'Cash';
  late final TextEditingController tendered;
  late final TextEditingController orderReference;

  @override
  void initState() {
    super.initState();
    tendered = TextEditingController(text: '0.00');
    orderReference = TextEditingController();
    tendered.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    tendered.removeListener(_refresh);
    tendered.dispose();
    orderReference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posControllerProvider);
    final quote = widget.quote;
    final amount = double.tryParse(tendered.text) ?? 0;
    final applied = amount.clamp(0, quote.total).toDouble();
    final due = (quote.total - applied).clamp(0, double.infinity).toDouble();
    final change = (amount - quote.total).clamp(0, double.infinity);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter zero or a partial amount to save this invoice as pending.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children:
                      ['Cash', 'Card', 'Transfer'].map((value) {
                        final selected = method == value;
                        final icon = switch (value) {
                          'Cash' => Icons.payments_outlined,
                          'Card' => Icons.credit_card_rounded,
                          _ => Icons.account_balance_outlined,
                        };
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: value == 'Transfer' ? 0 : 10,
                            ),
                            child: InkWell(
                              onTap:
                                  () => setState(() {
                                    method = value;
                                    if (value != 'Cash') {
                                      tendered.text = quote.total
                                          .toStringAsFixed(2);
                                      tendered.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: tendered.text.length,
                                      );
                                    }
                                  }),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: wide ? 24 : 18,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      selected
                                          ? AppColors.coffee.withValues(
                                            alpha: .12,
                                          )
                                          : Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        selected
                                            ? AppColors.coffee
                                            : Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      color: selected ? AppColors.coffee : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      value,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight:
                                            selected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: orderReference,
                  enabled: !state.submitting,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Order reference (cashier only)',
                    hintText: 'e.g. Table 1 or Customer 1',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tendered,
                        enabled: !state.submitting,
                        onTap:
                            () =>
                                tendered.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: tendered.text.length,
                                ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Amount tendered',
                          prefixText: '\$ ',
                          suffixIcon: IconButton(
                            tooltip: 'Clear tendered amount',
                            onPressed: () => tendered.text = '0.00',
                            icon: const Icon(Icons.backspace_outlined),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer change',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          formatMoney(change),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow('Subtotal', formatMoney(quote.subtotal)),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        'Discount',
                        '-${formatMoney(quote.discount)}',
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow('Tax', formatMoney(quote.tax)),
                      const Divider(height: 24),
                      _SummaryRow(
                        'Total amount',
                        formatMoney(quote.total),
                        emphasized: true,
                      ),
                      if (due > 0.00001) ...[
                        const SizedBox(height: 8),
                        _SummaryRow('Remaining due', formatMoney(due)),
                      ],
                    ],
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(message: state.error!.message),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed:
                      state.submitting || checkingLoyalty || amount < 0
                          ? null
                          : () => saveOrder(amount),
                  icon:
                      state.submitting
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    due > 0.00001
                        ? 'Save pending · ${formatMoney(due)} due'
                        : 'Pay now · ${formatMoney(quote.total)}',
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            color:
                emphasized
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          fontSize: emphasized ? 18 : null,
          color: emphasized ? AppColors.coffee : null,
        ),
      ),
    ],
  );
}

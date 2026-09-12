import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_error_parser.dart';
import '../../../../shared/money.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

class RegisterBalanceScreen extends ConsumerStatefulWidget {
  const RegisterBalanceScreen({super.key});
  @override
  ConsumerState<RegisterBalanceScreen> createState() =>
      _RegisterBalanceScreenState();
}

class _RegisterBalanceScreenState extends ConsumerState<RegisterBalanceScreen> {
  static const bills = [100, 50, 20, 10, 5, 2, 1, .25];
  final counts = {
    for (final bill in bills) bill: TextEditingController(text: '0'),
  };
  final expenses = TextEditingController(text: '0.00');
  Map<String, dynamic>? data;
  bool loading = true;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in counts.values) {
      controller.dispose();
    }
    expenses.dispose();
    super.dispose();
  }

  double get total => counts.entries.fold(
    0,
    (sum, item) => sum + item.key * (double.tryParse(item.value.text) ?? 0),
  );
  Map<String, double> get payload => {
    for (final item in counts.entries)
      item.key.toString(): item.key * (double.tryParse(item.value.text) ?? 0),
  };
  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .dio
          .get<Map<String, dynamic>>('/register-balance');
      if (mounted) {
        setState(() {
          data = response.data!['data'] as Map<String, dynamic>;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = ApiErrorParser.parse(e).message;
          loading = false;
        });
      }
    }
  }

  Future<void> _save(bool closing) async {
    if (closing) {
      final opening = (data?['opening_amount'] as num?)?.toDouble() ?? 0;
      final cashSales = (data?['cash_sales'] as num?)?.toDouble() ?? 0;
      final expense = double.tryParse(expenses.text) ?? 0;
      final expectedCash = opening + cashSales - expense;
      final difference = total - expectedCash;

      if (difference.abs() >= .01) {
        final discrepancy = formatMoney(difference.abs());
        setState(() {
          error =
              difference < 0
                  ? 'Cannot close register: physical cash is $discrepancy short. Recount the cash or record any missing cash expense.'
                  : 'Cannot close register: physical cash is $discrepancy over. Recount the cash before closing.';
        });
        return;
      }
    }

    setState(() {
      saving = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .dio
          .post<Map<String, dynamic>>(
            closing ? '/register-balance/close' : '/register-balance/open',
            data: {
              'counts': payload,
              if (closing) 'expenses': double.tryParse(expenses.text) ?? 0,
            },
          );
      if (mounted) {
        setState(() {
          data = response.data!['data'] as Map<String, dynamic>;
          saving = false;
        });
        if (closing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Register closed successfully.')),
          );
        }
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = ApiErrorParser.parse(exception).message;
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opening = (data?['opening_amount'] as num?)?.toDouble() ?? 0;
    final cashSales = (data?['cash_sales'] as num?)?.toDouble() ?? 0;
    final cashNewOrders = (data?['cash_new_orders'] as num?)?.toDouble() ?? 0;
    final priorOrderCollections =
        (data?['cash_prior_order_collections'] as num?)?.toDouble() ?? 0;
    final card = (data?['card_total'] as num?)?.toDouble() ?? 0;
    final transfer = (data?['transfer_total'] as num?)?.toDouble() ?? 0;
    final expense = double.tryParse(expenses.text) ?? 0;
    final closing = opening > 0;
    final expectedCash = opening + cashSales - expense;
    final remove = (total - opening).clamp(0, double.infinity).toDouble();
    final cashDifference = total - expectedCash;
    final reconciledTotal = total + expense + card + transfer;
    final closedAt = data?['closed_at']?.toString();

    if (!loading && closedAt != null && closedAt.isNotEmpty) {
      final closingAmount = (data?['closing_amount'] as num?)?.toDouble() ?? 0;
      final savedExpenses = (data?['expenses'] as num?)?.toDouble() ?? 0;
      return Scaffold(
        bottomNavigationBar: const AppBottomBar(currentPath: '/register'),
        appBar: AppBar(title: const Text('Register balance')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Register closed',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The closing count was saved successfully.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _Summary(
                          'Closing cash',
                          closingAmount,
                          emphasized: true,
                        ),
                        _Summary('Cash expenses', savedExpenses),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Return to home'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: const AppBottomBar(currentPath: '/register'),
      appBar: AppBar(title: const Text('Register balance')),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!closing) ...[
                    Text(
                      'Open register',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Count the cash placed in the register at the start of service.',
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (closing) ...[
                    _Summary('Opening balance', opening),
                    _Summary('Cash received today', cashSales),
                    _Summary('New orders paid in cash', cashNewOrders),
                    _Summary('Older orders paid today', priorOrderCollections),
                    _Summary('Card charges', card),
                    _Summary('Transfers', transfer),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Physical cash count',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...bills.map(
                    (bill) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${formatMoney(bill.toDouble())} ×'),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: counts[bill],
                              selectAllOnFocus: true,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Summary('Physical cash counted', total, emphasized: true),
                  if (closing) ...[
                    const SizedBox(height: 18),
                    TextField(
                      controller: expenses,
                      selectAllOnFocus: true,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cash expenses today',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Summary(
                      'Reconciled total',
                      reconciledTotal,
                      emphasized: true,
                    ),
                    _Summary('Cash to remove', remove, emphasized: true),
                    _Summary(
                      cashDifference.abs() < .01
                          ? 'Cash count matches'
                          : cashDifference < 0
                          ? 'Cash shortage'
                          : 'Cash overage',
                      cashDifference.abs(),
                      emphasized: true,
                    ),
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ErrorBanner(message: error!),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : () => _save(closing),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : closing
                          ? 'Close register'
                          : 'Save starting balance',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, {this.emphasized = false});
  final String label;
  final double value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) {
    final alert = label.contains('shortage') || label.contains('overage');
    final color = alert ? Theme.of(context).colorScheme.error : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Text(
            formatMoney(value),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: emphasized ? 20 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

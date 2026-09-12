import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_summary.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider)),
);
final ordersControllerProvider =
    StateNotifierProvider.autoDispose<OrdersController, OrdersState>(
      (ref) => OrdersController(ref.watch(ordersRepositoryProvider))..load(),
    );

class OrdersState {
  const OrdersState({
    this.filter = 'pending',
    this.orders = const [],
    this.loading = true,
    this.error,
    this.summary = const {},
    this.dateFrom,
    this.dateTo,
  });
  final String filter;
  final List<OrderSummary> orders;
  final bool loading;
  final AppException? error;
  final Map<String, dynamic> summary;
  final String? dateFrom, dateTo;
}

class OrdersController extends StateNotifier<OrdersState> {
  OrdersController(this._repo) : super(const OrdersState());
  final OrdersRepository _repo;
  Future<void> load([String? filter, String? dateFrom, String? dateTo]) async {
    final next = filter ?? state.filter;
    final today = _isoDate(DateTime.now());
    final from = dateFrom ?? state.dateFrom ?? today;
    final to = dateTo ?? state.dateTo ?? from;
    state = OrdersState(
      filter: next,
      dateFrom: from,
      dateTo: to,
      summary: state.summary,
    );
    try {
      final results = await Future.wait([
        _repo.list(
          next,
          dateFrom: next == 'complete' ? from : null,
          dateTo: next == 'complete' ? to : null,
        ),
        _repo.summary(dateFrom: from, dateTo: to),
      ]);
      state = OrdersState(
        filter: next,
        orders: results[0] as List<OrderSummary>,
        summary: results[1] as Map<String, dynamic>,
        dateFrom: from,
        dateTo: to,
        loading: false,
      );
    } on AppException catch (e) {
      state = OrdersState(
        filter: next,
        loading: false,
        error: e,
        summary: state.summary,
        dateFrom: from,
        dateTo: to,
      );
    }
  }
}

String _isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

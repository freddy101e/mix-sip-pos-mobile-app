import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(ref.watch(apiClientProvider)),
);
final posControllerProvider = StateNotifierProvider<PosController, PosState>(
  (ref) => PosController(ref.watch(posRepositoryProvider))..load(),
);

class PosState {
  const PosState({
    this.products = const [],
    this.customers = const [],
    this.cart = const [],
    this.customer,
    this.quote,
    this.loading = true,
    this.submitting = false,
    this.error,
    this.clientReference,
  });
  final List<Product> products;
  final List<Customer> customers;
  final List<CartLine> cart;
  final Customer? customer;
  final PosQuote? quote;
  final bool loading, submitting;
  final AppException? error;
  final String? clientReference;
  PosState copyWith({
    List<Product>? products,
    List<Customer>? customers,
    List<CartLine>? cart,
    Customer? customer,
    PosQuote? quote,
    bool? loading,
    bool? submitting,
    AppException? error,
    bool clearQuote = false,
    bool clearError = false,
    String? clientReference,
    bool clearClientReference = false,
  }) => PosState(
    products: products ?? this.products,
    customers: customers ?? this.customers,
    cart: cart ?? this.cart,
    customer: customer ?? this.customer,
    quote: clearQuote ? null : quote ?? this.quote,
    loading: loading ?? this.loading,
    submitting: submitting ?? this.submitting,
    error: clearError ? null : error ?? this.error,
    clientReference: clearClientReference
        ? null
        : clientReference ?? this.clientReference,
  );
}

class PosController extends StateNotifier<PosState> {
  static const cashCustomerName = 'BMP-CASH-CUSTOMER';

  PosController(this._repo, {String Function()? referenceFactory})
    : _referenceFactory = referenceFactory ?? _newReference,
      super(const PosState());
  final PosDataSource _repo;
  final String Function() _referenceFactory;
  Timer? _timer;
  int _searchGeneration = 0;

  static String _newReference() => const Uuid().v4();
  Future<void> load() async {
    try {
      final data = await Future.wait([_repo.products(''), _repo.customers()]);
      final customers = (data[1] as List<Customer>)
          .where((customer) => customer.name.trim() == cashCustomerName)
          .toList(growable: false);
      state = state.copyWith(
        products: data[0] as List<Product>,
        customers: customers,
        customer: customers.isEmpty ? null : customers.single,
        loading: false,
        clearError: true,
      );
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void search(String value) {
    _timer?.cancel();
    final generation = ++_searchGeneration;
    _timer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final products = await _repo.products(value);
        if (generation != _searchGeneration) return;
        state = state.copyWith(products: products, clearError: true);
      } on AppException catch (e) {
        if (generation != _searchGeneration) return;
        state = state.copyWith(error: e);
      }
    });
  }

  void selectCustomer(Customer? customer) =>
      state = state.copyWith(customer: customer, clearQuote: true);
  void add(Product product) {
    final cart = [...state.cart];
    final isNewSale = cart.isEmpty;
    final index = cart.indexWhere(
      (e) => e.product.id == product.id && e.complimentaryReason == null,
    );
    if (index < 0) {
      cart.add(CartLine(product, 1));
    } else {
      cart[index] = cart[index].copyWith(cart[index].quantity + 1);
    }
    state = state.copyWith(
      cart: cart,
      clearQuote: true,
      clientReference: isNewSale ? _referenceFactory() : state.clientReference,
    );
  }

  void quantity(int index, int value) {
    final cart = [...state.cart];
    if (value <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(value);
    }
    state = state.copyWith(
      cart: cart,
      clearQuote: true,
      clearClientReference: cart.isEmpty,
    );
  }

  void markComplimentary(int index, int quantity, String? reason) {
    if (state.submitting || index < 0 || index >= state.cart.length) return;
    if (reason != null && reason != 'birthday' && reason != 'loyalty_card') {
      return;
    }
    final cart = [...state.cart];
    final source = cart[index];
    if (quantity < 1 ||
        quantity > source.quantity ||
        reason == source.complimentaryReason) {
      return;
    }
    if (quantity == source.quantity) {
      cart.removeAt(index);
    } else {
      cart[index] = source.copyWith(source.quantity - quantity);
    }
    final target = cart.indexWhere(
      (line) =>
          line.product.id == source.product.id &&
          line.complimentaryReason == reason,
    );
    if (target < 0) {
      cart.add(CartLine(source.product, quantity, complimentaryReason: reason));
    } else {
      cart[target] = cart[target].copyWith(cart[target].quantity + quantity);
    }
    state = state.copyWith(cart: cart, clearQuote: true, clearError: true);
  }

  Future<void> quote() async {
    if (state.submitting || state.customer == null || state.cart.isEmpty) {
      return;
    }
    final customer = state.customer!;
    final cart = state.cart;
    state = state.copyWith(
      submitting: true,
      clearError: true,
      clearQuote: true,
    );
    try {
      final result = await _repo.quote(customer, cart);
      if (!mounted) return;
      if (!identical(cart, state.cart) || customer != state.customer) {
        state = state.copyWith(submitting: false, clearQuote: true);
        return;
      }
      state = state.copyWith(quote: result, submitting: false);
    } on AppException catch (e) {
      if (!mounted) return;
      final current = identical(cart, state.cart) && customer == state.customer;
      state = state.copyWith(
        error: current ? e : null,
        submitting: false,
        clearQuote: true,
      );
    }
  }

  Future<SaleResult?> checkout(
    String method,
    double tendered, {
    String orderReference = '',
    String? loyaltyCardStatus,
  }) async {
    if (state.submitting) return null;
    if (state.customer == null || state.quote == null) return null;
    final clientReference = state.clientReference ?? _referenceFactory();
    state = state.copyWith(
      submitting: true,
      clearError: true,
      clientReference: clientReference,
    );
    try {
      final sale = await _repo.checkout(
        state.customer!,
        state.cart,
        state.quote!,
        method,
        tendered,
        orderReference,
        clientReference,
        loyaltyCardStatus: loyaltyCardStatus,
      );
      state = state.copyWith(
        cart: [],
        submitting: false,
        clearQuote: true,
        clearClientReference: true,
      );
      return sale;
    } on AppException catch (e) {
      state = state.copyWith(error: e, submitting: false);
      return null;
    }
  }

  @override
  void dispose() {
    _searchGeneration++;
    _timer?.cancel();
    super.dispose();
  }
}

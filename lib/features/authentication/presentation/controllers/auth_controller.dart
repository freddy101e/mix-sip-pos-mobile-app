import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(),
);
final authSessionEventsProvider = Provider<AuthSessionEvents>((ref) {
  final events = AuthSessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(tokenStorageProvider),
    onUnauthorized: ref.watch(authSessionEventsProvider).unauthorized,
  ),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    events: ref.watch(authSessionEventsProvider),
  )..restore(),
);

class AuthSessionEvents {
  final _unauthorized = StreamController<void>.broadcast(sync: true);

  Stream<void> get unauthorizedEvents => _unauthorized.stream;
  void unauthorized() => _unauthorized.add(null);
  void dispose() => _unauthorized.close();
}

enum AuthStatus { restoring, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.restoring,
    this.user,
    this.error,
    this.submitting = false,
  });
  final AuthStatus status;
  final AppUser? user;
  final AppException? error;
  final bool submitting;
  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    AppException? error,
    bool? submitting,
    bool clearError = false,
    bool clearUser = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : user ?? this.user,
    error: clearError ? null : error ?? this.error,
    submitting: submitting ?? this.submitting,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, {AuthSessionEvents? events})
    : super(const AuthState()) {
    _unauthorizedSubscription = events?.unauthorizedEvents.listen(
      (_) => unauthorized(),
    );
  }
  final AuthDataSource _repository;
  StreamSubscription<void>? _unauthorizedSubscription;
  Future<void> restore() async {
    final user = await _repository.restore();
    state = AuthState(
      status:
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
      user: user,
    );
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final user = await _repository.login(username, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AppException catch (error) {
      state = state.copyWith(submitting: false, error: error);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Local logout must still complete when server revocation is unavailable.
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void unauthorized() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _unauthorizedSubscription?.cancel();
    super.dispose();
  }
}

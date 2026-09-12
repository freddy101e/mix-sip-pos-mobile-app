import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/session_loading_screen.dart';
import '../../features/attendance/presentation/screens/punch_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/register/presentation/screens/register_balance_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (auth.status == AuthStatus.restoring) {
        return location == '/loading' ? null : '/loading';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }
      if (location == '/login' || location == '/loading') return '/';
      final permissions = auth.user?.permissions ?? const <String>{};
      if (location == '/pos' && !permissions.contains('pos.menu')) return '/';
      if (location == '/orders' && !permissions.contains('orders.menu')) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => const SessionLoadingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/pos', builder: (_, _) => const PosScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(path: '/punch', builder: (_, _) => const PunchScreen()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterBalanceScreen(),
      ),
    ],
  );
});

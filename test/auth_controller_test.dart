import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/features/authentication/data/auth_repository.dart';
import 'package:invoiceandbilling/features/authentication/domain/app_user.dart';
import 'package:invoiceandbilling/features/authentication/presentation/controllers/auth_controller.dart';

void main() {
  test(
    'failed server logout still leaves local state unauthenticated',
    () async {
      final controller = AuthController(_FailingLogoutDataSource());
      await controller.login('admin', 'secret');

      await controller.logout();
      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.user, isNull);
    },
  );

  test('unauthorized event immediately clears authenticated state', () async {
    final controller = AuthController(_FailingLogoutDataSource());
    await controller.login('admin', 'secret');

    controller.unauthorized();

    expect(controller.state.status, AuthStatus.unauthenticated);
    expect(controller.state.user, isNull);
  });
}

class _FailingLogoutDataSource implements AuthDataSource {
  static const user = AppUser(
    id: 1,
    name: 'Admin',
    username: 'admin',
    roles: ['SuperAdmin'],
    permissions: {'pos.menu'},
  );

  @override
  Future<AppUser> login(String username, String password) async => user;

  @override
  Future<void> logout() async => throw Exception('Server unavailable');

  @override
  Future<AppUser?> restore() async => user;
}

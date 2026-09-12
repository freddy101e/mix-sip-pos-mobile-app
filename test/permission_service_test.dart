import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceandbilling/core/permissions/permission_service.dart';

void main() {
  const service = PermissionService({'pos.menu', 'orders.menu'});
  test('uses exact Laravel permission names', () {
    expect(service.can('pos.menu'), isTrue);
    expect(service.can('POS.MENU'), isFalse);
    expect(service.hasAll(['pos.menu', 'orders.menu']), isTrue);
  });
}

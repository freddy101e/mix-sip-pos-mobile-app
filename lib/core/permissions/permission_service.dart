class PermissionService {
  const PermissionService(this.permissions);
  final Set<String> permissions;
  bool can(String permission) => permissions.contains(permission);
  bool hasAny(Iterable<String> values) => values.any(can);
  bool hasAll(Iterable<String> values) => values.every(can);
}

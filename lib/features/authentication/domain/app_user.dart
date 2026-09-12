class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.roles,
    required this.permissions,
    this.email,
  });
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['id'] as num).toInt(),
    name: json['name'].toString(),
    username: json['username'].toString(),
    email: json['email']?.toString(),
    roles:
        (json['roles'] as List? ?? const []).map((e) => e.toString()).toList(),
    permissions:
        (json['permissions'] as List? ?? const [])
            .map((e) => e.toString())
            .toSet(),
  );
  final int id;
  final String name;
  final String username;
  final String? email;
  final List<String> roles;
  final Set<String> permissions;
}

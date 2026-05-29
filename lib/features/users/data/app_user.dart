
// ===== DATA MODEL =====
class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role; // 'admin' | 'kasir'
  final bool isActive;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  AppUser copyWith({String? name, String? username, String? email, String? role, bool? isActive}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_user.dart';

final usersProvider = NotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);

class UsersNotifier extends Notifier<List<AppUser>> {
  @override
  List<AppUser> build() => [
    const AppUser(id: '1', name: 'Admin System', username: 'admin', email: 'admin@pos.com', role: 'admin', createdAt: '2026-01-01'),
    const AppUser(id: '2', name: 'Budi Santoso', username: 'budi', email: 'budi@pos.com', role: 'kasir', createdAt: '2026-01-15'),
    const AppUser(id: '3', name: 'Sari Wijaya', username: 'sari', email: 'sari@pos.com', role: 'kasir', createdAt: '2026-02-01'),
  ];

  void addUser(AppUser user) {
    state = [...state, user];
  }

  void updateUser(String id, AppUser updated) {
    state = [for (final u in state) if (u.id == id) updated else u];
  }

  void deleteUser(String id) {
    state = state.where((u) => u.id != id).toList();
  }

  void toggleActive(String id) {
    state = [for (final u in state) if (u.id == id) u.copyWith(isActive: !u.isActive) else u];
  }
}

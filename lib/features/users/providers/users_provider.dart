import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_user.dart';
import '../data/user_local_repository.dart';

final usersProvider = NotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);

class UsersNotifier extends Notifier<List<AppUser>> {
  late final UserLocalRepository _repository;

  @override
  List<AppUser> build() {
    _repository = ref.watch(userRepositoryProvider);
    Future.microtask(() => loadUsers());
    return [];
  }

  Future<void> loadUsers() async {
    try {
      final list = await _repository.getAll();
      state = list;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addUser(AppUser user) async {
    try {
      final newUser = await _repository.create(user);
      state = [...state, newUser];
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateUser(String id, AppUser updated) async {
    try {
      await _repository.update(id, updated);
      state = [for (final u in state) if (u.id == id) updated else u];
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _repository.delete(id);
      state = state.where((u) => u.id != id).toList();
    } catch (e) {
      // Handle error
    }
  }

  void toggleActive(String id) {
    state = [for (final u in state) if (u.id == id) u.copyWith(isActive: !u.isActive) else u];
    // In a real app we would persist this toggle to database, e.g.:
    final user = state.firstWhere((u) => u.id == id);
    _repository.update(id, user);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_user.dart';
import '../data/user_local_repository.dart';
import '../../auth/providers/auth_provider.dart';

final usersProvider = NotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);

class UsersNotifier extends Notifier<List<AppUser>> {
  late final UserLocalRepository _repository;

  @override
  List<AppUser> build() {
    _repository = ref.watch(userRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);
    Future.microtask(() => loadUsers(storeId: storeId));
    return [];
  }

  Future<void> loadUsers({String? storeId}) async {
    try {
      final activeStoreId = storeId ?? ref.read(activeStoreIdProvider);
      final list = await _repository.getAllForStore(activeStoreId);
      if (ref.mounted) {
        state = list;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addUser(AppUser user) async {
    try {
      final storeId = ref.read(activeStoreIdProvider);
      final currentUser = ref.read(currentUserProvider).value;
      final userWithStore = user.copyWith(
        storeId: (user.storeId != null && user.storeId!.isNotEmpty) ? user.storeId : storeId,
        adminId: (user.adminId != null && user.adminId!.isNotEmpty) ? user.adminId : (currentUser?.id ?? '1'),
      );
      final newUser = await _repository.create(userWithStore);
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
    final user = state.firstWhere((u) => u.id == id);
    _repository.update(id, user);
  }
}

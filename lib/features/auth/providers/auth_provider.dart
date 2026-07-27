import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../users/data/app_user.dart';
import '../../users/data/user_local_repository.dart';
import '../../settings/data/settings_local_repository.dart';

import '../../transactions/providers/cart_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../users/providers/users_provider.dart';
import '../../reports/providers/reports_provider.dart';
import '../../reports/providers/transactions_report_provider.dart';

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppUser?> {
  late final UserLocalRepository _userRepository;

  @override
  AppUser? build() {
    _userRepository = ref.watch(userRepositoryProvider);
    _checkLoginStatus();
    return null;
  }

  void _invalidateAllDomainProviders() {
    ref.read(cartProvider.notifier).clearCart();
    ref.invalidate(productNotifierProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(usersProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(activeShiftProvider);
    ref.invalidate(closedShiftsProvider);
    ref.invalidate(dailyReportsProvider);
    ref.invalidate(allTransactionsNotifierProvider);
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        final userId = prefs.getString('loggedInUserId');
        if (userId != null) {
          final user = await _userRepository.getById(userId);
          if (user != null) {
            state = user;
            return;
          }
        }
      }
      state = null;
    } catch (_) {
      state = null;
    }
  }

  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Brief UX pause
    
    final authenticatedUser = await _userRepository.authenticate(username, password);
    if (authenticatedUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loggedInUserId', authenticatedUser.id);
      await prefs.setString('loggedInUserRole', authenticatedUser.role);
      state = authenticatedUser;
      _invalidateAllDomainProviders();
    } else {
      throw Exception('Username atau password salah.');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('loggedInUserId');
      await prefs.remove('loggedInUserRole');
    } catch (_) {}

    try {
      _invalidateAllDomainProviders();
    } catch (_) {}

    state = null;
  }

  Future<void> reloadCurrentUser() async {
    if (state == null) return;
    final user = await _userRepository.getById(state!.id);
    if (user != null) {
      state = user;
    }
  }

  Future<void> signUp(
    String username,
    String password, {
    String? fullName,
    String? email,
    String? storeName,
  }) async {
    final existingUser = await _userRepository.getByUsername(username);
    if (existingUser != null) {
      throw Exception('Username sudah terdaftar.');
    }

    if (email != null && email.trim().isNotEmpty) {
      final existingEmail = await _userRepository.getByEmail(email.trim());
      if (existingEmail != null) {
        throw Exception('Email sudah terdaftar.');
      }
    }

    final storeRepo = ref.read(settingsRepositoryProvider);
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final storeId = 'store_${DateTime.now().millisecondsSinceEpoch}';
    final nameStore = (storeName != null && storeName.trim().isNotEmpty)
        ? storeName.trim()
        : 'Toko ${username.trim()}';

    // 1. Create Store in stores table
    await storeRepo.createStore(
      id: storeId,
      ownerId: userId,
      storeName: nameStore,
    );

    // 2. Create Admin User linked to storeId
    final newUser = AppUser(
      id: userId,
      name: (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : username.trim(),
      username: username.trim(),
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : '${username.trim()}@example.com',
      role: 'admin',
      storeId: storeId,
      adminId: userId,
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
      password: password,
    );

    await _userRepository.create(newUser);
  }
}

final currentUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final user = ref.watch(authProvider);
  return AsyncData(user);
});

final activeStoreIdProvider = Provider<String>((ref) {
  final user = ref.watch(authProvider);
  return user?.storeId ?? 'store-uuid-001';
});

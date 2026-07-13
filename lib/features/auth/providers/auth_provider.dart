import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../users/data/app_user.dart';
import '../../users/data/user_local_repository.dart';


final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  late final UserLocalRepository _userRepository;

  @override
  bool build() {
    _userRepository = ref.watch(userRepositoryProvider);
    _checkLoginStatus();
    return false;
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    state = isLoggedIn;
  }

  Future<void> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Brief UX pause
    
    final authenticatedUser = await _userRepository.authenticate(username, password);
    if (authenticatedUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loggedInUserId', authenticatedUser.id);
      await prefs.setString('loggedInUserRole', authenticatedUser.role);
      state = true;
    } else {
      throw Exception('Username atau password salah.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('loggedInUserId');
    await prefs.remove('loggedInUserRole');
    state = false;
  }

  Future<void> signUp(String username, String password) async {
    final existingUser = await _userRepository.getByUsername(username);
    if (existingUser != null) {
      throw Exception('Username sudah terdaftar.');
    }

    final newUser = AppUser(
      id: '', // Will be assigned by database auto-increment
      name: username.trim(),
      username: username.trim(),
      email: '${username.trim()}@example.com',
      role: 'admin', // Default role for self registration
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
      password: password,
    );

    await _userRepository.create(newUser);
  }
}

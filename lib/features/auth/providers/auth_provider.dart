import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Initial state is false, but we check shared preferences asynchronously.
    // The UI should handle this fast enough, or we could use AsyncNotifier if needed.
    // For simplicity, we keep it as a sync Notifier and update state later.
    _checkLoginStatus();
    return false;
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    state = isLoggedIn;
  }

  Future<void> login(String username, String password) async {
    // Dummy login logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    if (username.isNotEmpty && password == "123456") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      state = true;
    } else {
      throw Exception('Invalid username or password');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    state = false;
  }
}

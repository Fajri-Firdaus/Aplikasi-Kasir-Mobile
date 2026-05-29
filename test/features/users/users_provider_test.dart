import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/users/providers/users_provider.dart';
import 'package:mobile_pos_flutter/features/users/data/app_user.dart';
import 'package:mobile_pos_flutter/features/settings/providers/settings_provider.dart';

void main() {
  test('UsersNotifier adds new employee', () {
    final container = ProviderContainer();
    final notifier = container.read(usersProvider.notifier);
    
    final newUser = AppUser(
      id: '99',
      name: 'Karyawan Baru',
      username: 'karyawan',
      email: 'karyawan@pos.com',
      role: 'kasir',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    notifier.addUser(newUser);
    final users = container.read(usersProvider);
    
    expect(users.any((u) => u.name == 'Karyawan Baru'), true);
  });

  test('SettingsNotifier updates store name', () {
    final container = ProviderContainer();
    final notifier = container.read(settingsProvider.notifier);
    
    notifier.updateStoreName('Toko Maju Jaya');
    final settings = container.read(settingsProvider);
    
    expect(settings.storeName, 'Toko Maju Jaya');
  });
}

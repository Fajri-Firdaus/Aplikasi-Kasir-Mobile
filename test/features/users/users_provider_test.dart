import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/users/providers/users_provider.dart';
import 'package:mobile_pos_flutter/features/users/data/app_user.dart';
import 'package:mobile_pos_flutter/features/settings/providers/settings_provider.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWith((ref) => LocalDatabaseService(isTesting: true)),
      ],
    );
    addTearDown(() {
      container.read(localDatabaseServiceProvider).close();
      container.dispose();
    });
    return container;
  }

  test('UsersNotifier adds new employee to SQLite', () async {
    final container = createContainer();
    final notifier = container.read(usersProvider.notifier);
    
    // Wait for initial database seeding/loading
    await notifier.loadUsers();

    final newUser = AppUser(
      id: '', // database auto-increment
      name: 'Karyawan Baru',
      username: 'karyawan',
      email: 'karyawan@pos.com',
      role: 'kasir',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await notifier.addUser(newUser);
    
    final users = container.read(usersProvider);
    expect(users.any((u) => u.name == 'Karyawan Baru'), true);
  });

  test('SettingsNotifier updates store name in SQLite', () async {
    final container = createContainer();
    final notifier = container.read(settingsProvider.notifier);
    
    // Wait for initial microtask load to finish
    await Future.delayed(const Duration(milliseconds: 200));

    await notifier.updateStoreName('Toko Maju Jaya');
    final settings = container.read(settingsProvider);
    
    expect(settings.storeName, 'Toko Maju Jaya');
  });
}

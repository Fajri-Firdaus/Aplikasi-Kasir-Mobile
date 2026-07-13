import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/core/data/local_database_service.dart';
import 'package:mobile_pos_flutter/features/auth/providers/auth_provider.dart';
import '../../test_helper.dart';

void main() {
  setupTestDatabase();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test('AuthNotifier initial state is false', () {
    final container = createContainer();
    expect(container.read(authProvider), false);
  });

  test('AuthNotifier login success sets state to true', () async {
    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    
    await notifier.login('admin', '123456');
    expect(container.read(authProvider), true);
  });

  test('AuthNotifier login fails with wrong password', () async {
    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    
    expect(
      () async => await notifier.login('admin', 'wrong'),
      throwsException,
    );
    expect(container.read(authProvider), false);
  });

  test('AuthNotifier logout sets state to false', () async {
    final container = createContainer();
    final notifier = container.read(authProvider.notifier);
    
    await notifier.login('admin', '123456');
    expect(container.read(authProvider), true);
    
    await notifier.logout();
    expect(container.read(authProvider), false);
  });

  test('AuthNotifier signUp success allows login', () async {
    final container = createContainer();
    final notifier = container.read(authProvider.notifier);

    // Sign up a new user
    await notifier.signUp('newuser', 'password123');

    // Login with the new user should succeed
    await notifier.login('newuser', 'password123');
    expect(container.read(authProvider), true);
  });

  test('AuthNotifier signUp fails with duplicate username', () async {
    final container = createContainer();
    final notifier = container.read(authProvider.notifier);

    // 'admin' is already seeded in the database
    expect(
      () async => await notifier.signUp('admin', 'password123'),
      throwsException,
    );
  });
}

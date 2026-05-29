import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos_flutter/features/auth/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
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
}

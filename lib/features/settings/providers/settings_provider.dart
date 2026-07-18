import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_settings.dart';
import '../data/settings_local_repository.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  late final SettingsLocalRepository _repository;

  @override
  AppSettings build() {
    _repository = ref.watch(settingsRepositoryProvider);
    Future.microtask(() => loadSettings());
    return const AppSettings(
      storeName: 'Mobile POS Dashboard',
      storeAddress: 'Jl. Merdeka No. 123',
      storePhone: '08123456789',
    );
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = settings;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateStoreName(String name) async {
    final updated = state.copyWith(storeName: name);
    state = updated;
    await _repository.updateSettings(updated);
  }

  Future<void> updateStoreAddress(String address) async {
    final updated = state.copyWith(storeAddress: address);
    state = updated;
    await _repository.updateSettings(updated);
  }

  Future<void> updateStorePhone(String phone) async {
    final updated = state.copyWith(storePhone: phone);
    state = updated;
    await _repository.updateSettings(updated);
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = settings;
    await _repository.updateSettings(settings);
  }
}

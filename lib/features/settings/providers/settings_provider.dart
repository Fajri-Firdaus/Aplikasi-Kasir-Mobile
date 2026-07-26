import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_settings.dart';
import '../data/settings_local_repository.dart';
import '../../auth/providers/auth_provider.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  late final SettingsLocalRepository _repository;

  @override
  AppSettings build() {
    _repository = ref.watch(settingsRepositoryProvider);
    final storeId = ref.watch(activeStoreIdProvider);

    Future.microtask(() => loadSettings(storeId: storeId));
    return AppSettings(
      id: storeId,
      storeName: '',
      storeAddress: '',
      storePhone: '',
    );
  }

  Future<void> loadSettings({String? storeId}) async {
    try {
      final activeStoreId = storeId ?? ref.read(activeStoreIdProvider);
      final res = await _repository.getSettings(storeId: activeStoreId);
      if (ref.mounted) {
        state = res;
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateStoreName(String name) async {
    final updated = state.copyWith(storeName: name);
    state = updated;
    await updateSettings(updated);
  }

  Future<void> updateStoreAddress(String address) async {
    final updated = state.copyWith(storeAddress: address);
    state = updated;
    await updateSettings(updated);
  }

  Future<void> updateStorePhone(String phone) async {
    final updated = state.copyWith(storePhone: phone);
    state = updated;
    await updateSettings(updated);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final storeId = ref.read(activeStoreIdProvider);
    final toSave = settings.copyWith(id: settings.id ?? storeId);
    state = toSave;
    await _repository.updateSettings(toSave, storeId: storeId);
  }
}

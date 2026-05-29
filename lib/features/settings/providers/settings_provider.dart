import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;

  const AppSettings({
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
  });

  AppSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) {
    return AppSettings(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return const AppSettings(
      storeName: 'Mobile POS Dashboard',
      storeAddress: 'Jl. Merdeka No. 123',
      storePhone: '08123456789',
    );
  }

  void updateStoreName(String name) {
    state = state.copyWith(storeName: name);
  }

  void updateStoreAddress(String address) {
    state = state.copyWith(storeAddress: address);
  }

  void updateStorePhone(String phone) {
    state = state.copyWith(storePhone: phone);
  }
}

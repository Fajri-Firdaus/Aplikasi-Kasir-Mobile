import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    String? id,
    String? ownerId,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    @Default('Terima kasih atas kunjungan Anda!') String receiptFooter,
    String? updatedAt,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}

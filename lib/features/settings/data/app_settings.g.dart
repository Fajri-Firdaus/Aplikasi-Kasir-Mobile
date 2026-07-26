// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  id: json['id'] as String?,
  ownerId: json['ownerId'] as String?,
  storeName: json['storeName'] as String,
  storeAddress: json['storeAddress'] as String,
  storePhone: json['storePhone'] as String,
  receiptFooter:
      json['receiptFooter'] as String? ?? 'Terima kasih atas kunjungan Anda!',
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'storeName': instance.storeName,
      'storeAddress': instance.storeAddress,
      'storePhone': instance.storePhone,
      'receiptFooter': instance.receiptFooter,
      'updatedAt': instance.updatedAt,
    };

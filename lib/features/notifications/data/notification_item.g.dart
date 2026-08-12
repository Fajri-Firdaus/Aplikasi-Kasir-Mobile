// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    _NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type:
          $enumDecodeNullable(_$NotificationTypeEnumMap, json['type']) ??
          NotificationType.info,
      isRead: json['isRead'] as bool? ?? false,
      targetRoute: json['targetRoute'] as String?,
    );

Map<String, dynamic> _$NotificationItemToJson(_NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'isRead': instance.isRead,
      'targetRoute': instance.targetRoute,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.warning: 'warning',
  NotificationType.success: 'success',
  NotificationType.info: 'info',
  NotificationType.alert: 'alert',
};

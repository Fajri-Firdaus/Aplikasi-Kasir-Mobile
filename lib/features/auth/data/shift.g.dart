// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shift _$ShiftFromJson(Map<String, dynamic> json) => _Shift(
  id: json['id'] as String,
  userId: json['userId'] as String,
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String?,
  startingCash: (json['startingCash'] as num?)?.toDouble() ?? 0.0,
  endingCash: (json['endingCash'] as num?)?.toDouble() ?? 0.0,
  status: json['status'] as String? ?? 'open',
);

Map<String, dynamic> _$ShiftToJson(_Shift instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'startingCash': instance.startingCash,
  'endingCash': instance.endingCash,
  'status': instance.status,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  shiftId: json['shiftId'] as String,
  customerId: json['customerId'] as String?,
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentMethod: json['paymentMethod'] as String,
  cashReceived: (json['cashReceived'] as num?)?.toDouble() ?? 0.0,
  status: json['status'] as String? ?? 'completed',
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shiftId': instance.shiftId,
      'customerId': instance.customerId,
      'totalAmount': instance.totalAmount,
      'paymentMethod': instance.paymentMethod,
      'cashReceived': instance.cashReceived,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

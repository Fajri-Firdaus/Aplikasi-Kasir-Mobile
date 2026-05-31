// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionDetail _$TransactionDetailFromJson(Map<String, dynamic> json) =>
    _TransactionDetail(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
      buyPriceAtSale: (json['buyPriceAtSale'] as num).toDouble(),
      sellPriceAtSale: (json['sellPriceAtSale'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionDetailToJson(_TransactionDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transactionId': instance.transactionId,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'buyPriceAtSale': instance.buyPriceAtSale,
      'sellPriceAtSale': instance.sellPriceAtSale,
    };

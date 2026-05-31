// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  imageUrl: json['imageUrl'] as String,
  stock: (json['stock'] as num).toInt(),
  sku: json['sku'] as String?,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'category': instance.category,
  'imageUrl': instance.imageUrl,
  'stock': instance.stock,
  'sku': instance.sku,
  'isActive': instance.isActive,
};

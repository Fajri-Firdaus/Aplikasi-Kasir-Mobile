// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionDetail {

 String get id; String get transactionId; String get productId; int get quantity; double get buyPriceAtSale; double get sellPriceAtSale;
/// Create a copy of TransactionDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionDetailCopyWith<TransactionDetail> get copyWith => _$TransactionDetailCopyWithImpl<TransactionDetail>(this as TransactionDetail, _$identity);

  /// Serializes this TransactionDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.buyPriceAtSale, buyPriceAtSale) || other.buyPriceAtSale == buyPriceAtSale)&&(identical(other.sellPriceAtSale, sellPriceAtSale) || other.sellPriceAtSale == sellPriceAtSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,transactionId,productId,quantity,buyPriceAtSale,sellPriceAtSale);

@override
String toString() {
  return 'TransactionDetail(id: $id, transactionId: $transactionId, productId: $productId, quantity: $quantity, buyPriceAtSale: $buyPriceAtSale, sellPriceAtSale: $sellPriceAtSale)';
}


}

/// @nodoc
abstract mixin class $TransactionDetailCopyWith<$Res>  {
  factory $TransactionDetailCopyWith(TransactionDetail value, $Res Function(TransactionDetail) _then) = _$TransactionDetailCopyWithImpl;
@useResult
$Res call({
 String id, String transactionId, String productId, int quantity, double buyPriceAtSale, double sellPriceAtSale
});




}
/// @nodoc
class _$TransactionDetailCopyWithImpl<$Res>
    implements $TransactionDetailCopyWith<$Res> {
  _$TransactionDetailCopyWithImpl(this._self, this._then);

  final TransactionDetail _self;
  final $Res Function(TransactionDetail) _then;

/// Create a copy of TransactionDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? transactionId = null,Object? productId = null,Object? quantity = null,Object? buyPriceAtSale = null,Object? sellPriceAtSale = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,buyPriceAtSale: null == buyPriceAtSale ? _self.buyPriceAtSale : buyPriceAtSale // ignore: cast_nullable_to_non_nullable
as double,sellPriceAtSale: null == sellPriceAtSale ? _self.sellPriceAtSale : sellPriceAtSale // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionDetail].
extension TransactionDetailPatterns on TransactionDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionDetail value)  $default,){
final _that = this;
switch (_that) {
case _TransactionDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionDetail value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String transactionId,  String productId,  int quantity,  double buyPriceAtSale,  double sellPriceAtSale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionDetail() when $default != null:
return $default(_that.id,_that.transactionId,_that.productId,_that.quantity,_that.buyPriceAtSale,_that.sellPriceAtSale);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String transactionId,  String productId,  int quantity,  double buyPriceAtSale,  double sellPriceAtSale)  $default,) {final _that = this;
switch (_that) {
case _TransactionDetail():
return $default(_that.id,_that.transactionId,_that.productId,_that.quantity,_that.buyPriceAtSale,_that.sellPriceAtSale);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String transactionId,  String productId,  int quantity,  double buyPriceAtSale,  double sellPriceAtSale)?  $default,) {final _that = this;
switch (_that) {
case _TransactionDetail() when $default != null:
return $default(_that.id,_that.transactionId,_that.productId,_that.quantity,_that.buyPriceAtSale,_that.sellPriceAtSale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionDetail implements TransactionDetail {
  const _TransactionDetail({required this.id, required this.transactionId, required this.productId, required this.quantity, required this.buyPriceAtSale, required this.sellPriceAtSale});
  factory _TransactionDetail.fromJson(Map<String, dynamic> json) => _$TransactionDetailFromJson(json);

@override final  String id;
@override final  String transactionId;
@override final  String productId;
@override final  int quantity;
@override final  double buyPriceAtSale;
@override final  double sellPriceAtSale;

/// Create a copy of TransactionDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionDetailCopyWith<_TransactionDetail> get copyWith => __$TransactionDetailCopyWithImpl<_TransactionDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.buyPriceAtSale, buyPriceAtSale) || other.buyPriceAtSale == buyPriceAtSale)&&(identical(other.sellPriceAtSale, sellPriceAtSale) || other.sellPriceAtSale == sellPriceAtSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,transactionId,productId,quantity,buyPriceAtSale,sellPriceAtSale);

@override
String toString() {
  return 'TransactionDetail(id: $id, transactionId: $transactionId, productId: $productId, quantity: $quantity, buyPriceAtSale: $buyPriceAtSale, sellPriceAtSale: $sellPriceAtSale)';
}


}

/// @nodoc
abstract mixin class _$TransactionDetailCopyWith<$Res> implements $TransactionDetailCopyWith<$Res> {
  factory _$TransactionDetailCopyWith(_TransactionDetail value, $Res Function(_TransactionDetail) _then) = __$TransactionDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String transactionId, String productId, int quantity, double buyPriceAtSale, double sellPriceAtSale
});




}
/// @nodoc
class __$TransactionDetailCopyWithImpl<$Res>
    implements _$TransactionDetailCopyWith<$Res> {
  __$TransactionDetailCopyWithImpl(this._self, this._then);

  final _TransactionDetail _self;
  final $Res Function(_TransactionDetail) _then;

/// Create a copy of TransactionDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? transactionId = null,Object? productId = null,Object? quantity = null,Object? buyPriceAtSale = null,Object? sellPriceAtSale = null,}) {
  return _then(_TransactionDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,buyPriceAtSale: null == buyPriceAtSale ? _self.buyPriceAtSale : buyPriceAtSale // ignore: cast_nullable_to_non_nullable
as double,sellPriceAtSale: null == sellPriceAtSale ? _self.sellPriceAtSale : sellPriceAtSale // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

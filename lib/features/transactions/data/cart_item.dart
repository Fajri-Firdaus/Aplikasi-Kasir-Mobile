import 'package:freezed_annotation/freezed_annotation.dart';
import '../../products/data/product.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
abstract class CartItem with _$CartItem {
  const CartItem._(); // Required for custom getters

  const factory CartItem({
    required Product product,
    @Default(1) int quantity,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);

  double get totalPrice => product.price * quantity;
}

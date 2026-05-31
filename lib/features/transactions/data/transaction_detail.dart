import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_detail.freezed.dart';
part 'transaction_detail.g.dart';

@freezed
abstract class TransactionDetail with _$TransactionDetail {
  const factory TransactionDetail({
    required String id,
    required String transactionId,
    required String productId,
    required int quantity,
    required double buyPriceAtSale,
    required double sellPriceAtSale,
  }) = _TransactionDetail;

  factory TransactionDetail.fromJson(Map<String, dynamic> json) => _$TransactionDetailFromJson(json);
}

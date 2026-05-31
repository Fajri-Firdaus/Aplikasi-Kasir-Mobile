import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String shiftId,
    String? customerId,
    required double totalAmount,
    required String paymentMethod,
    @Default(0.0) double cashReceived,
    @Default('completed') String status,
    required String createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}

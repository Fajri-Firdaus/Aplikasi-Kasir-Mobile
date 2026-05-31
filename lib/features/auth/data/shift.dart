import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

@freezed
abstract class Shift with _$Shift {
  const factory Shift({
    required String id,
    required String userId,
    required String startTime,
    String? endTime,
    @Default(0.0) double startingCash,
    @Default(0.0) double endingCash,
    @Default('open') String status,
  }) = _Shift;

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);
}

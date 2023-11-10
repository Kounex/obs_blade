import 'package:freezed_annotation/freezed_annotation.dart';

part 'input_channel.freezed.dart';
part 'input_channel.g.dart';

@freezed
class InputChannel with _$InputChannel {
  const factory InputChannel({
    required double? current,
    required double? average,
    required double? potential,
  }) = _InputChannel;

  factory InputChannel.fromJson(Map<String, Object?> json) =>
      _$InputChannelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_drop_reason.freezed.dart';
part 'twitch_drop_reason.g.dart';

/// Helix `chat/messages` drop reason — an OBJECT (not a string), present
/// when Twitch accepted but dropped a message (`isSent == false`).
/// [message] is Twitch's own human-readable explanation.
@Freezed(fromJson: true, toJson: false)
abstract class TwitchDropReason with _$TwitchDropReason {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchDropReason({
    required String code,
    String? message,
  }) = _TwitchDropReason;

  factory TwitchDropReason.fromJson(Map<String, Object?> json) =>
      _$TwitchDropReasonFromJson(json);
}

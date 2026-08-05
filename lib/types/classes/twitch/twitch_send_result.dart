import 'package:freezed_annotation/freezed_annotation.dart';

import 'twitch_drop_reason.dart';

part 'twitch_send_result.freezed.dart';
part 'twitch_send_result.g.dart';

/// Result of Helix `chat/messages` — the endpoint can accept a message but
/// drop it (`isSent == false`, e.g. AutoMod), so both halves are surfaced.
@Freezed(fromJson: true, toJson: false)
abstract class TwitchSendResult with _$TwitchSendResult {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchSendResult({
    required String messageId,
    required bool isSent,
    TwitchDropReason? dropReason,
  }) = _TwitchSendResult;

  factory TwitchSendResult.fromJson(Map<String, Object?> json) =>
      _$TwitchSendResultFromJson(json);
}

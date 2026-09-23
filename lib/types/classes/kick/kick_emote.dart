import 'package:freezed_annotation/freezed_annotation.dart';

part 'kick_emote.freezed.dart';
part 'kick_emote.g.dart';

/// One emote from a `GET https://kick.com/emotes/{slug}` set — picker-only.
/// Inline rendering of emotes already IN a message goes through the
/// `[emote:id:name]` token path ([parseKickChatContent] in
/// `kick_chat_message.dart`); this DTO only feeds
/// [KickEmoteSection]/`KickEmoteStore` for the compose-time picker.
@Freezed(fromJson: true, toJson: false)
abstract class KickEmote with _$KickEmote {
  const factory KickEmote({
    required int id,
    required String name,
    @JsonKey(name: 'subscribers_only') @Default(false) bool subscribersOnly,
  }) = _KickEmote;

  factory KickEmote.fromJson(Map<String, Object?> json) =>
      _$KickEmoteFromJson(json);
}

/// One labeled group in the picker. `GET /emotes/{slug}` returns the
/// requested channel's own set (label `Channel`) plus Kick's
/// platform-wide `Global` and `Emojis` sets in the SAME response — see
/// [KickEmoteService.fetchChannelEmotes] for the verified shape.
class KickEmoteSection {
  final String label;
  final List<KickEmote> emotes;

  const KickEmoteSection({required this.label, required this.emotes});
}

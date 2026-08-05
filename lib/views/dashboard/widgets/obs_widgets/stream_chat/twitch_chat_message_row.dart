import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';

/// One chat line: role badges + colored author name + message text with
/// inline emotes. Cheermote/mention fragments fall back to plain text.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  /// Settings box — the badge visibility toggles
  /// ([settingsKeyForBadgeSetId]), read with default-on.
  final Box settingsBox;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
  });

  static const double _emoteSize = 20.0;
  static const double _badgeSize = 18.0;

  Color _authorColor(BuildContext context) {
    final hex = this.event.color;
    if (hex != null && hex.length == 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  }

  /// Badges before the author name, in payload order. Unknown badges
  /// (catalog not loaded yet, new Twitch set) and toggled-off categories
  /// are skipped silently.
  List<InlineSpan> _badgeSpans() {
    if (this.event.badges.isEmpty) return const [];
    final badgeStore = GetIt.instance<TwitchBadgeStore>();
    return [
      for (final badge in this.event.badges)
        if (this.settingsBox.get(
          settingsKeyForBadgeSetId(badge.setId).name,
          defaultValue: true,
        ))
          if (badgeStore.badgeVersion(badge.setId, badge.id)
              case final version?)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
                child: Image.network(
                  version.imageUrl2x,
                  height: _badgeSize,
                  width: _badgeSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
    ];
  }

  List<InlineSpan> _messageSpans() {
    final fragments = this.event.message.fragments;
    if (fragments.isEmpty) {
      return [TextSpan(text: this.event.message.text)];
    }
    return [
      for (final fragment in fragments)
        if (fragment.type == 'emote' && fragment.emote != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              twitchEmoteUrl(fragment.emote!.id),
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(fragment.text),
            ),
          )
        else
          TextSpan(text: fragment.text),
    ];
  }

  /// Badge-less rows never change — an Observer that tracks nothing
  /// spams flutter_mobx's "No observables" warning, so only rows with
  /// badges observe the catalog (arrivals/changes rebuild them;
  /// toggle changes come from the HiveBuilder above the list).
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: this.event.badges.isEmpty
          ? this._richText(context)
          : Observer(builder: this._richText),
    );
  }

  Text _richText(BuildContext context) => Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            ...this._badgeSpans(),
            TextSpan(
              text: this.event.chatterUserName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: this._authorColor(context),
              ),
            ),
            const TextSpan(text: ': '),
            ...this._messageSpans(),
          ],
        ),
      );
}

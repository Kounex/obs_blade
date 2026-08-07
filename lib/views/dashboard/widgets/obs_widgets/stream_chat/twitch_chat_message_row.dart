import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// One chat line: role badges + colored author name + message text with
/// inline emotes (first-party fragments and third-party 7TV/BTTV tokens).
/// Cheermote/mention fragments fall back to plain text.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  /// Settings box — the badge visibility toggles
  /// ([settingsKeyForBadgeSetId]) plus the third-party emote toggle
  /// ([SettingsKeys.TwitchChatThirdPartyEmotes]), read with default-on.
  final Box settingsBox;

  /// Moderation tombstone — username/badges stay; the body renders its
  /// original content dimmed (Twitch mod view) with a ` —Deleted` marker
  /// (set by the window from the store's lifecycle state).
  final bool isDeleted;

  /// Display name of the moderator who deleted this message — only single
  /// deletes carry one (purge//clear payloads don't). Non-null together
  /// with [isDeleted] makes the row tappable ([onDeletedTap]).
  final String? deletedActor;

  /// Whether the actor reveal line under a deleted message is expanded.
  final bool isDeletedExpanded;

  /// Tap handler for a deleted message — toggles the reveal line.
  /// Tappability is gated on [isDeleted] + [deletedActor]; a null
  /// callback with an actor yields an inert, tap-swallowing target.
  final VoidCallback? onDeletedTap;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.isDeleted = false,
    this.deletedActor,
    this.isDeletedExpanded = false,
    this.onDeletedTap,
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
          ...this._textSpans(fragment.text),
    ];
  }

  /// Body spans for a deleted message — the content stays (Twitch mod
  /// view) but dims hard: text recolors to half the marker's opacity and
  /// emote images get a matching [Opacity]. Structure, spacing and error
  /// builders are preserved. Assumes [_messageSpans] results are flat and
  /// recognizer-less (true today: plain TextSpans + emote WidgetSpans).
  List<InlineSpan> _dimmedMessageSpans(BuildContext context) {
    final color = Theme.of(context)
        .textTheme
        .bodySmall
        ?.color
        ?.withValues(alpha: 0.5);
    return [
      for (final span in this._messageSpans())
        if (span is TextSpan)
          TextSpan(text: span.text, style: TextStyle(color: color))
        else if (span is WidgetSpan)
          WidgetSpan(
            alignment: span.alignment,
            child: Opacity(opacity: 0.5, child: span.child),
          )
        else
          span,
    ];
  }

  /// Third-party emotes (7TV/BTTV) arrive as plain text — split on
  /// spaces and swap known tokens for inline images, preserving spacing
  /// exactly. Unknown tokens (and the toggle-off case) stay text.
  List<InlineSpan> _textSpans(String text) {
    if (!this.settingsBox.get(
      SettingsKeys.TwitchChatThirdPartyEmotes.name,
      defaultValue: true,
    )) {
      return [TextSpan(text: text)];
    }
    final emoteStore = GetIt.instance<ThirdPartyEmoteStore>();
    final tokens = text.split(' ');
    return [
      for (var i = 0; i < tokens.length; i++) ...[
        if (i > 0) const TextSpan(text: ' '),
        if (emoteStore.emoteImageUrl(tokens[i]) case final imageUrl?)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              imageUrl,
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(tokens[i]),
            ),
          )
        else
          TextSpan(text: tokens[i]),
      ],
    ];
  }

  /// Badge-less rows never change — an Observer that tracks nothing
  /// spams flutter_mobx's "No observables" warning, so only rows with
  /// badges observe the catalog (arrivals/changes rebuild them;
  /// toggle changes come from the HiveBuilder above the list).
  @override
  Widget build(BuildContext context) {
    final Widget line = this.event.badges.isEmpty
        ? this._richText(context)
        : Observer(builder: this._richText);
    final bool revealable = this.isDeleted && this.deletedActor != null;
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line,
        if (revealable && this.isDeletedExpanded)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
            child: Text(
              "${this.deletedActor} deleted ${this.event.chatterUserName}'s message",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: revealable
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: this.onDeletedTap,
              child: body,
            )
          : body,
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
            if (this.isDeleted) ...[
              ...this._dimmedMessageSpans(context),
              TextSpan(
                text: ' —Deleted',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ] else
              ...this._messageSpans(),
          ],
        ),
      );
}

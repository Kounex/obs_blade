import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_message_display.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_visibility.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';

/// Formats [ChatMessageEvent.receivedAt] for the user-card message list
/// (Twitch-style `12:29 PM`).
String formatChatMessageTime(DateTime time) =>
    DateFormat.jm().format(time.toLocal());

/// One chat line: role badges + colored author name + message text with
/// inline emotes (first-party fragments and third-party 7TV/BTTV tokens),
/// @mentions, reply previews, and first-message / notice accent chrome.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  /// Settings box — the badge visibility toggles
  /// ([settingsKeyForBadgeSetId]) plus the third-party emote toggle
  /// ([SettingsKeys.TwitchChatThirdPartyEmotes]) and appearance keys
  /// ([NativeChatAppearance]), read with defaults.
  final Box settingsBox;

  /// Moderation tombstone — username/badges stay; the body renders its
  /// original content dimmed (Twitch mod view) with a kind-specific
  /// marker (` —Deleted` / ` —Timed out (10m)` / ` —Banned`).
  final bool isDeleted;

  /// Marker copy when [isDeleted] — defaults to ` —Deleted`.
  final String deletedMarker;

  /// Display name of the moderator who deleted this message — arrives via
  /// `channel.moderate` when the token carries the moderation scope
  /// bundle; null for pre-upgrade tokens and always for purge//clear ids.
  /// Non-null together with [isDeleted] makes the row tappable
  /// ([onDeletedTap]).
  final String? deletedActor;

  /// Whether the actor reveal line under a deleted message is expanded.
  final bool isDeletedExpanded;

  /// Tap handler for a deleted message — toggles the reveal line.
  /// Tappability is gated on [isDeleted] + [deletedActor]; a null
  /// callback with an actor yields an inert, tap-swallowing target.
  final VoidCallback? onDeletedTap;

  /// Tap handler for badges + username → user card.
  final VoidCallback? onAuthorTap;

  /// Tap handler for an `@mention` in the body → user card for that id.
  final ValueChanged<String>? onMentionTap;

  /// Long-press handler for mod actions on a live message.
  final VoidCallback? onMessageLongPress;

  /// Light gray wash while this row is the open mod-sheet target.
  /// Hold wash during the press is painted locally by the long-press
  /// listener so parent [setState] cannot dispose author/link taps.
  final bool highlighted;

  /// Left accent when this row continues a prior chat notification
  /// (same chatter).
  final Color? accentBarColor;

  /// Resolves a mention's chatter hex (`#RRGGBB`) from recent history.
  /// Broadcaster mentions always use [kChatBroadcasterMentionColor].
  final String? Function(String userId)? mentionHexFor;

  /// When embedded under a notification banner, skip outer vertical
  /// padding (the banner owns spacing).
  final bool compact;

  /// Prefix [event.receivedAt] as `12:29 PM` (user-card LIVE list).
  final bool showTimestamp;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.isDeleted = false,
    this.deletedMarker = ' —Deleted',
    this.deletedActor,
    this.isDeletedExpanded = false,
    this.onDeletedTap,
    this.onAuthorTap,
    this.onMentionTap,
    this.onMessageLongPress,
    this.highlighted = false,
    this.accentBarColor,
    this.mentionHexFor,
    this.compact = false,
    this.showTimestamp = false,
  });

  static const double _badgeSize = 18.0;

  /// GIF picker attachments render larger than emotes (Twitch shows them
  /// at roughly 3 lines of chat) and scale with the emote size setting.
  static const double _gifSizeFactor = 3.0;

  /// Soft on-surface wash — readable on dark/light chat without competing
  /// with announce / first-message chrome.
  static Color holdHighlightColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

  bool get _isFirstMessage =>
      this.event.isFirstMessage &&
      isChatFirstMessageVisible(this.settingsBox);

  /// Shared-chat origin channel name when this message was broadcast from
  /// a partner channel — never for same-channel messages (Twitch leaves
  /// the source fields null for those, and we double-guard on the id).
  String? get _sourceChannelName {
    final sourceId = this.event.sourceBroadcasterUserId;
    final sourceName = this.event.sourceBroadcasterUserName;
    if (sourceId == null ||
        sourceName == null ||
        sourceId == this.event.broadcasterUserId) {
      return null;
    }
    return sourceName;
  }

  double get _emoteSize => NativeChatAppearance.emoteSize(this.settingsBox);
  double get _textSize => NativeChatAppearance.textSize(this.settingsBox);
  double get _spacing =>
      NativeChatAppearance.messageSpacing(this.settingsBox);

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
  List<Widget> _badgeWidgets() {
    if (this.event.badges.isEmpty) return const [];
    final badgeStore = GetIt.instance<TwitchBadgeStore>();
    return [
      for (final badge in this.event.badges)
        if (this.settingsBox.get(
          settingsKeyForBadgeSetId(badge.setId).name,
          defaultValue: true,
        ))
          if (badgeStore.badgeVersion(
                  this.event.broadcasterUserId, badge.setId, badge.id)
              case final version?)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
              child: Image.network(
                version.imageUrl2x,
                height: _badgeSize,
                width: _badgeSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
    ];
  }

  List<InlineSpan> _badgeSpans() => [
        for (final widget in this._badgeWidgets())
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: widget,
          ),
      ];

  InlineSpan _authorSpan(BuildContext context) {
    final authorStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: this._authorColor(context),
    );
    if (this.onAuthorTap == null) {
      return TextSpan(
        text: this.event.chatterUserName,
        style: authorStyle,
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Pressable(
        haptic: true,
        onTap: this.onAuthorTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...this._badgeWidgets(),
            Text(this.event.chatterUserName, style: authorStyle),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _messageSpans(BuildContext context) {
    final fragments = fragmentsForChatDisplay(this.event);
    if (fragments.isEmpty) {
      /// Reply with only a suppressed `@parent` — fall back carefully:
      /// don't re-print the full wire text (it still has the @).
      if (this.event.reply != null && this.event.message.fragments.isNotEmpty) {
        return const [];
      }
      return this._linkAwareTextSpans(context, this.event.message.text);
    }

    /// Power-up messages: `power_ups_gigantified_emote` blows the emote up
    /// (same scale as GIF attachments); `power_ups_message_effect` is a
    /// cosmetic animation we can't reproduce — the content renders as a
    /// normal message, which matches the wire payload.
    final gigantified =
        this.event.messageType == 'power_ups_gigantified_emote';
    final emoteHeight =
        gigantified ? _emoteSize * _gifSizeFactor : _emoteSize;
    return [
      for (final fragment in fragments)
        if (fragment.type == 'emote' && fragment.emote != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              twitchEmoteUrl(fragment.emote!.id),
              height: emoteHeight,
              width: emoteHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(fragment.text),
            ),
          )
        else if (fragment.type == 'mention' && fragment.mention != null)
          this._mentionSpan(context, fragment)
        else if (fragment.type == 'gif' && fragment.gif != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              fragment.gif!.url,
              height: _emoteSize * _gifSizeFactor,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(fragment.text),
            ),
          )
        else
          ...this._textSpans(context, fragment.text),
    ];
  }

  InlineSpan _mentionSpan(BuildContext context, ChatMessageFragment fragment) {
    final mention = fragment.mention!;
    final style = TextStyle(
      fontWeight: FontWeight.w700,
      color: mentionColorForFragment(
            mentionUserId: mention.userId,
            broadcasterUserId: this.event.broadcasterUserId,
            chatterHex: this.mentionHexFor?.call(mention.userId),
          ) ??
          Colors.white,
    );
    if (this.onMentionTap == null) {
      return TextSpan(text: fragment.text, style: style);
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Pressable(
        haptic: true,
        onTap: () => this.onMentionTap!(mention.userId),
        child: Text(fragment.text, style: style),
      ),
    );
  }

  /// Body spans for a deleted message — the content stays (Twitch mod
  /// view) but dims hard: text recolors to half the marker's opacity and
  /// emote images get a matching [Opacity]. Structure, spacing and error
  /// builders are preserved. Assumes [_messageSpans] results are flat
  /// (plain TextSpans + emote/mention WidgetSpans).
  List<InlineSpan> _dimmedMessageSpans(BuildContext context) {
    final color = Theme.of(context)
        .textTheme
        .bodySmall
        ?.color
        ?.withValues(alpha: 0.5);
    return [
      for (final span in this._messageSpans(context))
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
  /// exactly. Unknown tokens (and the toggle-off case) stay text / links.
  List<InlineSpan> _textSpans(BuildContext context, String text) {
    if (!this.settingsBox.get(
      SettingsKeys.TwitchChatThirdPartyEmotes.name,
      defaultValue: true,
    )) {
      return this._linkAwareTextSpans(context, text);
    }
    final emoteStore = GetIt.instance<ThirdPartyEmoteStore>();
    final tokens = text.split(' ');
    return [
      for (var i = 0; i < tokens.length; i++) ...[
        if (i > 0) const TextSpan(text: ' '),
        if (emoteStore.emoteImageUrl(tokens[i],
                broadcasterId: this.event.broadcasterUserId)
            case final imageUrl?)
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
          ...this._linkAwareTextSpans(context, tokens[i]),
      ],
    ];
  }

  /// Split [text] into plain runs and tappable links (http(s) + bare domains).
  List<InlineSpan> _linkAwareTextSpans(BuildContext context, String text) {
    if (text.isEmpty) return const [];
    final matches = chatUrlMatches(text).toList();
    if (matches.isEmpty) return [TextSpan(text: text)];

    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Pressable(
            haptic: true,
            onTap: () => confirmAndOpenChatLink(context, url),
            child: Text(url, style: linkStyle),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
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
    final reply = this.event.reply;
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (this._isFirstMessage)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'FIRST MESSAGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kChatFirstMessageAccent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        if (reply != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.reply,
                  size: 12.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: AppSpacing.xs / 2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: this._textSize * 0.85,
                          ),
                      children: [
                        const TextSpan(text: 'Replying to '),
                        if (this.onMentionTap == null)
                          TextSpan(text: '@${reply.parentUserName}')
                        else
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Pressable(
                              haptic: true,
                              onTap: () =>
                                  this.onMentionTap!(reply.parentUserId),
                              child: Text(
                                '@${reply.parentUserName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: this._textSize * 0.85,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        TextSpan(text: ': ${reply.parentMessageBody}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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

    Widget chrome = body;
    if (this.accentBarColor != null || this._isFirstMessage) {
      final accent = this._isFirstMessage
          ? kChatFirstMessageAccent
          : this.accentBarColor!;
      chrome = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.0,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: body),
            if (this._isFirstMessage)
              Container(
                width: 3.0,
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      );
      if (this._isFirstMessage) {
        chrome = ColoredBox(
          color: kChatFirstMessageTint,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs / 2,
            ),
            child: chrome,
          ),
        );
      }
    }

    final padded = this.compact
        ? chrome
        : Padding(
            padding: EdgeInsets.symmetric(vertical: this._spacing),
            child: chrome,
          );

    Widget child;
    if (this.onMessageLongPress != null) {
      /// Timer-based long-press via [Listener] — no [GestureDetector]
      /// long-press in the arena (that was eating author/link taps).
      /// Hold wash is painted locally so the list parent never rebuilds
      /// mid-press (that disposed [Pressable] and killed username taps).
      child = _ModLongPressListener(
        highlighted: this.highlighted,
        onLongPress: this.onMessageLongPress!,
        child: padded,
      );
    } else if (this.highlighted) {
      child = ColoredBox(
        color: holdHighlightColor(context),
        child: padded,
      );
    } else {
      child = padded;
    }

    if (revealable) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          this.onDeletedTap!();
        },
        child: child,
      );
    }

    return child;
  }

  Text _richText(BuildContext context) => Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: this._textSize,
              ),
          children: [
            if (this.showTimestamp && this.event.receivedAt != null)
              TextSpan(
                text: '${formatChatMessageTime(this.event.receivedAt!)} ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: this._textSize * 0.9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (this._sourceChannelName case final sourceName?)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
                  child: _SourceChannelChip(
                    label: '#$sourceName',
                    color: sourceChannelColor(
                      this.event.sourceBroadcasterUserId ??
                          this.event.sourceBroadcasterUserLogin ??
                          sourceName,
                    ),
                  ),
                ),
              ),
            if (this.onAuthorTap == null) ...this._badgeSpans(),
            this._authorSpan(context),
            const TextSpan(text: ': '),
            if (this.isDeleted) ...[
              ...this._dimmedMessageSpans(context),
              TextSpan(
                text: this.deletedMarker,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ] else
              ...this._messageSpans(context),
          ],
        ),
      );
}

/// Source-channel chip for shared-chat partner messages — same visual
/// language as [NativeChatStatusChip] but without its vertical padding,
/// so it stays inside the text line height and never grows the row.
class _SourceChannelChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SourceChannelChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: this.color.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Text(
        this.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: this.color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

/// Long-press + hold-wash without a competing [GestureDetector].
///
/// Uses pointer timers only so child [Pressable] taps (author / mention /
/// links) are never delayed or cancelled by a parent long-press recognizer.
/// Wash is local [setState] on a stable [ColoredBox] — never a parent list
/// rebuild that would dispose nested tap targets mid-gesture.
class _ModLongPressListener extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final bool highlighted;

  const _ModLongPressListener({
    required this.child,
    required this.onLongPress,
    this.highlighted = false,
  });

  @override
  State<_ModLongPressListener> createState() => _ModLongPressListenerState();
}

class _ModLongPressListenerState extends State<_ModLongPressListener> {
  static const Duration _highlightDelay = Duration(milliseconds: 140);
  static const Duration _longPressDelay = Duration(milliseconds: 500);
  static const double _moveSlop = 18.0;

  Timer? _highlightTimer;
  Timer? _longPressTimer;
  int? _activePointer;
  Offset? _downPosition;
  bool _holding = false;

  @override
  void dispose() {
    this._highlightTimer?.cancel();
    this._longPressTimer?.cancel();
    super.dispose();
  }

  void _setHolding(bool value) {
    if (this._holding == value || !this.mounted) return;
    this.setState(() => this._holding = value);
  }

  void _cancelPending() {
    this._highlightTimer?.cancel();
    this._longPressTimer?.cancel();
    this._highlightTimer = null;
    this._longPressTimer = null;
    this._activePointer = null;
    this._downPosition = null;
    /// Sheet wash continues via [highlighted] after parent setState in
    /// [onLongPress] (runs before this pointer-up in the event queue).
    this._setHolding(false);
  }

  @override
  Widget build(BuildContext context) {
    final wash = this._holding || this.widget.highlighted;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (this._activePointer != null) return;
        this._activePointer = event.pointer;
        this._downPosition = event.localPosition;
        this._highlightTimer = Timer(_highlightDelay, () {
          this._setHolding(true);
        });
        this._longPressTimer = Timer(_longPressDelay, () {
          this._highlightTimer?.cancel();
          this._setHolding(true);
          HapticFeedback.mediumImpact();
          this.widget.onLongPress();
        });
      },
      onPointerMove: (event) {
        if (event.pointer != this._activePointer ||
            this._downPosition == null) {
          return;
        }
        if ((event.localPosition - this._downPosition!).distance >
            _moveSlop) {
          this._cancelPending();
        }
      },
      onPointerUp: (event) {
        if (event.pointer != this._activePointer) return;
        this._cancelPending();
      },
      onPointerCancel: (event) {
        if (event.pointer != this._activePointer) return;
        this._cancelPending();
      },
      child: ColoredBox(
        color: wash
            ? TwitchChatMessageRow.holdHighlightColor(context)
            : Colors.transparent,
        child: this.widget.child,
      ),
    );
  }
}

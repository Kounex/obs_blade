import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

/// Kick sends a per-chatter chat color in `identity.color` (`#RRGGBB`).
/// Falls back to the plain body color (what the Twitch row does for
/// uncolored names) when absent or malformed.
Color kickAuthorColor(BuildContext context, String? colorHex) {
  final hex = colorHex;
  if (hex != null) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value != null) return Color(0xFF000000 | value);
  }
  return Theme.of(context).textTheme.bodyMedium?.color ??
      (Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard)
          .textOrnament;
}

/// One native Kick chat line, mirroring [TwitchChatMessageRow]'s visual
/// idiom but bound to [KickChatMessage]: v2 badge artwork chips before the
/// name (legacy text-chip fallback), name in `identity.color`, link-aware
/// body with `[emote:id:name]` tokens rendered inline, reply context line
/// and the dimmed ` —Deleted` tombstone treatment. `system` rows (the
/// `/clear` notice) render as a muted system line.
class KickChatMessageRow extends StatelessWidget {
  final KickChatMessage message;

  /// Settings box — appearance keys ([NativeChatAppearance]), read with
  /// defaults.
  final Box settingsBox;

  /// Long-press handler for reply/mod actions on a live message
  /// (signed-in only — gated by the caller).
  final VoidCallback? onMessageLongPress;

  /// Tap handler for badges + username → user card. The caller gates
  /// this on `message.authorId != null` (system rows have no sender).
  final VoidCallback? onAuthorTap;

  /// Light gray wash while this row is the open mod-sheet target.
  final bool highlighted;

  const KickChatMessageRow({
    super.key,
    required this.message,
    required this.settingsBox,
    this.onMessageLongPress,
    this.onAuthorTap,
    this.highlighted = false,
  });

  double get _textSize => NativeChatAppearance.textSize(this.settingsBox);
  double get _emoteSize => NativeChatAppearance.emoteSize(this.settingsBox);
  double get _spacing => NativeChatAppearance.messageSpacing(this.settingsBox);

  /// Badge artwork size — matches the Twitch row's badge artwork.
  static const double _badgeSize = 16.0;

  List<Widget> _badgeWidgets() {
    final identity = this.message.sender?.identity;
    if (identity == null) return const [];
    final v2 = identity.displayBadges;
    if (v2.isNotEmpty) {
      return [
        for (final badge in v2)
          Padding(
            key: Key('kick-badge-${badge.name ?? badge.badgeType}'),
            padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
            child: Image.network(
              badge.imageUrl!,
              height: _badgeSize,
              width: _badgeSize,
              fit: BoxFit.contain,
              frameBuilder: chatImageFadeIn,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
      ];
    }

    /// Legacy badges carry no artwork — small neutral text chips (same
    /// contained idiom as the header Mod chip), only as a fallback.
    return [
      for (final badge in identity.badges)
        if (badge.text != null && badge.text!.isNotEmpty)
          Padding(
            key: Key('kick-badge-legacy-${badge.type}'),
            padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
            child: NativeChatStatusChip(
              label: badge.count != null && badge.count! > 0
                  ? '${badge.text} (${badge.count})'
                  : badge.text!,
            ),
          ),
    ];
  }

  List<InlineSpan> _badgeSpans() => [
    for (final widget in this._badgeWidgets())
      WidgetSpan(alignment: PlaceholderAlignment.middle, child: widget),
  ];

  InlineSpan _authorSpan(BuildContext context) {
    final authorStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: kickAuthorColor(context, this.message.sender?.identity?.color),
    );
    if (this.onAuthorTap == null) {
      return TextSpan(text: this.message.authorName, style: authorStyle);
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
            Text(this.message.authorName, style: authorStyle),
          ],
        ),
      ),
    );
  }

  /// Content with emote tokens swapped to inline images at the app's
  /// emote sizing (same rendering contract as the Twitch row).
  List<InlineSpan> _messageSpans(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final fragment in parseKickChatContent(this.message.content)) {
      if (fragment.isEmote) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              kickEmoteUrl(fragment.emoteId!),
              height: this._emoteSize,
              width: this._emoteSize,
              fit: BoxFit.contain,
              frameBuilder: chatImageFadeIn,
              errorBuilder: (_, _, _) => Text('[${fragment.emoteName}]'),
            ),
          ),
        );
      } else {
        spans.addAll(chatLinkTextSpans(context, fragment.text));
      }
    }
    return spans;
  }

  /// Tombstone treatment — the content stays visible but dims (same UX
  /// as the Twitch row), with the italic marker appended.
  List<InlineSpan> _dimmedMessageSpans(BuildContext context) =>
      dimmedChatContentSpans(context, this._messageSpans(context));

  TextSpan _deletedMarkerSpan(BuildContext context) => TextSpan(
    text: ' —Deleted',
    style: TextStyle(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).textTheme.bodySmall?.color,
    ),
  );

  /// Reply context line above the message (`type: reply`) —
  /// `@original_sender: original_message`, muted, one line.
  Widget? _replyHeader(BuildContext context) {
    if (this.message.type != KickChatMessageType.reply) return null;
    final metadata = this.message.metadata;
    final senderName = metadata?.originalSenderName;
    if (senderName == null || senderName.isEmpty) return null;
    final content = metadata?.originalMessageContent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs / 2),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
                child: Icon(
                  CupertinoIcons.arrowshape_turn_up_left_fill,
                  size: 12.0,
                  color:
                      (Theme.of(context).extension<AppTextColors>() ??
                              AppTextColors.standard)
                          .textTertiary,
                ),
              ),
            ),
            TextSpan(
              text:
                  '@$senderName${content != null && content.isNotEmpty ? ': $content' : ''}',
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// A synthetic notice line — `/clear` plus the sub/gift/host notices
  /// the store appends (see `_appendNotice` there). Icon is picked from
  /// the message id's `system-<kind>-…` prefix; text is the message's
  /// own [KickChatMessage.content] (falls back to the `/clear` copy for
  /// any older/unrecognized synthetic row with no content set).
  Widget _systemRow(BuildContext context) {
    final accent =
        (Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard)
            .textOrnament;
    final id = this.message.id;
    final icon = id.startsWith('system-sub-')
        ? CupertinoIcons.star_fill
        : id.startsWith('system-gift-')
        ? CupertinoIcons.gift_fill
        : id.startsWith('system-host-')
        ? CupertinoIcons.person_2_fill
        : JamIcons.shield_f;
    final text = this.message.content.isNotEmpty
        ? this.message.content
        : 'Chat was cleared by a moderator';
    return Row(
      children: [
        Icon(icon, size: 14.0, color: accent),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: this._textSize),
          ),
        ),
      ],
    );
  }

  /// The plain chat line: badges + colored author + body.
  Widget _textRow(BuildContext context) {
    final Widget row = Text.rich(
      TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: this._textSize),
        children: [
          if (this.onAuthorTap == null) ...this._badgeSpans(),
          this._authorSpan(context),
          const TextSpan(text: ': '),
          if (this.message.isTombstoned) ...[
            ...this._dimmedMessageSpans(context),
            this._deletedMarkerSpan(context),
          ] else
            ...this._messageSpans(context),
        ],
      ),
    );
    return this.message.isTombstoned ? ChatTombstoneFade(child: row) : row;
  }

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: EdgeInsets.symmetric(vertical: this._spacing),
      child: this.message.type == KickChatMessageType.system
          ? this._systemRow(context)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [?this._replyHeader(context), this._textRow(context)],
            ),
    );

    if (this.onMessageLongPress != null && !this.message.isTombstoned) {
      return ChatRowLongPressListener(
        highlighted: this.highlighted,
        onLongPress: this.onMessageLongPress!,
        child: padded,
      );
    }
    if (this.highlighted) {
      return ColoredBox(
        color: TwitchChatMessageRow.holdHighlightColor(context),
        child: padded,
      );
    }
    return padded;
  }
}

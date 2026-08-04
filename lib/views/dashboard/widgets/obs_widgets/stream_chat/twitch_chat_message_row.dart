import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

/// One chat line: colored author name + message text with inline emotes.
/// Cheermote/mention fragments fall back to plain text in Phase 1.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  const TwitchChatMessageRow({super.key, required this.event});

  static const double _emoteSize = 20.0;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
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
      ),
    );
  }
}

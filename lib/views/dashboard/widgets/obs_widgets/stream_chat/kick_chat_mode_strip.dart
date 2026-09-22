import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/kick_chat.dart';

/// Passive, read-only line docked above the native Kick chat input
/// listing whichever of Kick's chat modes (`chatroom.{slowMode,
/// followersMode,subscribersMode,emotesMode}`) are currently active.
/// Kick's public API has no viewer-facing "chat modes" surface and no
/// write endpoint for them either (mod-only, changed from Kick's own
/// dashboard) — this is informational only, same ceiling documented in
/// `docs/kick-chat-audit.md`. Renders nothing when no mode is active or
/// the channel info hasn't resolved yet.
class KickChatModeStrip extends StatelessWidget {
  /// Brand accent — the icon.
  final Color accentColor;

  const KickChatModeStrip({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<KickChatStore>();
    return Observer(
      builder: (context) {
        final chatroom = store.channelInfo?.chatroom;
        if (chatroom == null) return const SizedBox.shrink();
        final active = <String>[
          if (chatroom.slowMode) 'Slow mode',
          if (chatroom.followersMode) 'Followers-only',
          if (chatroom.subscribersMode) 'Subscribers-only',
          if (chatroom.emotesMode) 'Emote-only',
        ];
        if (active.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 12.0,
                color: this.accentColor,
              ),
              const SizedBox(width: AppSpacing.xs / 2),
              Expanded(
                child: Text(
                  active.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

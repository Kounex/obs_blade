import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../types/classes/twitch/twitch_pinned_message.dart';
import '../../../../../utils/styling_helper.dart';

/// Slim banner above the native Twitch chat timeline showing the channel's
/// currently pinned message (Helix pins — at most one per channel). The
/// store refetches on connect/switch and after local pin mutations (there
/// is no EventSub for pins).
///
/// The ✕ unpin affordance only renders for users who may moderate the
/// selected channel; failures surface as a snackbar hosted by the chat
/// view's context.
class PinnedChatBanner extends StatelessWidget {
  final TwitchPinnedMessage pinned;

  const PinnedChatBanner({super.key, required this.pinned});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<TwitchChatStore>();
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        0.0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.pin_fill,
            size: 14.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${this.pinned.senderUserName}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: this.pinned.message.text),
                ],
              ),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (store.canModerateSelectedChannel) ...[
            const SizedBox(width: AppSpacing.sm),
            Pressable(
              haptic: true,
              onTap: () async {
                final ok = await store.unpinMessage();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Could not unpin the message'),
                      ),
                    );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 14.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

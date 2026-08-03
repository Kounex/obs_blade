import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/styling_helper.dart';

/// Chat-line chrome closer to the stream chat empty/list language —
/// avatar chip + username + message bar (no WebView).
class ChatPreview extends StatelessWidget {
  const ChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color chip =
        StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 12);

    Widget line({
      required String user,
      required String message,
      required Color accent,
    }) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18.0,
                height: 18.0,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: '$user ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      TextSpan(text: message),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    final Color secondary = Theme.of(context).colorScheme.secondary;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: chip,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            line(
              user: 'viewer_one',
              message: 'Looking great tonight!',
              accent: secondary,
            ),
            line(
              user: 'mod_bot',
              message: 'Welcome to the stream.',
              accent: Theme.of(context).extension<AppStatusColors>()!.live,
            ),
            line(
              user: 'chat_fan',
              message: 'That scene switch was clean.',
              accent: Colors.lightBlueAccent,
            ),
          ],
        ),
      ),
    );
  }
}

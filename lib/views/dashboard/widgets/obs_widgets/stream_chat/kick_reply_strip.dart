import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/kick_chat.dart';

/// "Replying to @user: excerpt …" strip docked above the native Kick
/// chat input while a reply target is set ([KickChatStore.replyTarget]).
/// Renders nothing when no target is pending; ✕ cancels. Mirrors
/// [NativeReplyStrip] (Twitch) bound to the Kick store.
class KickReplyStrip extends StatelessWidget {
  /// Brand accent — the reply icon.
  final Color accentColor;

  const KickReplyStrip({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<KickChatStore>();
    return Observer(
      builder: (context) {
        final target = store.replyTarget;
        if (target == null) return const SizedBox.shrink();
        return Row(
          children: [
            Icon(CupertinoIcons.reply, size: 12.0, color: this.accentColor),
            const SizedBox(width: AppSpacing.xs / 2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'Replying to '),
                    TextSpan(
                      text: '@${target.authorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            (Theme.of(context).extension<AppTextColors>() ??
                                    AppTextColors.standard)
                                .highlightText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ': ${target.content}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Pressable(
              haptic: true,
              onTap: store.clearReplyTarget,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: kMinInteractiveDimensionCupertino,
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 14.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

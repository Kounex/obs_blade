import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../stores/pro_store.dart';
import 'activity_feed.dart';
import 'activity_formatting.dart';
import 'activity_sheets.dart';

/// Lets a host that shows the feed itself (the Chat tab) take over the
/// chat header button: [show] switches to the feed instead of opening a
/// sheet, and [feedVisible] hides the button while the feed is on screen
/// next to the chat.
class ActivityHostScope extends InheritedWidget {
  final VoidCallback show;
  final bool feedVisible;

  const ActivityHostScope({
    super.key,
    required this.show,
    required this.feedVisible,
    required super.child,
  });

  static ActivityHostScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivityHostScope>();

  @override
  bool updateShouldNotify(ActivityHostScope oldWidget) =>
      oldWidget.feedVisible != this.feedVisible || oldWidget.show != this.show;
}

/// Opens the feed the way the current host wants it.
void openActivity(BuildContext context) {
  final host = ActivityHostScope.maybeOf(context);
  if (host != null) {
    host.show();
  } else {
    showActivitySheet(context);
  }
}

/// Bell in the native chat header with the unseen count. Pro only (the
/// feed runs on the native engines); hidden while the feed is already on
/// screen beside the chat.
class ChatActivityButton extends StatelessWidget {
  const ChatActivityButton({super.key});

  @override
  Widget build(BuildContext context) {
    final store = activityStoreOrNull();
    final host = ActivityHostScope.maybeOf(context);
    if (store == null ||
        !GetIt.instance.isRegistered<ProStore>() ||
        (host?.feedVisible ?? false)) {
      return const SizedBox.shrink();
    }
    return Observer(
      builder: (context) {
        if (!GetIt.instance<ProStore>().isPro) return const SizedBox.shrink();
        final unseen = store.unseenCount;
        final Color accent = Theme.of(context).colorScheme.secondary;
        return Semantics(
          button: true,
          label: unseen == 0 ? 'Activity' : 'Activity, $unseen new',
          excludeSemantics: true,
          child: Pressable(
            haptic: true,
            springy: false,
            onTap: () => openActivity(context),
            child: SizedBox(
              key: const Key('chat-activity-button'),
              width: kMinInteractiveDimensionCupertino,
              height: kMinInteractiveDimensionCupertino,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    unseen > 0 ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
                    size: 20.0,
                    color: unseen > 0
                        ? accent
                        : Theme.of(context).disabledColor,
                  ),
                  if (unseen > 0)
                    Positioned(
                      top: 6.0,
                      right: 4.0,
                      child: ActivityCountBadge(count: unseen),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small accent pill with a count (1..99+).
class ActivityCountBadge extends StatelessWidget {
  final int count;

  const ActivityCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 16.0, minHeight: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        activityBadgeText(this.count),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondary,
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

/// "3 new" over the streaming-mode preview - opens the feed sheet. Gone
/// at zero and without Pro.
class ActivityNewChip extends StatelessWidget {
  const ActivityNewChip({super.key});

  @override
  Widget build(BuildContext context) {
    final store = activityStoreOrNull();
    if (store == null || !GetIt.instance.isRegistered<ProStore>()) {
      return const SizedBox.shrink();
    }
    return Observer(
      builder: (context) {
        final unseen = GetIt.instance<ProStore>().isPro ? store.unseenCount : 0;
        return AnimatedSwitcher(
          duration: AppMotion.medium,
          child: unseen == 0
              ? const SizedBox.shrink(key: ValueKey('none'))
              : Semantics(
                  key: const ValueKey('chip'),
                  button: true,
                  label: '$unseen new in activity',
                  excludeSemantics: true,
                  child: Pressable(
                    haptic: true,
                    springy: false,
                    onTap: () => showActivitySheet(context),
                    child: Container(
                      key: const Key('activity-new-chip'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.bell_fill,
                            size: 14.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${activityBadgeText(unseen)} new',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

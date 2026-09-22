import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'kick_chat_message_row.dart';
import 'native_chat_appearance.dart';
import 'native_chat_chrome.dart';

/// Native Kick chat timeline, driven by [KickChatStore]'s message buffer
/// (anonymous reads — channel resolution + history backfill over REST,
/// live events over Kick's public Pusher socket). Mirrors
/// [NativeYouTubeChatView]'s scroll/pin logic and pause chip; no mod
/// long-press — reads are anonymous this wave, so there are no mod
/// actions to gate.
class NativeKickChatView extends StatefulWidget {
  const NativeKickChatView({super.key});

  @override
  State<NativeKickChatView> createState() => _NativeKickChatViewState();
}

class _NativeKickChatViewState extends State<NativeKickChatView> {
  final ScrollController _scrollController = ScrollController();

  /// Pinned to the newest message until the user scrolls up
  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _lastRenderedCount = 0;

  KickChatStore get _store => GetIt.instance<KickChatStore>();

  @override
  void initState() {
    super.initState();
    this._scrollController.addListener(this._onScroll);
  }

  void _onScroll() {
    if (!this._scrollController.hasClients) return;
    final position = this._scrollController.position;
    if (!position.hasContentDimensions) return;
    final atBottom = position.pixels >= position.maxScrollExtent - 24.0;
    if (atBottom && !this._pinnedToBottom) {
      setState(() {
        this._pinnedToBottom = true;
        this._unreadWhileScrolledUp = false;
      });
    } else if (!atBottom && this._pinnedToBottom) {
      setState(() => this._pinnedToBottom = false);
    }
  }

  /// Instant pin to the newest message. Prefer [jumpTo] over [animateTo]
  /// so we never race a post-frame stick-to-bottom jump.
  void _jumpToBottomIfPossible() {
    if (!this.mounted || !this._scrollController.hasClients) return;
    final position = this._scrollController.position;
    if (!position.hasContentDimensions) return;
    final target = position.maxScrollExtent;
    if ((position.pixels - target).abs() < 0.5) return;
    position.jumpTo(target);
  }

  void _resumePinnedToBottom() {
    setState(() {
      this._pinnedToBottom = true;
      this._unreadWhileScrolledUp = false;
    });
    this._jumpToBottomIfPossible();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      this._jumpToBottomIfPossible();
    });
  }

  @override
  void dispose() {
    this._scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final connection = this._store.chatConnection;

        /// Reading the observable list tracks it — tombstones mutate
        /// entries in place, so also read the length for the pin logic.
        final items = this._store.messages.toList();
        final timelineEmpty = items.isEmpty;

        if ((connection == KickChatConnectionState.connecting ||
                connection == KickChatConnectionState.reconnecting) &&
            timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Connecting to Kick chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == KickChatConnectionState.error && timelineEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ?? 'Could not connect to Kick chat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Pressable(
                  haptic: true,
                  onTap: () => this._store.connectChat(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (timelineEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                /// `offline` = the slug does not resolve — a normal state,
                /// not an error.
                connection == KickChatConnectionState.offline
                    ? 'No chat for this channel — the slug may be wrong or the channel is unavailable.'
                    : 'Connected — waiting for messages…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        /// Stick to bottom only when the timeline length changes while
        /// pinned — tombstones don't change the count (no jump / unread).
        final countChanged = items.length != this._lastRenderedCount;
        if (this._pinnedToBottom) {
          this._unreadWhileScrolledUp = false;
          if (countChanged) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              this._jumpToBottomIfPossible();
            });
          }
        } else if (countChanged) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() => this._unreadWhileScrolledUp = true);
            }
          });
        }
        this._lastRenderedCount = items.length;

        /// Appearance toggles re-render in place (shared keys with the
        /// Twitch engine — the appearance options sheet is reused as-is).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatTextSize,
            SettingsKeys.TwitchChatMessageSpacing,
            SettingsKeys.TwitchChatMessageSeparators,
          ],
          builder: (context, settingsBox, child) {
            final separators = NativeChatAppearance.separators(settingsBox);
            return Stack(
              children: [
                ListView.separated(
                  controller: this._scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => separators
                      ? Divider(
                          height: 1.0,
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                        )
                      : const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final message = items[index];
                    return KickChatMessageRow(
                      key: ValueKey(message.id),
                      message: message,
                      settingsBox: settingsBox,
                    );
                  },
                ),
                if (!this._pinnedToBottom)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: Center(
                      child: Pressable(
                        haptic: true,
                        onTap: this._resumePinnedToBottom,
                        child: Container(
                          /// Invisible 44pt hit expansion — the chip's
                          /// visual bottom edge stays put
                          constraints: const BoxConstraints(
                            minWidth: kMinInteractiveDimensionCupertino,
                            minHeight: kMinInteractiveDimensionCupertino,
                          ),
                          alignment: Alignment.bottomCenter,
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            transitionBuilder: (child, animation) =>
                                nativeChatSwapTransition(
                                  context,
                                  child,
                                  animation,
                                ),
                            child: Container(
                              key: ValueKey(this._unreadWhileScrolledUp),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: this._unreadWhileScrolledUp
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : StylingHelper.lightenDarkenColor(
                                        Theme.of(context).cardColor,
                                      ),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                this._unreadWhileScrolledUp
                                    ? 'New messages ↓'
                                    : 'Paused ↓',
                                style: this._unreadWhileScrolledUp
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            (Theme.of(context)
                                                        .extension<
                                                          AppTextColors
                                                        >() ??
                                                    AppTextColors.standard)
                                                .highlightText,
                                      )
                                    : Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

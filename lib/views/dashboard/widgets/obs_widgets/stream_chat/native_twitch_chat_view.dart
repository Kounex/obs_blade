import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'twitch_chat_message_row.dart';

/// Native read-only Twitch chat. Lives in the same dashboard slot the
/// WebView chat uses — driven by [TwitchChatStore]'s message buffer.
class NativeTwitchChatView extends StatefulWidget {
  const NativeTwitchChatView({super.key});

  @override
  State<NativeTwitchChatView> createState() => _NativeTwitchChatViewState();
}

class _NativeTwitchChatViewState extends State<NativeTwitchChatView> {
  final ScrollController _scrollController = ScrollController();

  /// Pinned to the newest message until the user scrolls up
  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _lastRenderedCount = 0;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  @override
  void initState() {
    super.initState();
    this._scrollController.addListener(this._onScroll);
  }

  void _onScroll() {
    if (!this._scrollController.hasClients) return;
    final atBottom = this._scrollController.position.pixels >=
        this._scrollController.position.maxScrollExtent - 24.0;
    if (atBottom && !this._pinnedToBottom) {
      setState(() {
        this._pinnedToBottom = true;
        this._unreadWhileScrolledUp = false;
      });
    } else if (!atBottom && this._pinnedToBottom) {
      setState(() => this._pinnedToBottom = false);
    }
  }

  void _scrollToBottom() {
    if (!this._scrollController.hasClients) return;
    this._scrollController.animateTo(
      this._scrollController.position.maxScrollExtent,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
    );
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
        final messageCount = this._store.messages.length;

        /// Tracked so the visible list rebuilds once when third-party
        /// emote catalogs land (pop-in) — rows resolve tokens
        /// non-reactively at build time, so this read is the only
        /// rebuild trigger.
        // ignore: unused_local_variable
        final emoteCatalogVersion =
            GetIt.instance<ThirdPartyEmoteStore>().catalogVersion;

        /// Tracked so lifecycle changes (tombstones, /clear banner)
        /// rebuild the list — the merge/membership reads below are
        /// non-reactive plain data, so this version read is their only
        /// rebuild trigger (same pattern as the emote pop-in above).
        // ignore: unused_local_variable
        final lifecycleVersion = this._store.lifecycleVersion;

        if (connection == TwitchChatConnectionState.connecting &&
            messageCount == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Connecting to Twitch chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == TwitchChatConnectionState.failed &&
            messageCount == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ?? 'Could not connect to Twitch chat',
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (messageCount == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Connected — waiting for messages…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        final items = this._store.messagesWithNotices();

        /// New-frame bookkeeping: jump to the newest message while pinned,
        /// flag the unread pill otherwise (post-frame — not during build).
        /// Tombstones don't change the count (no unread flag); a /clear
        /// banner does (it counts as new activity).
        if (this._pinnedToBottom) {
          this._unreadWhileScrolledUp = false;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this._scrollController.hasClients) {
              this._scrollController.jumpTo(
                  this._scrollController.position.maxScrollExtent);
            }
          });
        } else if (items.length != this._lastRenderedCount) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() => this._unreadWhileScrolledUp = true);
            }
          });
        }
        this._lastRenderedCount = items.length;

        /// Toggle changes re-filter badges and re-render emote tokens in
        /// place; row-level Observers pick up badge catalog arrivals
        /// (emote catalog arrivals ride the outer Observer's
        /// catalogVersion read above).
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatBadgeBroadcaster,
            SettingsKeys.TwitchChatBadgeModerator,
            SettingsKeys.TwitchChatBadgeVip,
            SettingsKeys.TwitchChatBadgeSubscriber,
            SettingsKeys.TwitchChatBadgeFounder,
            SettingsKeys.TwitchChatBadgeBits,
            SettingsKeys.TwitchChatBadgeOther,
            SettingsKeys.TwitchChatThirdPartyEmotes,
          ],
          builder: (context, settingsBox, child) => Stack(
            children: [
              ListView.builder(
                controller: this._scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is ChatSystemNotice) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'Chat was cleared by a moderator',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    );
                  }
                  final event = item as ChatMessageEvent;
                  return TwitchChatMessageRow(
                    event: event,
                    settingsBox: settingsBox,
                    isDeleted: this._store.isMessageDeleted(event.messageId),
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
                      onTap: () {
                        setState(() {
                          this._pinnedToBottom = true;
                          this._unreadWhileScrolledUp = false;
                        });
                        this._scrollToBottom();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: this._unreadWhileScrolledUp
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          this._unreadWhileScrolledUp
                              ? 'New messages ↓'
                              : 'Paused ↓',
                          style: this._unreadWhileScrolledUp
                              ? Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white)
                              : Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

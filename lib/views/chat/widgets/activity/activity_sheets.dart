import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../models/enums/chat_type.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/base/adaptive_switch.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../stores/views/activity.dart';
import '../../../../stores/views/kick_chat.dart';
import '../../../../types/classes/activity/activity_event.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/kick/kick_events_relay_client.dart';
import '../../../../utils/modal_handler.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/chat_type_brand.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_chrome.dart';
import '../../../dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
import 'activity_feed.dart';
import 'activity_formatting.dart';

/// The whole feed in a sheet (streaming mode, the chat header button
/// outside the Chat tab).
Future<void> showActivitySheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.9,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: nativeChatSheetDragHandle(context),
            ),
            const Expanded(child: ActivityFeed(inSheet: true)),
          ],
        ),
      ),
    );

/// Everything one person did on one platform, newest first.
Future<void> showActivityPersonSheet(
  BuildContext context,
  ActivityEvent event,
) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) => _PersonSheet(event: event),
);

class _PersonSheet extends StatelessWidget {
  final ActivityEvent event;

  const _PersonSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final store = activityStoreOrNull();
    if (store == null) return const SizedBox.shrink();
    final chatType = chatTypeOf(this.event.platform);
    return Observer(
      builder: (context) {
        final history = this.event.actor.anonymous
            ? [
                store.allEvents.firstWhere(
                  (e) => e.id == this.event.id,
                  orElse: () => this.event,
                ),
              ]
            : store.historyOf(this.event);
        final totals = formatActivityTotals(ActivityTotals.of(history));
        final open = history.where((e) => e.isBig && !e.thanked).toList();
        final now = DateTime.now();
        return NativeChatSheetScaffold(
          header: Row(
            children: [
              Icon(
                chatType.icon,
                size: 18.0,
                color:
                    chatType.brandColor ??
                    Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  activityActorName(this.event),
                  overflow: TextOverflow.ellipsis,
                  style: nativeChatSheetTitleStyle(context),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (totals != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    totals,
                    key: const Key('activity-person-totals'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (open.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ChannelModActionRow(
                    key: const Key('activity-person-thank-all'),
                    icon: CupertinoIcons.checkmark_circle,
                    label: open.length == 1
                        ? 'Mark thanked'
                        : 'Mark all ${open.length} thanked',
                    onTap: () {
                      for (final item in open) {
                        store.setThanked(item, true);
                      }
                    },
                  ),
                ),
              ChannelModSectionHeader(
                history.length == 1 ? '1 event' : '${history.length} events',
              ),
              for (final item in history)
                ActivityRow(
                  key: ValueKey('person-${item.id}'),
                  event: item,
                  isNew: false,
                  now: now,
                  compact: true,
                  onThanked: (thanked) => store.setThanked(item, thanked),
                  onTap: () => store.setThanked(item, !item.thanked),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Feed options: mark all seen, the Kick relay switch, clear history.
Future<void> showActivityOptionsSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (context) => const _OptionsSheet(),
    );

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context) {
    final store = activityStoreOrNull();
    if (store == null) return const SizedBox.shrink();
    final getIt = GetIt.instance;
    final kickSignedIn =
        getIt.isRegistered<KickChatStore>() &&
        getIt.checkLazySingletonInstanceExists<KickChatStore>() &&
        getIt<KickChatStore>().ownChannelSlug != null;
    return NativeChatSheetScaffold(
      header: Text('Activity', style: nativeChatSheetTitleStyle(context)),
      body: Observer(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChannelModActionRow(
              key: const Key('activity-mark-all-seen'),
              icon: CupertinoIcons.eye,
              label: 'Mark all as seen',
              onTap: store.unseenCount == 0
                  ? null
                  : () {
                      store.markAllSeen();
                      Navigator.of(context).pop();
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            const ChannelModSectionHeader('Kick'),
            ChannelModActionRow(
              key: const Key('activity-kick-relay'),
              icon: CupertinoIcons.cloud,
              label: 'Follows, KICKs and subs',
              onTap: () async {
                final box = Hive.box(HiveKeys.Settings.name);
                await box.put(
                  SettingsKeys.ActivityKickRelay.name,
                  !(box.get(
                        SettingsKeys.ActivityKickRelay.name,
                        defaultValue: true,
                      )
                      as bool),
                );
                store.relaySettingChanged();
              },
              trailing: HiveBuilder<dynamic>(
                hiveKey: HiveKeys.Settings,
                rebuildKeys: const [SettingsKeys.ActivityKickRelay],
                builder: (context, box, _) => BaseAdaptiveSwitch(
                  value: box.get(
                    SettingsKeys.ActivityKickRelay.name,
                    defaultValue: true,
                  ),
                  onChanged: (value) async {
                    await box.put(SettingsKeys.ActivityKickRelay.name, value);
                    store.relaySettingChanged();
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Kick sends these only to a server, so they go through OBS '
                'Blade\'s relay: it checks which channel is yours with your '
                'Kick sign-in and keeps the events for 7 days, also while '
                'the app is closed. Turning this off or signing out of Kick '
                'deletes them there.${kickSignedIn ? '' : ' Sign in to Kick in the chat to use it.'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (kickSignedIn && store.relayState != KickRelayState.off)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  switch (store.relayState) {
                    KickRelayState.synced when !store.relaySubscribed =>
                      'Connected · Kick hasn\'t accepted every event yet, '
                          'retrying',
                    KickRelayState.synced => 'Connected',
                    KickRelayState.retrying => 'Reconnecting…',
                    _ => 'Connecting…',
                  },
                  key: const Key('activity-kick-relay-state'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const ChannelModSectionHeader('History'),
            ChannelModActionRow(
              key: const Key('activity-clear'),
              icon: CupertinoIcons.trash,
              label: 'Clear activity history',
              destructive: true,
              onTap: store.allEvents.isEmpty
                  ? null
                  : () => ModalHandler.showBaseDialog(
                      context: context,
                      barrierDismissible: true,
                      dialogWidget: ConfirmationDialog(
                        title: 'Clear activity history?',
                        body:
                            'Every follow, sub and gift in the feed is '
                            'removed from this device. This can\'t be undone.',
                        isYesDestructive: true,
                        okText: 'Clear',
                        noText: 'Cancel',
                        onOk: (_) async {
                          await store.clearHistory();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'The feed keeps 30 days on this device.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

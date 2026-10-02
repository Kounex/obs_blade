import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../shared/design/design.dart';
import '../../shared/general/base/constrained_box.dart';
import '../../shared/general/responsive_widget_wrapper.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../stores/pro_store.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/routing_helper.dart';
import '../dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'widgets/activity/activity_entry_points.dart';
import 'widgets/activity/activity_feed.dart';

/// Chat tab root: the standalone home for stream chat - usable with or
/// without an OBS session (chat state lives in the global settings box and
/// the GetIt chat stores; the stores connect on login restore / channel
/// select regardless of any surface). The regular dashboard carries no chat
/// pane; the streaming-mode cockpit embeds chat as its live co-display
/// surface.
///
/// Chat | Activity: a segment on phones; on tablets (Pro) both side by
/// side.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        title: 'Chat',
        customBody: Padding(
          padding: EdgeInsets.only(
            /// Breathing room between the nav bar and the chat chrome
            top: AppSpacing.lg,

            /// Full available height, resting the standard gap above the
            /// glass tab bar
            bottom: tabBarBottomPadding(context),
          ),
          child: ResponsiveWidgetWrapper(
            mobileWidget: const Center(
              child: BaseConstrainedBox(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ChatTabSegments(),
              ),
            ),
            tabletWidget: Observer(
              builder: (context) => GetIt.instance<ProStore>().isPro
                  ? const Center(
                      child: BaseConstrainedBox(
                        maxWidth: kWideContentMaxWidth,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: ChatTabSideBySide(),
                      ),
                    )
                  : const Center(
                      child: BaseConstrainedBox(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: ChatTabSegments(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

const String kChatTabSegmentChat = 'chat';
const String kChatTabSegmentActivity = 'activity';

/// Phone: Chat | Activity. The chat stays mounted (offstage) while the
/// feed shows, so a WebView or a native session never reloads on a
/// switch; the feed is built only while selected (its visit marks what
/// it showed as seen).
class ChatTabSegments extends StatefulWidget {
  const ChatTabSegments({super.key});

  @override
  State<ChatTabSegments> createState() => _ChatTabSegmentsState();
}

class _ChatTabSegmentsState extends State<ChatTabSegments> {
  late String _segment;

  @override
  void initState() {
    super.initState();
    final stored = Hive.box(
      HiveKeys.Settings.name,
    ).get(SettingsKeys.ActivityChatTabSegment.name);
    this._segment = stored == kChatTabSegmentActivity
        ? kChatTabSegmentActivity
        : kChatTabSegmentChat;
  }

  void _select(String segment) {
    if (segment == this._segment) return;
    setState(() => this._segment = segment);
    Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.ActivityChatTabSegment.name, segment);
  }

  @override
  Widget build(BuildContext context) {
    final bool activity = this._segment == kChatTabSegmentActivity;
    return ActivityHostScope(
      show: () => this._select(kChatTabSegmentActivity),
      feedVisible: activity,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<String>(
              key: const Key('chat-tab-segments'),
              groupValue: this._segment,
              children: {
                kChatTabSegmentChat: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text('Chat'),
                ),
                kChatTabSegmentActivity: const _ActivitySegmentLabel(),
              },
              onValueChanged: (next) {
                if (next != null) this._select(next);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: activity,
                  child: TickerMode(
                    enabled: !activity,
                    child: StreamChat(proRoute: ChatTabRoutingKeys.Pro.route),
                  ),
                ),
                if (activity)
                  ActivityFeed(
                    proRoute: ChatTabRoutingKeys.Pro.route,
                    hostTab: Tabs.Chat,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySegmentLabel extends StatelessWidget {
  const _ActivitySegmentLabel();

  @override
  Widget build(BuildContext context) {
    final store = activityStoreOrNull();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Activity'),
          if (store != null)
            Observer(
              builder: (context) {
                final unseen = GetIt.instance<ProStore>().isPro
                    ? store.unseenCount
                    : 0;
                return unseen == 0
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: ActivityCountBadge(
                          key: const Key('chat-tab-activity-badge'),
                          count: unseen,
                        ),
                      );
              },
            ),
        ],
      ),
    );
  }
}

/// Tablet (Pro): chat and the feed next to each other - the chat header
/// drops its activity button, the feed is already there.
class ChatTabSideBySide extends StatelessWidget {
  const ChatTabSideBySide({super.key});

  @override
  Widget build(BuildContext context) {
    return ActivityHostScope(
      show: () {},
      feedVisible: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: StreamChat(proRoute: ChatTabRoutingKeys.Pro.route),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ActivityFeed(
              proRoute: ChatTabRoutingKeys.Pro.route,
              hostTab: Tabs.Chat,
            ),
          ),
        ],
      ),
    );
  }
}

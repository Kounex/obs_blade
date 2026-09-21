import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/icon_button.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/shared/general/responsive_widget_wrapper.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/resizeable_scene_preview.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_buttons.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/stream_health_pill.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

/// Streaming-mode dashboard - the "you're live" cockpit: drag-resizable
/// scene preview, scene buttons, and the stream chat. Chrome is on-demand
/// so the video and chat own the space: the stream-health stats float over
/// the preview as a pill (chart toggle), and the chat header (platform /
/// channel / engine / account) floats over the chat as a card (tune
/// toggle). Both toggle states persist in the settings box; the tune
/// toggle is draggable along the chat's right edge (clamped clear of the
/// window header and the input-dock / pause-chip zone, persisted as a
/// height fraction). Phone stacks the blocks; tablet puts preview +
/// buttons left and chat full-height on the right.
///
/// Deliberately full-bleed (ratified media exception to the dashboard's
/// content-card grid): the preview keeps maximum width, the scene buttons
/// carry their own padding.
class DashboardContentStreaming extends StatefulWidget {
  const DashboardContentStreaming({super.key});

  @override
  State<DashboardContentStreaming> createState() =>
      _DashboardContentStreamingState();
}

class _DashboardContentStreamingState extends State<DashboardContentStreaming> {
  /// [SceneButtons] renders its horizontal-scroll row at size + 24
  static const double _sceneButtonsHeight = 64.0 + 24.0;

  /// Overlay toggle visual size (the hit floor around it is larger); the
  /// chat panel docks directly beside it
  static const double _toggleSize = 32.0;

  /// Top clamp for the draggable chat toggle - keeps it clear of the native
  /// chat window's own header row (title + status tag)
  static const double _toggleMinDy = 52.0;

  /// Bottom clamp margin - keeps the toggle roughly above the chat input
  /// dock and the centered pause chip
  static const double _toggleBottomMargin = 72.0;

  late bool _statsOverlay;
  late bool _headerOpen;

  /// Vertical position of the chat-header toggle: 0..1 fraction of its
  /// draggable range (1.0 = bottom, the default)
  late double _toggleDyFraction;

  @override
  void initState() {
    super.initState();
    final Box<dynamic> settingsBox = Hive.box(HiveKeys.Settings.name);
    this._statsOverlay =
        settingsBox.get(
              SettingsKeys.StreamingModeStatsOverlay.name,
              defaultValue: true,
            )
            as bool;
    this._headerOpen =
        settingsBox.get(
              SettingsKeys.StreamingModeChatHeaderOpen.name,
              defaultValue: false,
            )
            as bool;
    this._toggleDyFraction =
        (settingsBox.get(
                  SettingsKeys.StreamingModeChatToggleDyFraction.name,
                  defaultValue: 1.0,
                )
                as num)
            .toDouble()
            .clamp(0.0, 1.0);
  }

  void _toggleStats() => setState(() {
    this._statsOverlay = !this._statsOverlay;
    Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.StreamingModeStatsOverlay.name, this._statsOverlay);
  });

  void _toggleHeader() => setState(() {
    this._headerOpen = !this._headerOpen;
    Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.StreamingModeChatHeaderOpen.name, this._headerOpen);
  });

  Widget _previewWithOverlays({double? initialHeight, double? maxHeight}) =>
      Stack(
        children: [
          ResizeableScenePreview(
            initialHeight: initialHeight,
            maxHeight: maxHeight,
          ),
          if (this._statsOverlay)
            const Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: StreamHealthPill(),
            ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _OverlayToggleButton(
              icon: Icons.insights,
              active: this._statsOverlay,
              onTap: this._toggleStats,
            ),
          ),
        ],
      );

  Widget _chatWithOverlays() => LayoutBuilder(
    builder: (context, constraints) {
      final double height = constraints.maxHeight;
      final double maxDy = math.max(
        height - _toggleBottomMargin - _toggleSize,
        _toggleMinDy,
      );
      final double range = maxDy - _toggleMinDy;
      final double dy = range <= 0
          ? _toggleMinDy
          : (_toggleMinDy + this._toggleDyFraction * range).clamp(
              _toggleMinDy,
              maxDy,
            );

      /// Panel opens toward the roomier side of the toggle
      final bool opensDown = dy + _toggleSize / 2 < height / 2;

      return Stack(
        fit: StackFit.expand,
        children: [
          const StreamChat(usernameRowPadding: true, hideUsernameBar: true),
          Positioned(
            top: dy,
            right: AppSpacing.sm,
            child: _ChatHeaderToggleButton(
              active: this._headerOpen,
              onTap: this._toggleHeader,
              onVerticalDragUpdate: range <= 0
                  ? null
                  : (details) => setState(() {
                      this._toggleDyFraction =
                          ((dy + details.delta.dy - _toggleMinDy) / range)
                              .clamp(0.0, 1.0);
                    }),
              onVerticalDragEnd: (_) => Hive.box(HiveKeys.Settings.name).put(
                SettingsKeys.StreamingModeChatToggleDyFraction.name,
                this._toggleDyFraction,
              ),
            ),
          ),
          Positioned(
            top: opensDown ? dy + _toggleSize + AppSpacing.sm : null,
            bottom: opensDown ? null : height - dy + AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,

            /// SizedBox.shrink keeps the AnimatedSwitcher's layout stable
            /// while the panel is gone
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, opensDown ? -0.04 : 0.04),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: this._headerOpen
                  ? Material(
                      key: const ValueKey('chat-header-panel'),
                      elevation: 0.0,
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: ChatUsernameBar(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Padding(
        padding: EdgeInsets.only(bottom: tabBarBottomPadding(context)),
        child: ResponsiveWidgetWrapper(
          mobileWidget: Column(
            children: [
              this._previewWithOverlays(),
              const SceneButtons(
                size: 64,
                mode: SceneButtonsMode.horizontalScroll,
              ),
              Flexible(child: this._chatWithOverlays()),
            ],
          ),
          tabletWidget: LayoutBuilder(
            builder: (context, constraints) {
              /// The preview absorbs the full left column by default; the
              /// drag handle trades preview height for breathing room below
              /// the scene buttons
              final double previewHeight = math.max(
                constraints.maxHeight -
                    ResizeableScenePreview.dragHandleHeight -
                    _sceneButtonsHeight,
                75.0,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 3,
                    child: Column(
                      children: [
                        this._previewWithOverlays(
                          initialHeight: previewHeight,
                          maxHeight: previewHeight,
                        ),
                        const SceneButtons(
                          size: 64,
                          mode: SceneButtonsMode.horizontalScroll,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(flex: 2, child: this._chatWithOverlays()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Small translucent circular button floating over video / chat content -
/// highlight when its overlay is on, dimmed white when off. [badgeColor]
/// paints a status dot on the top-right edge (chat-header toggle: is a chat
/// channel/username selected at all). Optional vertical-drag callbacks turn
/// it into an edge-docked draggable (tap still fires on a clean touch).
///
/// Hit-slop contract: the visual stays 32px, the transparent 44x44 floor
/// around it (top-right anchored, so the circle never moves) carries the
/// hit area.
class _OverlayToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? badgeColor;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  const _OverlayToggleButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.badgeColor,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: this.onVerticalDragUpdate,
      onVerticalDragEnd: this.onVerticalDragEnd,
      child: Pressable(
        onTap: this.onTap,

        /// 32px visual glyph - standard release, no overshoot (rule 6)
        springy: false,
        child: SizedBox(
          width: kBaseIconButtonMinHitArea,
          height: kBaseIconButtonMinHitArea,
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      end: this.active
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.white60,
                    ),
                    duration: AppMotion.fast,
                    builder: (context, color, child) =>
                        Icon(this.icon, size: 18.0, color: color),
                  ),
                  if (this.badgeColor != null)
                    Positioned(
                      top: 5.0,
                      right: 5.0,
                      child: Container(
                        width: 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          color: this.badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tune toggle for the floating chat-header panel. The badge mirrors the
/// "is any chat selected" rule the chat pane itself uses (per-platform
/// username/channel present in the settings box), so a configured chat
/// stays glanceable while the header is hidden.
class _ChatHeaderToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  const _ChatHeaderToggleButton({
    required this.active,
    required this.onTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.SelectedChatType,
        SettingsKeys.SelectedTwitchUsername,
        SettingsKeys.SelectedYouTubeUsername,
        SettingsKeys.SelectedOwncastUsername,
      ],
      builder: (context, settingsBox, child) {
        final ChatType chatType = settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );
        final bool chatActive = switch (chatType) {
          ChatType.Twitch =>
            settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) != null,
          ChatType.YouTube =>
            settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name) != null,
          ChatType.Owncast =>
            settingsBox.get(SettingsKeys.SelectedOwncastUsername.name) != null,
        };
        return _OverlayToggleButton(
          icon: Icons.tune,
          active: this.active,
          onTap: this.onTap,
          badgeColor: chatActive
              ? Theme.of(context).extension<AppStatusColors>()!.reachable
              : Theme.of(context).extension<AppTextColors>()!.textOrnament,
          onVerticalDragUpdate: this.onVerticalDragUpdate,
          onVerticalDragEnd: this.onVerticalDragEnd,
        );
      },
    );
  }
}

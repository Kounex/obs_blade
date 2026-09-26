import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../shared/general/nested_list_manager.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/media/media_hub_layout.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import 'media_hub_arrange_sheet.dart';
import 'media_list_row.dart';
import 'media_pad.dart';
import 'media_transport_sheet.dart';

const String kMediaHubViewPads = 'pads';
const String kMediaHubViewList = 'list';

/// Soundboard + transport hub for every media source of the scene
/// collection. Two views over the same (arranged, per-connection) source
/// list: Pads (tap = play from the top) and List (full transport).
class MediaHub extends StatefulWidget {
  /// Pad edge on wide layouts - the grid fits as many as the width allows
  final double maxPadExtent;

  const MediaHub({super.key, this.maxPadExtent = 132.0});

  @override
  State<MediaHub> createState() => _MediaHubState();
}

class _MediaHubState extends State<MediaHub>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    /// Loads status + in-program state for every media input; the input
    /// list reload keeps it current from here on
    GetIt.instance<DashboardStore>().requestAllMediaStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTransport(String inputName) =>
      ModalHandler.showBaseCupertinoBottomSheet(
        context: this.context,
        modalWidgetBuilder: (context, controller) =>
            MediaTransportSheet(inputName: inputName),
      );

  void _openArrange(String connectionKey) =>
      ModalHandler.showBaseCupertinoBottomSheet(
        context: this.context,
        modalWidgetBuilder: (context, controller) =>
            MediaHubArrangeSheet(connectionKey: connectionKey),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.MediaHubViewMode,
        SettingsKeys.MediaHubLayouts,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          final String view =
              settingsBox.get(
                    SettingsKeys.MediaHubViewMode.name,
                    defaultValue: kMediaHubViewPads,
                  )
                  as String;
          final String? connectionKey = currentMediaHubConnectionKey();
          final MediaHubLayout layout = connectionKey == null
              ? MediaHubLayout.empty
              : readMediaHubLayout(
                  settingsBox.get(SettingsKeys.MediaHubLayouts.name),
                  connectionKey,
                );
          final List<String> all = layout.arrange([
            for (final input in dashboardStore.mediaInputs)
              if (input.inputName != null) input.inputName!,
          ]);
          final List<String> visible = all
              .where((name) => !layout.isHidden(name))
              .toList();
          final bool anyActive = visible.any(
            (name) => dashboardStore.mediaStatus[name]?.active ?? false,
          );

          return Column(
            children: [
              const StaleStateBadge(),
              _Toolbar(
                view: view,
                onView: (next) =>
                    settingsBox.put(SettingsKeys.MediaHubViewMode.name, next),
                onStopAll: anyActive
                    ? () => dashboardStore.stopAllMedia(visible)
                    : null,
                onArrange: connectionKey != null && all.isNotEmpty
                    ? () => _openArrange(connectionKey)
                    : null,
              ),
              const BaseDivider(),
              Expanded(
                child: NestedScrollManager(
                  parentScrollController:
                      ModalRoute.of(context)!.settings.arguments
                          as ScrollController,
                  child: Scrollbar(
                    controller: _controller,
                    thumbVisibility: true,
                    child: all.isEmpty
                        ? _EmptyState(controller: _controller)
                        : visible.isEmpty
                        ? _EmptyState(
                            controller: _controller,
                            allHidden: true,
                            onArrange: connectionKey != null
                                ? () => _openArrange(connectionKey)
                                : null,
                          )
                        : view == kMediaHubViewList
                        ? ListView(
                            controller: _controller,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            children: [
                              for (final (index, name) in visible.indexed)
                                StaggeredEntrance(
                                  key: ValueKey('row-$name'),
                                  index: index,
                                  rise: 0.0,
                                  child: MediaListRow(
                                    inputName: name,
                                    onOpenTransport: () => _openTransport(name),
                                  ),
                                ),
                            ],
                          )
                        : GridView.builder(
                            controller: _controller,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: this.widget.maxPadExtent,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: visible.length,
                            itemBuilder: (context, index) => StaggeredEntrance(
                              key: ValueKey('pad-${visible[index]}'),
                              index: index,
                              scaleFrom: 0.985,
                              child: MediaPad(
                                inputName: visible[index],
                                onOpenTransport: () =>
                                    _openTransport(visible[index]),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String view;
  final ValueChanged<String> onView;
  final VoidCallback? onStopAll;
  final VoidCallback? onArrange;

  const _Toolbar({
    required this.view,
    required this.onView,
    this.onStopAll,
    this.onArrange,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          CupertinoSlidingSegmentedControl<String>(
            groupValue: this.view,
            children: const {
              kMediaHubViewPads: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(CupertinoIcons.square_grid_2x2, size: 18.0),
              ),
              kMediaHubViewList: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(CupertinoIcons.list_bullet, size: 18.0),
              ),
            },
            onValueChanged: (next) {
              if (next != null) this.onView(next);
            },
          ),
          const Spacer(),
          StaleGuard(
            child: _ToolbarAction(
              icon: CupertinoIcons.stop_circle,
              label: 'Stop all',
              onTap: this.onStopAll,
            ),
          ),
          _ToolbarAction(
            icon: CupertinoIcons.slider_horizontal_3,
            label: 'Arrange',
            iconOnly: true,
            onTap: this.onArrange,
            color: theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool iconOnly;
  final Color? color;

  const _ToolbarAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconOnly = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = this.onTap == null
        ? theme.disabledColor
        : this.color ?? theme.extension<AppTextColors>()!.accentText;

    return Semantics(
      button: true,
      enabled: this.onTap != null,
      label: this.label,
      excludeSemantics: true,
      child: Pressable(
        haptic: true,
        onTap: this.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(this.icon, size: 20.0, color: color),
                if (!this.iconOnly) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    this.label,
                    style: theme.textTheme.labelLarge!.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ScrollController controller;
  final bool allHidden;
  final VoidCallback? onArrange;

  const _EmptyState({
    required this.controller,
    this.allHidden = false,
    this.onArrange,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;

    return ListView(
      controller: this.controller,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Icon(
          this.allHidden
              ? CupertinoIcons.eye_slash
              : CupertinoIcons.music_note_list,
          size: 28.0,
          color: textColors.textOrnament,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          this.allHidden ? 'All media sources hidden' : 'No media sources yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          this.allHidden
              ? 'Show them again via Arrange.'
              : 'Add a Media Source (or VLC Video Source) in OBS and it shows up here as a pad.\n\n'
                    'Tip: put your sound clips in their own "Soundboard" scene and add that scene as a source to your main scenes - they are always in program and heard on stream.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall!.copyWith(
            color: textColors.textSecondary,
          ),
        ),
        if (this.onArrange != null) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: CupertinoButton(
              onPressed: this.onArrange,
              child: const Text('Arrange'),
            ),
          ),
        ],
      ],
    );
  }
}

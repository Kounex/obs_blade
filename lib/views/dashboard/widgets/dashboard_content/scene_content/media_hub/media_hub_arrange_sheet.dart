import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../stores/shared/network.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/media/media_hub_layout.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';

/// Reorder + show/hide the Media hub's sources for the current connection.
/// Every change writes straight to `MediaHubLayouts` - the hub rebuilds
/// behind the sheet.
class MediaHubArrangeSheet extends StatelessWidget {
  final String connectionKey;

  const MediaHubArrangeSheet({super.key, required this.connectionKey});

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.MediaHubLayouts],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          final Object? raw = settingsBox.get(
            SettingsKeys.MediaHubLayouts.name,
          );
          final MediaHubLayout layout = readMediaHubLayout(
            raw,
            this.connectionKey,
          );
          final List<String> names = layout.arrange([
            for (final input in dashboardStore.mediaInputs)
              if (input.inputName != null) input.inputName!,
          ]);

          void save(MediaHubLayout next) => settingsBox.put(
            SettingsKeys.MediaHubLayouts.name,
            writeMediaHubLayout(raw, this.connectionKey, next),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arrange Media', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Drag to reorder, tap the eye to hide a source from the hub. Saved for this connection.',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: textColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const BaseDivider(),
                  ],
                ),
              ),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                  ),
                  itemCount: names.length,
                  onReorderItem: (oldIndex, newIndex) {
                    final List<String> order = [...names];
                    order.insert(newIndex, order.removeAt(oldIndex));
                    save(layout.withOrder(order));
                  },
                  itemBuilder: (context, index) {
                    final String name = names[index];
                    final bool hidden = layout.isHidden(name);
                    return Material(
                      key: ValueKey(name),
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 24.0,
                          right: AppSpacing.md,
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hidden
                              ? TextStyle(color: textColors.textTertiary)
                              : null,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              button: true,
                              toggled: !hidden,
                              label: hidden ? 'Show $name' : 'Hide $name',
                              excludeSemantics: true,
                              child: Pressable(
                                haptic: true,
                                onTap: () =>
                                    save(layout.withHidden(name, !hidden)),
                                child: SizedBox(
                                  width: 44.0,
                                  height: 44.0,
                                  child: Icon(
                                    hidden
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: hidden
                                        ? textColors.textTertiary
                                        : theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const SizedBox(
                                width: 44.0,
                                height: 44.0,
                                child: Icon(CupertinoIcons.line_horizontal_3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Current connection's layout key, or null without a session
String? currentMediaHubConnectionKey() {
  final session = GetIt.instance<NetworkStore>().activeSession;
  if (session == null) return null;
  return mediaHubConnectionKey(
    connectionName: session.connection.name,
    host: session.connection.host,
  );
}

/// Read helper for callers outside a HiveBuilder
MediaHubLayout currentMediaHubLayout(String connectionKey) =>
    readMediaHubLayout(
      Hive.box(HiveKeys.Settings.name).get(SettingsKeys.MediaHubLayouts.name),
      connectionKey,
    );

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/base/dropdown.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/canvas_view.dart';
import '../../../../../types/classes/api/obs_canvas.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';

/// Dropdown above the scene buttons to view another OBS canvas (e.g. a
/// vertical one). Only shows when OBS reports more than one canvas and
/// [SettingsKeys.ExposeCanvasSwitcher] is on (default).
class CanvasPicker extends StatelessWidget {
  const CanvasPicker({super.key});

  static String _label(ObsCanvas canvas) {
    final name = canvas.name.isNotEmpty
        ? canvas.name
        : canvas.isMain
        ? 'Main'
        : 'Canvas';
    final resolution = canvas.resolutionLabel;
    return resolution != null ? '$name · $resolution' : name;
  }

  @override
  Widget build(BuildContext context) {
    final CanvasViewStore? canvasStore = canvasViewStoreOrNull();
    if (canvasStore == null) return const SizedBox();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeCanvasSwitcher],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          if (!(settingsBox.get(
                    SettingsKeys.ExposeCanvasSwitcher.name,
                    defaultValue: true,
                  )
                  as bool) ||
              !canvasStore.hasMultipleCanvases) {
            return const SizedBox();
          }

          final String? mainUuid = canvasStore.canvases
              .where((canvas) => canvas.isMain)
              .map((canvas) => canvas.uuid)
              .firstOrNull;

          return BaseCard(
            topPadding: 0.0,
            rightPadding: AppSpacing.md,
            bottomPadding: 0.0,
            leftPadding: AppSpacing.md,
            child: StaleGuard(
              child: BaseDropdown<String>(
                value: canvasStore.viewedCanvasUuid ?? mainUuid,
                label: 'Canvas',
                items: canvasStore.canvases
                    .map(
                      (canvas) => BaseDropdownItem(
                        value: canvas.uuid,
                        text: _label(canvas),
                      ),
                    )
                    .toList(),
                onChanged: canvasStore.viewCanvas,
              ),
            ),
          );
        },
      ),
    );
  }
}

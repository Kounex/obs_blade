import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../types/extensions/string.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';
import '../add_edit_theme/add_edit_theme.dart';
import 'theme_colors_row.dart';

/// A theme in the list, rendered as a small preview card: activation
/// badge, miniature app-chrome mock painted from the theme's own slots,
/// name / description and the full color bubble strip.
class ThemeEntry extends StatelessWidget {
  final CustomTheme customTheme;
  final bool isEditable;

  const ThemeEntry(
      {super.key, required this.customTheme, this.isEditable = true});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.ActiveCustomThemeUUID.name,
        this.customTheme.uuid,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// The activation badge overlays the preview's top-left
                  /// corner instead of reserving a permanent gutter, so
                  /// entries keep one left alignment whether or not a
                  /// theme is active.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ThemePreview(customTheme: this.customTheme),
                      Positioned(
                        top: -6.0,
                        left: -6.0,
                        child: HiveBuilder<dynamic>(
                          hiveKey: HiveKeys.Settings,
                          rebuildKeys: const [
                            SettingsKeys.ActiveCustomThemeUUID
                          ],
                          builder: (context, settingsBox, child) =>
                              AnimatedSwitcher(
                            duration: AppMotion.medium,
                            switchInCurve: AppMotion.standard,
                            switchOutCurve: AppMotion.exit,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: animation,
                                  curve: AppMotion.spring,
                                  reverseCurve: AppMotion.exit,
                                ),
                                child: child,
                              ),
                            ),
                            child: settingsBox.get(
                                        SettingsKeys
                                            .ActiveCustomThemeUUID.name,
                                        defaultValue: '') ==
                                    this.customTheme.uuid
                                ? _ActiveBadge(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: !this.isEditable ? AppSpacing.xl : 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            this.customTheme.name ?? 'Unnamed theme',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          if (this.customTheme.description != null &&
                              this.customTheme.description!.isNotEmpty) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              this.customTheme.description!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          ThemeColorsRow(customTheme: this.customTheme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (this.isEditable)
              ThemedCupertinoButton(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                text: 'Edit',
                onPressed: () => ModalHandler.showBaseCupertinoBottomSheet(
                  context: context,
                  modalWidgetBuilder: (context, scrollController) =>
                      AddEditTheme(
                    customTheme: this.customTheme,
                    scrollController: scrollController,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

/// Filled selection badge shown for the currently active theme (morphs in
/// via the [AnimatedSwitcher] in [ThemeEntry]).
class _ActiveBadge extends StatelessWidget {
  final Color color;

  const _ActiveBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26.0,
      height: 26.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: this.color.withValues(alpha: 0.16),
        border: Border.all(color: this.color, width: 1.5),
      ),
      child: Icon(
        CupertinoIcons.checkmark,
        size: 14.0,
        color: this.color,
      ),
    );
  }
}

/// Miniature app-chrome mock (app bar / card / tab bar) painted entirely
/// from the theme's own slots - makes each entry read as a tiny preview
/// of the app running that theme.
class _ThemePreview extends StatelessWidget {
  final CustomTheme customTheme;

  const _ThemePreview({required this.customTheme});

  @override
  Widget build(BuildContext context) {
    final Color? cardBorder = this.customTheme.cardBorderColorHex?.hexToColor();

    return Container(
      width: 60.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: this.customTheme.backgroundColorHex.hexToColor(),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Column(
          children: [
            Container(
              height: 7.0,
              color: this.customTheme.appBarColorHex.hexToColor(),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 42.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    color: this.customTheme.cardColorHex.hexToColor(),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    border: cardBorder != null
                        ? Border.all(color: cardBorder.withValues(alpha: 0.6))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5.0,
                        height: 5.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: this.customTheme.accentColorHex.hexToColor(),
                        ),
                      ),
                      const SizedBox(width: 3.0),
                      Container(
                        width: 16.0,
                        height: 3.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2.0),
                          color: this
                                  .customTheme
                                  .dividerColorHex
                                  ?.hexToColor() ??
                              StylingHelper.light_divider_color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 7.0,
              color: this.customTheme.tabBarColorHex.hexToColor(),
              alignment: Alignment.center,
              child: Container(
                width: 3.0,
                height: 3.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: this.customTheme.highlightColorHex.hexToColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

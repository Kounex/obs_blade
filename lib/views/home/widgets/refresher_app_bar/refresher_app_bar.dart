import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../models/custom_theme.dart';
import '../../../../shared/animator/fader.dart';
import '../../../../shared/design/app_spacing.dart';
import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../types/extensions/string.dart';
import '../../../../utils/styling_helper.dart';
import 'scroll_refresh_icon.dart';

const double kRefresherAppBarHeight = 44.0;

class RefresherAppBar extends StatelessWidget {
  final double? expandedHeight;

  const RefresherAppBar({
    super.key,
    this.expandedHeight,
  });

  @override
  Widget build(BuildContext context) {
    return TransculentSliverAppBar(
      pinned: true,
      stretch: true,
      toolbarHeight: kRefresherAppBarHeight,
      expandedHeight: this.expandedHeight,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              /// Theme hairline (same convention as [BaseDivider]) instead of
              /// a hardcoded dynamic color - stays correct on custom themes
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          titlePadding: const EdgeInsetsDirectional.only(bottom: 16),
          title: LayoutBuilder(
            builder: (context, constraints) {
              if ((constraints.maxHeight -
                          (MediaQuery.paddingOf(context).top - 16))
                      .toInt() <=
                  kRefresherAppBarHeight.toInt()) {
                return Fader(
                  child: Transform.translate(
                    offset: const Offset(0, 4.0),
                    child: Text(
                      'OBS Blade',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle,
                    ),
                  ),
                );
              }
              return ScrollRefreshIcon(
                expandedBarHeight: this.expandedHeight,
                currentBarHeight: constraints.maxHeight,
              );
            },
          ),
          background: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.CustomTheme,
              SettingsKeys.ActiveCustomThemeUUID
            ],
            builder: (context, settingsBox, child) {
              CustomTheme? customTheme =
                  StylingHelper.currentCustomTheme(settingsBox);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: customTheme?.logoAppBarColorHex?.hexToColor() ??
                        Colors.transparent,
                  ),
                  /// Inset from notch + bottom edge, then contain so the
                  /// logo stays large without overflowing the bar.
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      MediaQuery.paddingOf(context).top * 0.45,
                      AppSpacing.xl,
                      AppSpacing.xs,
                    ),
                    child: customTheme?.customLogo != null
                        ? Image.memory(
                            base64Decode(customTheme!.customLogo!),
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            StylingHelper.brightnessAwareOBSLogo(context),
                            fit: BoxFit.contain,
                          ),
                  ),

                  /// Subtle top scrim so status-bar icons stay legible
                  /// over the (white) logo when the bar is stretched
                  Positioned(
                    top: 0.0,
                    left: 0.0,
                    right: 0.0,
                    height: kRefresherAppBarHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .scaffoldBackgroundColor
                                .withValues(alpha: 0.9),
                            Theme.of(context)
                                .scaffoldBackgroundColor
                                .withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          collapseMode: CollapseMode.parallax,
          stretchModes: const [
            StretchMode.blurBackground,
            StretchMode.zoomBackground
          ],
        ),
      ),
    );
  }
}

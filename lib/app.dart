import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'models/custom_theme.dart';
import 'shared/design/design.dart';
import 'shared/general/hive_builder.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'types/extensions/string.dart';
import 'utils/built_in_themes.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';

// GlobalKey<NavigatorState> rootNavKey = GlobalKey();

class App extends StatelessWidget {
  const App({
    super.key,
  });

  ThemeData _getCurrentTheme(Box settingsBox) {
    Brightness? brightness;
    Color? scaffoldBackgroundColor;
    Color? accentColor;
    Color? hightlightColor;
    Color? backgroundColor;
    Color? canvasColor;
    Color? cardColor;
    Color? indicatorColor;
    Color? toggleableActiveColor;
    Color? sliderColor;
    Color? appBarColor;
    Color? buttonColor;
    Color? tabBarColor;
    Color? dividerColor;

    if (settingsBox.get(SettingsKeys.CustomTheme.name, defaultValue: false)) {
      CustomTheme? activeCustomTheme;
      try {
        activeCustomTheme = [
          ...BuiltInThemes.themes,
          ...Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).values
        ].firstWhere((customTheme) =>
            customTheme.uuid ==
            settingsBox.get(SettingsKeys.ActiveCustomThemeUUID.name,
                defaultValue: ''));
      } catch (e) {
        // No cusotm theme
      }
      if (activeCustomTheme != null) {
        brightness = activeCustomTheme.useLightBrightness
            ? Brightness.light
            : Brightness.dark;
        scaffoldBackgroundColor =
            activeCustomTheme.backgroundColorHex.hexToColor();
        accentColor = activeCustomTheme.accentColorHex.hexToColor();
        hightlightColor = activeCustomTheme.highlightColorHex.hexToColor();
        backgroundColor = activeCustomTheme.cardColorHex.hexToColor();
        canvasColor = activeCustomTheme.cardColorHex.hexToColor();
        cardColor = activeCustomTheme.cardColorHex.hexToColor();
        indicatorColor = activeCustomTheme.highlightColorHex.hexToColor();
        toggleableActiveColor = activeCustomTheme.accentColorHex.hexToColor();
        sliderColor = Colors.transparent;
        appBarColor = activeCustomTheme.appBarColorHex.hexToColor();
        buttonColor = activeCustomTheme.accentColorHex.hexToColor();
        tabBarColor = activeCustomTheme.tabBarColorHex.hexToColor();
        dividerColor = activeCustomTheme.dividerColorHex?.hexToColor();
      }
    }

    ThemeData baseThemeData =
        (brightness != null && brightness == Brightness.light
            ? ThemeData.light()
            : ThemeData.dark());

    final TextTheme appTextTheme = buildAppTextTheme(baseThemeData.textTheme);

    /// One label family for every text field (BaseAdaptiveTextField and
    /// plain TextFormField alike): same size/color everywhere, only the
    /// field state shifts the color (focus = highlight, error and
    /// disabled stay distinguishable)
    TextStyle statefulLabelStyle(TextStyle base) =>
        WidgetStateTextStyle.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return base.copyWith(color: baseThemeData.disabledColor);
            }
            if (states.contains(WidgetState.error)) {
              return base.copyWith(color: baseThemeData.colorScheme.error);
            }
            if (states.contains(WidgetState.focused)) {
              return base.copyWith(
                  color: hightlightColor ?? StylingHelper.highlight_color);
            }
            return base;
          },
        );

    return baseThemeData.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor ??
          (settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
              ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                      defaultValue: false)
                  ? StylingHelper.background_reduced_smearing_color
                  : StylingHelper.background_color
              : '212123'.hexToColor()),
      canvasColor: canvasColor ?? StylingHelper.primary_color,
      cardColor: cardColor ?? StylingHelper.primary_color,
      indicatorColor: indicatorColor ?? StylingHelper.highlight_color,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      textSelectionTheme: TextSelectionThemeData(
        selectionColor: accentColor ?? StylingHelper.highlight_color,
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor ?? StylingHelper.light_divider_color,
      ),

      /// Setting a platform specifically to manipulate the platform
      /// agnostic elements (if the user opted in for that)
      platform: settingsBox.get(SettingsKeys.ForceNonNativeElements.name,
              defaultValue: false)
          ? (Platform.isIOS || Platform.isMacOS
              ? TargetPlatform.android
              : TargetPlatform.iOS)
          : defaultTargetPlatform,

      /// Inner Widget themes
      primaryIconTheme: baseThemeData.iconTheme.copyWith(
        color: brightness != null && brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      ),

      textTheme: appTextTheme,

      /// Consistent label/hint rendering for every field: 15pt inline
      /// label shrinking to a 12pt floating label, callout-grey family
      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: appTextTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
        labelStyle: statefulLabelStyle(
            appTextTheme.bodyMedium!.copyWith(color: Colors.grey[500])),
        floatingLabelStyle: statefulLabelStyle(
            appTextTheme.labelMedium!.copyWith(color: Colors.grey[500])),
      ),

      /// Cupertino slide transitions on all platforms - that IS the
      /// app's feel (all in-tab pushes are CupertinoPageRoute already)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),

      /// Semantic status colors (live / recording / warning / reachability) -
      /// constant across custom themes, they are signal colors, not brand
      extensions: const [AppStatusColors.standard],

      /// Sub-themes which used to leak stock colors - derived from the
      /// active card/highlight slots instead
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor ?? StylingHelper.primary_color,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: StylingHelper.lightenDarkenColor(
            cardColor ?? StylingHelper.primary_color, 8),

        /// The background above is a near-card tone, so the stock M3
        /// content color can land mid-gray on it — pin the foreground to
        /// the app's plain readable tone instead.
        contentTextStyle: appTextTheme.bodyMedium?.copyWith(
          color: brightness != null && brightness == Brightness.light
              ? Colors.black
              : Colors.white,
        ),
        actionTextColor: hightlightColor ?? StylingHelper.highlight_color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: baseThemeData.chipTheme.copyWith(
        backgroundColor: StylingHelper.lightenDarkenColor(
            cardColor ?? StylingHelper.primary_color, 8),
        selectedColor: (hightlightColor ?? StylingHelper.highlight_color)
            .withValues(alpha: 0.24),
        checkmarkColor: hightlightColor ?? StylingHelper.highlight_color,
        side: BorderSide.none,
      ),

      sliderTheme: SliderThemeData(
        activeTickMarkColor:
            Colors.transparent, // sliderColor ?? StylingHelper.highlight_color,
        activeTrackColor:
            Colors.transparent, //sliderColor ?? StylingHelper.highlight_color,
        valueIndicatorColor: sliderColor ?? StylingHelper.highlight_color,
        thumbColor: sliderColor ?? StylingHelper.highlight_color,
        thumbShape: BorderRoundSliderThumbShape(
          borderColor: StylingHelper.surroundingAwareAccent(
            surroundingColor: cardColor ?? StylingHelper.primary_color,
          ),
        ),
        overlayColor:
            (sliderColor ?? StylingHelper.highlight_color).withOpacity(0.3),
        inactiveTrackColor:
            (sliderColor ?? StylingHelper.highlight_color).withOpacity(0.3),
        inactiveTickMarkColor: Colors
            .transparent, //(sliderColor ?? StylingHelper.highlight_color).withOpacity(0.3),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: brightness != null && brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: (appBarColor ?? StylingHelper.primary_color)
            .withOpacity(StylingHelper.opacity_blurry),
        surfaceTintColor: Colors.transparent,
      ),

      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(
          accentColor: buttonColor ?? StylingHelper.accent_color,
        ),
        buttonColor: buttonColor ?? StylingHelper.accent_color,
      ),

      cupertinoOverrideTheme: CupertinoThemeData(
        scaffoldBackgroundColor: scaffoldBackgroundColor ??
            (settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
                ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                        defaultValue: false)
                    ? StylingHelper.background_reduced_smearing_color
                    : StylingHelper.background_color
                : Colors.grey[900]),
        textTheme: CupertinoTextThemeData(
          primaryColor: hightlightColor ?? StylingHelper.highlight_color,
        ),
        barBackgroundColor: (tabBarColor ?? StylingHelper.primary_color)
            .withOpacity(StylingHelper.opacity_blurry),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return toggleableActiveColor ?? StylingHelper.accent_color;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return toggleableActiveColor ?? StylingHelper.accent_color;
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return toggleableActiveColor ?? StylingHelper.accent_color;
          }
          return null;
        }),
      ),
      colorScheme: ColorScheme.fromSwatch(
        accentColor: hightlightColor ?? StylingHelper.highlight_color,
        brightness: brightness ?? Brightness.dark,
      ).copyWith(background: backgroundColor ?? StylingHelper.primary_color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.TrueDark,
        SettingsKeys.ReduceSmearing,
        SettingsKeys.CustomTheme,
        SettingsKeys.ActiveCustomThemeUUID,
        SettingsKeys.ForceNonNativeElements,
      ],
      builder: (context, Box settingsBox, child) => HiveBuilder<CustomTheme>(
        hiveKey: HiveKeys.CustomTheme,
        builder: (context, customThemeBox, child) {
          return MaterialApp(
            // navigatorKey: rootNavKey,
            debugShowCheckedModeBanner: false,
            theme: _getCurrentTheme(settingsBox),
            initialRoute: settingsBox.get(
              SettingsKeys.HasUserSeenIntro202208.name,
              defaultValue: false,
            )
                ? AppRoutingKeys.Tabs.route
                // ? AppRoutingKeys.Intro.route
                : AppRoutingKeys.Intro.route,
            onGenerateInitialRoutes: (initialRoute) => [
              MaterialPageRoute(
                builder: RoutingHelper.appRoutes[initialRoute]!,
                settings: RouteSettings(name: initialRoute),
              ),
            ],
            routes: RoutingHelper.appRoutes,
          );
        },
      ),
    );
  }
}

class BorderRoundSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;

  final double? disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  final double elevation;
  final double pressedElevation;

  final double borderWidth;
  final Color borderColor;

  const BorderRoundSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 0.0,
    this.pressedElevation = 0.0,
    this.borderWidth = 1.0,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );

    final ColorTween borderColorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: this.borderColor,
    );

    final Color color = colorTween.evaluate(enableAnimation)!;
    final Color borderColor = borderColorTween.evaluate(enableAnimation)!;
    final double radius = radiusTween.evaluate(enableAnimation);

    canvas.drawCircle(
      center,
      radius + 0.5,
      Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color,
    );
  }
}

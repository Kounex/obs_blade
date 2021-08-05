import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'models/custom_theme.dart';
import 'shared/general/hive_builder.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'types/extensions/string.dart';
import 'utils/built_in_themes.dart';
import 'utils/routing_helper.dart';
import 'utils/styling_helper.dart';

class App extends StatelessWidget {
  ThemeData _getCurrentTheme(Box settingsBox) {
    Brightness? brightness;
    Color? scaffoldBackgroundColor;
    Color? accentColor;
    Color? backgroundColor;
    Color? canvasColor;
    Color? cardColor;
    Color? indicatorColor;
    Color? toggleableActiveColor;
    Color? sliderColor;
    Color? appBarColor;
    Color? buttonColor;
    Color? extraButtonColor;
    Color? tabBarColor;
    Color? cursorColor;
    Color? cupertinoPrimaryColor;

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
      } catch (e) {}
      if (activeCustomTheme != null) {
        brightness = activeCustomTheme.useLightBrightness
            ? Brightness.light
            : Brightness.dark;
        scaffoldBackgroundColor =
            activeCustomTheme.backgroundColorHex.hexToColor();
        accentColor = activeCustomTheme.accentColorHex.hexToColor();
        backgroundColor = activeCustomTheme.cardColorHex.hexToColor();
        canvasColor = activeCustomTheme.cardColorHex.hexToColor();
        cardColor = activeCustomTheme.cardColorHex.hexToColor();
        indicatorColor = activeCustomTheme.accentColorHex.hexToColor();
        toggleableActiveColor = activeCustomTheme.accentColorHex.hexToColor();
        sliderColor = Colors.transparent;
        appBarColor = activeCustomTheme.appBarColorHex.hexToColor();
        buttonColor = activeCustomTheme.accentColorHex.hexToColor();
        extraButtonColor = activeCustomTheme.highlightColorHex.hexToColor();
        tabBarColor = activeCustomTheme.tabBarColorHex.hexToColor();
        cursorColor = activeCustomTheme.accentColorHex.hexToColor();
        cupertinoPrimaryColor =
            activeCustomTheme.highlightColorHex.hexToColor();
      }
    }

    ThemeData baseThemeData =
        (brightness != null && brightness == Brightness.light
            ? ThemeData.light()
            : ThemeData.dark());

    return baseThemeData.copyWith(
      primaryColorBrightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor ??
          (settingsBox.get(SettingsKeys.TrueDark.name, defaultValue: false)
              ? settingsBox.get(SettingsKeys.ReduceSmearing.name,
                      defaultValue: false)
                  ? StylingHelper.background_reduced_smearing_color
                  : StylingHelper.background_color
              : '212123'.hexToColor()), //Colors.grey[900]),
      accentColor: accentColor ?? StylingHelper.highlight_color,
      backgroundColor: backgroundColor ?? StylingHelper.primary_color,
      canvasColor: canvasColor ?? StylingHelper.primary_color,
      cardColor: cardColor ?? StylingHelper.primary_color,
      // cursorColor: cursorColor ?? StylingHelper.highlight_color,
      indicatorColor: indicatorColor ?? StylingHelper.highlight_color,
      buttonColor: extraButtonColor,
      dividerColor: Colors.grey[500],
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: accentColor ?? StylingHelper.highlight_color,
      ),
      toggleableActiveColor:
          toggleableActiveColor ?? StylingHelper.accent_color,

      /// Inner Widget themes
      primaryIconTheme: IconThemeData(
        color: brightness != null && brightness == Brightness.light
            ? Colors.black
            : Colors.white,
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

      // useTextSelectionTheme: true,

      // textSelectionTheme: TextSelectionThemeData(
      //   cursorColor: cursorColor ?? StylingHelper.highlight_color,
      //   selectionColor: cursorColor ?? StylingHelper.highlight_color,
      //   selectionHandleColor: cursorColor ?? StylingHelper.highlight_color,
      // ),

      // textSelectionHandleColor: cursorColor ?? StylingHelper.highlight_color,

      tabBarTheme: TabBarTheme(
        labelColor: brightness != null && brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      ),

      appBarTheme: AppBarTheme(
        color: (appBarColor ?? StylingHelper.primary_color)
            .withOpacity(StylingHelper.opacity_blurry),
      ),

      buttonTheme: ButtonThemeData(
        buttonColor: buttonColor ?? StylingHelper.accent_color,
        splashColor: Colors.transparent,
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
          primaryColor: accentColor ?? StylingHelper.highlight_color,
        ),
        barBackgroundColor: (tabBarColor ?? StylingHelper.primary_color)
            .withOpacity(StylingHelper.opacity_blurry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: [
        SettingsKeys.TrueDark,
        SettingsKeys.ReduceSmearing,
        SettingsKeys.CustomTheme,
        SettingsKeys.ActiveCustomThemeUUID,
      ],
      builder: (context, Box settingsBox, child) => HiveBuilder<CustomTheme>(
        hiveKey: HiveKeys.CustomTheme,
        builder: (context, customThemeBox, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _getCurrentTheme(settingsBox),
            initialRoute: settingsBox.get(SettingsKeys.HasUserSeenIntro.name,
                    defaultValue: false)
                ? AppRoutingKeys.Tabs.route
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

    final Tween<double> elevationTween = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    );

    // final double evaluatedElevation =
    //     elevationTween.evaluate(activationAnimation);
    // final Path path = Path()
    //   ..addArc(
    //       Rect.fromCenter(
    //           center: center, width: 2 * radius, height: 2 * radius),
    //       0,
    //       pi * 2);
    // canvas.drawShadow(path, Colors.black, evaluatedElevation, true);

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

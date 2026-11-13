import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/animator/full_overlay.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/modal_handler.dart';

/// Settings -> Theme -> Bars & Sheets: every floating surface (bars, tab
/// bar, sheets, toasts) blurs only in Glass - Clear and Solid draw a plain
/// color (issue #106: blur cost on slower Android GPUs)
void main() {
  const Color barSlot = Color(0xFF1B1B1F);

  ThemeData theme(SurfaceStyle style, {TargetPlatform? platform}) => ThemeData(
    brightness: Brightness.dark,
    platform: platform,
    cardColor: const Color(0xFF202024),
    cupertinoOverrideTheme: const CupertinoThemeData(),
    extensions: [
      AppStatusColors.standard,
      AppTextColors.standard,
      AppGlass.forBar(barSlot, style: style),
    ],
  );

  const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(CupertinoIcons.gear), label: 'Settings'),
  ];

  Widget tabBarApp(SurfaceStyle style, {required Widget tabBar}) => MaterialApp(
    theme: theme(style),
    home: Scaffold(
      extendBody: true,
      body: const SizedBox.expand(),
      bottomNavigationBar: GlassBar(
        contentEdge: GlassBarEdge.top,
        child: tabBar,
      ),
    ),
  );

  Color barFill(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(GlassBar),
              matching: find.byType(ColoredBox),
            )
            .first,
      )
      .color;

  group('tab bar', () {
    testWidgets('stock CupertinoTabBar in a GlassBar blurs twice', (
      tester,
    ) async {
      /// Why GlassCupertinoTabBar exists: a non-opaque CupertinoTabBar adds
      /// its own BackdropFilter under the GlassBar's
      await tester.pumpWidget(
        tabBarApp(
          SurfaceStyle.glass,
          tabBar: CupertinoTabBar(
            items: items,
            backgroundColor: Colors.transparent,
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNWidgets(2));
    });

    testWidgets('glass: one blur - the GlassBar\'s', (tester) async {
      await tester.pumpWidget(
        tabBarApp(
          SurfaceStyle.glass,
          tabBar: GlassCupertinoTabBar(items: items),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(barFill(tester).a, closeTo(AppGlass.barAlpha, 0.01));
    });

    testWidgets('clear: no blur, mostly opaque', (tester) async {
      await tester.pumpWidget(
        tabBarApp(
          SurfaceStyle.clear,
          tabBar: GlassCupertinoTabBar(items: items),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(barFill(tester).a, closeTo(AppGlass.clearAlpha, 0.01));
    });

    testWidgets('solid: no blur, opaque', (tester) async {
      await tester.pumpWidget(
        tabBarApp(
          SurfaceStyle.solid,
          tabBar: GlassCupertinoTabBar(items: items),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(barFill(tester).a, 1.0);
    });

    testWidgets('the tab bar itself stays transparent and borderless', (
      tester,
    ) async {
      await tester.pumpWidget(
        tabBarApp(
          SurfaceStyle.glass,
          tabBar: GlassCupertinoTabBar(items: items),
        ),
      );
      final GlassCupertinoTabBar bar = tester.widget(
        find.byType(GlassCupertinoTabBar),
      );
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.border, const Border());
    });
  });

  group('sheets', () {
    Future<void> openSheet(
      WidgetTester tester,
      SurfaceStyle style,
      TargetPlatform platform,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme(style, platform: platform),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ModalHandler.showBaseBottomSheet(
                    context: context,
                    builder: (_) => const Text('Sheet body'),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet body'), findsOneWidget);
    }

    Finder sheetBlur() => find.ancestor(
      of: find.text('Sheet body'),
      matching: find.byType(BackdropFilter),
    );

    Color sheetColor(WidgetTester tester) {
      final Container surface = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.text('Sheet body'),
              matching: find.byType(Container),
            ),
          )
          .firstWhere(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration as BoxDecoration).color != null,
          );
      return (surface.decoration as BoxDecoration).color!;
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('glass blurs on ${platform.name}', (tester) async {
        await openSheet(tester, SurfaceStyle.glass, platform);
        expect(sheetBlur(), findsOneWidget);
        expect(sheetColor(tester).a, closeTo(AppGlass.barAlpha, 0.01));
      });

      testWidgets('clear: no blur on ${platform.name}', (tester) async {
        await openSheet(tester, SurfaceStyle.clear, platform);
        expect(sheetBlur(), findsNothing);
        expect(sheetColor(tester).a, closeTo(AppGlass.clearAlpha, 0.01));
      });

      testWidgets('solid: opaque on ${platform.name}', (tester) async {
        await openSheet(tester, SurfaceStyle.solid, platform);
        expect(sheetBlur(), findsNothing);
        expect(sheetColor(tester).a, 1.0);
      });
    }
  });

  group('toast', () {
    Future<void> showToast(WidgetTester tester, SurfaceStyle style) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme(style),
          home: const Scaffold(
            body: FullOverlay(
              content: Text('Saved'),
              animationDuration: Duration(milliseconds: 200),
              showDuration: Duration(seconds: 1),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved'), findsOneWidget);
    }

    /// Lets the close timer fire and the fade-out finish
    Future<void> closeToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    Finder toastBlur() => find.ancestor(
      of: find.text('Saved'),
      matching: find.byType(BackdropFilter),
    );

    Color toastColor(WidgetTester tester) => tester
        .widget<Material>(
          find
              .ancestor(of: find.text('Saved'), matching: find.byType(Material))
              .first,
        )
        .color!;

    testWidgets('glass: animated backdrop blur', (tester) async {
      await showToast(tester, SurfaceStyle.glass);
      expect(toastBlur(), findsOneWidget);
      expect(toastColor(tester).a, closeTo(0.87, 0.01));
      await closeToast(tester);
    });

    testWidgets('clear: no blur', (tester) async {
      await showToast(tester, SurfaceStyle.clear);
      expect(toastBlur(), findsNothing);
      expect(toastColor(tester).a, closeTo(AppGlass.clearAlpha, 0.01));
      await closeToast(tester);
    });

    testWidgets('solid: no blur, opaque', (tester) async {
      await showToast(tester, SurfaceStyle.solid);
      expect(toastBlur(), findsNothing);
      expect(toastColor(tester).a, 1.0);
      await closeToast(tester);
    });
  });
}

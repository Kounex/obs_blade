import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/design.dart';

/// Body tracking per device font: SF Pro keeps its own spacing, Roboto keeps
/// Material's. Material's spacing isn't in [ThemeData.textTheme] - it's the
/// typography geometry [Theme.of] merges in wherever the theme leaves
/// letterSpacing unset - so this checks the resolved theme.
void main() {
  Future<TextTheme> resolved(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    final base = ThemeData.dark();
    late TextTheme textTheme;
    await tester.pumpWidget(
      Theme(
        data: base.copyWith(
          textTheme: buildAppTextTheme(
            base.textTheme,
            textSecondary: AppTextColors.standard.textSecondary,
            textTertiary: AppTextColors.standard.textTertiary,
            platform: platform,
          ),
        ),
        child: Builder(
          builder: (context) {
            textTheme = Theme.of(context).textTheme;
            return const SizedBox();
          },
        ),
      ),
    );
    return textTheme;
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    testWidgets('$platform: body slots have no added letter spacing', (
      tester,
    ) async {
      final theme = await resolved(tester, platform);
      expect(theme.bodyLarge!.letterSpacing, 0.0);
      expect(theme.bodyMedium!.letterSpacing, 0.0);
      expect(theme.bodySmall!.letterSpacing, 0.0);
    });
  }

  testWidgets('Android: body slots keep Material spacing', (tester) async {
    final theme = await resolved(tester, TargetPlatform.android);
    final geometry = Typography.material2021().englishLike;
    expect(theme.bodyLarge!.letterSpacing, geometry.bodyLarge!.letterSpacing);
    expect(theme.bodyMedium!.letterSpacing, geometry.bodyMedium!.letterSpacing);
    expect(theme.bodySmall!.letterSpacing, geometry.bodySmall!.letterSpacing);
    expect(theme.bodyMedium!.letterSpacing, greaterThan(0));
  });

  testWidgets('non-body slots match across platforms', (tester) async {
    final ios = await resolved(tester, TargetPlatform.iOS);
    final android = await resolved(tester, TargetPlatform.android);
    expect(
      ios.headlineSmall!.letterSpacing,
      android.headlineSmall!.letterSpacing,
    );
    expect(ios.titleMedium!.letterSpacing, android.titleMedium!.letterSpacing);
    expect(ios.labelSmall!.letterSpacing, 0.8);
    expect(android.labelSmall!.letterSpacing, 0.8);
  });
}

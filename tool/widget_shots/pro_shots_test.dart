import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/views/pro/widgets/pro_benefits.dart';

import 'support/shots_harness.dart';

/// Paywall benefit cards: every card on its own (tile colour, glyph,
/// copy length), the phone carousel and the tablet grid.
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('every benefit card', (tester) async {
    await harness.shot(
      tester,
      'pro_benefit_cards',
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final ProBenefit benefit in kProBenefits) ...[
              ProBenefitCard(benefit: benefit),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
      size: const Size(390, 1500),
    );
  });

  testWidgets('phone carousel', (tester) async {
    await harness.shot(
      tester,
      'pro_benefits_phone',
      const Column(children: [ProBenefitsBrowser()]),
    );
  });

  testWidgets('narrow phone carousel', (tester) async {
    await harness.shot(
      tester,
      'pro_benefits_narrow',
      const Column(children: [ProBenefitsBrowser()]),
      size: const Size(320, 640),
    );
  });

  testWidgets('tablet grid', (tester) async {
    await harness.shot(
      tester,
      'pro_benefits_tablet',
      const SingleChildScrollView(child: ProBenefitsBrowser()),
      size: kShotTablet,
    );
  });
}

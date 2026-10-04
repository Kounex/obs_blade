import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/pro/widgets/pro_benefits.dart';

/// One Pro story: five groups on the paywall, the same names in the same
/// order on the locked panes (minus the pane's own feature).
void main() {
  test('five groups, one per feature, activity and TTS included', () {
    expect(kProBenefits.map((b) => b.feature), ProFeature.values);
    expect(kProBenefits.map((b) => b.title), [
      'Every Chat, One Place',
      'Never Miss a Supporter',
      'Hear Your Chat',
      'Moderate From Your Pocket',
      'Make It Yours',
    ]);
  });

  test('locked panes: the other four groups, in order', () {
    expect(proBenefitTaste(except: ProFeature.chat).map((b) => b.feature), [
      ProFeature.activity,
      ProFeature.speech,
      ProFeature.moderation,
      ProFeature.themes,
    ]);
    expect(proBenefitTaste(except: ProFeature.activity).map((b) => b.feature), [
      ProFeature.chat,
      ProFeature.speech,
      ProFeature.moderation,
      ProFeature.themes,
    ]);
    expect(proBenefitTaste(), hasLength(4));
  });

  test(
    'copy says only what the app collects (no tips: no source for them)',
    () {
      final activity = kProBenefits.firstWhere(
        (b) => b.feature == ProFeature.activity,
      );
      expect(activity.body.toLowerCase(), isNot(contains('tip')));
    },
  );
}

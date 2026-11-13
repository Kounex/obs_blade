import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/pro/widgets/pro_benefits.dart';

/// One Pro story: six groups on the paywall, the same names in the same
/// order on the locked panes (minus the pane's own feature).
void main() {
  test('six groups, one per feature, remote access second', () {
    expect(kProBenefits.map((b) => b.feature), ProFeature.values);
    expect(kProBenefits.map((b) => b.title), [
      'Every Chat, One Place',
      'Control OBS From Anywhere',
      'Never Miss a Supporter',
      'Hear Your Chat',
      'Moderate From Your Pocket',
      'Your Own Themes',
    ]);
  });

  test('locked panes: the first four other groups, in order', () {
    expect(proBenefitTaste(except: ProFeature.chat).map((b) => b.feature), [
      ProFeature.remote,
      ProFeature.activity,
      ProFeature.speech,
      ProFeature.moderation,
    ]);
    expect(proBenefitTaste(except: ProFeature.activity).map((b) => b.feature), [
      ProFeature.chat,
      ProFeature.remote,
      ProFeature.speech,
      ProFeature.moderation,
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

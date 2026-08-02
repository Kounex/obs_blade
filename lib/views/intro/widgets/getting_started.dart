import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../shared/general/social_block.dart';
import '../../../shared/general/themed/rich_text.dart';
import '../../../utils/styling_helper.dart';
import '../intro.dart';
import 'intro_primary_button.dart';

class GettingStarted extends StatelessWidget {
  const GettingStarted({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseConstrainedBox(
      hasBasePadding: true,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StaggeredEntrance(
                  index: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Image.asset(
                      StylingHelper.brightnessAwareOBSLogo(context),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                StaggeredEntrance(
                  index: 1,
                  child: ThemedRichText(
                    textAlign: TextAlign.center,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    textSpans: [
                      const TextSpan(
                        text: 'An unofficial, ',
                      ),
                      WidgetSpan(
                        child: SocialBlock(
                          topPadding: 0,
                          bottomPadding: 0,
                          socialInfos: [
                            SocialEntry(
                              linkText: 'open source',
                              link: 'https://github.com/Kounex/obs_blade',
                              textStyle:
                                  Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' OBS controller to master your streams and recordings!\n\nMaking use of the beautiful, open source ',
                      ),
                      WidgetSpan(
                        child: SocialBlock(
                          topPadding: 0,
                          bottomPadding: 0,
                          socialInfos: [
                            SocialEntry(
                              linkText: 'WebSocket',
                              link:
                                  'https://github.com/obsproject/obs-websocket',
                              textStyle:
                                  Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(
                        text: ' plugin!',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Bottom-anchored CTA cluster - same anchoring as the intro
          /// slides' control row (safe area + base padding)
          StaggeredEntrance(
            index: 2,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom +
                    kIntroControlsBottomPadding,
              ),
              child: Column(
                children: [
                  const BaseDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  IntroPrimaryButton(
                    text: 'Start',
                    onPressed: () => GetIt.instance<IntroStore>()
                        .setStage(IntroStage.VersionSelection),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

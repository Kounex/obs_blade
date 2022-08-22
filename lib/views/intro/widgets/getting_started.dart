import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';
import 'package:obs_blade/stores/views/intro.dart';

import '../../../shared/general/social_block.dart';
import '../../../shared/general/themed/rich_text.dart';
import '../../../utils/styling_helper.dart';

class GettingStarted extends StatelessWidget {
  const GettingStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseConstrainedBox(
      hasBasePadding: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(flex: 1),
          Flexible(
            flex: 12,
            child: Column(
              children: [
                Fader(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Image.asset(
                      StylingHelper.brightnessAwareOBSLogo(context),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                Fader(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                  child: ThemedRichText(
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
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    fontSize: 18,
                                  ),
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
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(
                        text: ' plugin!',
                      ),
                    ],
                    textAlign: TextAlign.center,
                    textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontSize: 18,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Fader(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: Column(
                children: [
                  const BaseDivider(),
                  ThemedCupertinoButton(
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

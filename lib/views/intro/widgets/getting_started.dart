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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height / 12,
            left: 0,
            right: 0,
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
                        text:
                            'An unofficial OBS controller to master your streams and recordings!\n\nMaking use of the beautiful ',
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
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 92.0,
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

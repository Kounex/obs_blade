import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/shared/general/social_block.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';

class TipsContent extends StatelessWidget {
  const TipsContent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'If you enjoy OBS Blade and want to support the development, leaving a tip would mean a lot to me!',
        ),
        // const SizedBox(height: 12.0),
        const BaseDivider(
          height: 24.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Column(
              children: [
                SocialBlock(
                  socialInfos: [
                    SocialEntry(
                        icon: JamIcons.coffee,
                        link: 'https://www.buymeacoffee.com/Kounex',
                        linkText: 'Buy Me a Coffee'),
                    SocialEntry(
                        icon: JamIcons.paypal,
                        link: 'https://paypal.me/Kounex',
                        linkText: 'PayPal'),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

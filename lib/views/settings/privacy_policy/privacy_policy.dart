import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/social_block.dart';
import 'package:obs_blade/shared/general/themed/rich_text.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';

import '../../../shared/general/base/card.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Privacy Policy',
        listViewChildren: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.doc_person_fill,
                  size: 92.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
              ],
            ),
          ),
          BaseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ThemedRichText(
                  textSpans: [
                    TextSpan(
                      text: 'Currently ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text:
                          'OBS Blade does not collect and send any data to any kind of server on its own! The respective app stores (Google Play Store and Apple App Store) will collect analytics data about app usage, crashes, etc. but I\'m not collecting anything. If you want to know more about what those app stores collect, take a look at their privacy policies:',
                    ),
                  ],
                ),
                SocialBlock(
                  socialInfos: [
                    SocialEntry(
                      icon: JamIcons.google,
                      iconSize: 24.0,
                      link: 'https://policies.google.com/privacy',
                      linkText: 'Google Privacy Policy',
                    ),
                    SocialEntry(
                      icon: JamIcons.apple,
                      link: 'https://apple.com/legal/privacy/en-ww/',
                      linkText: 'Apple Privacy Policy',
                    ),
                  ],
                ),
                const Text(
                  'I might add third party providers later on to help me out with stuff like device-sync, error handling, feedback, statistics, etc. and if I do and this third party provider collects any personal data about you, I will add this to this privacy policy! Since data privacy is very important to me, I will try to be very strict about which third party I will work with.\n\nIf you have any concerns about your data or would like to help me improve in this regard, don\'t hesitate to contact me. You can visit the "About" page inside the app to see possible ways to get in touch me with. The preferred way to contact me for such things though is via email:',
                ),
                SocialBlock(
                  socialInfos: [
                    SocialEntry(
                      icon: CupertinoIcons.mail_solid,
                      iconSize: 24.0,
                      link: 'mailto:contact@kounex.com',
                      linkText: 'contact@kounex.com',
                    ),
                  ],
                ),
                const Text('Thanks for reading! :)')
              ],
            ),
          ),
        ],
      ),
    );
  }
}

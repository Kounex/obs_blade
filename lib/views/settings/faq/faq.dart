import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/faq/widgets/enumeration_block/enumeration_entry.dart';
import 'package:obs_blade/views/settings/faq/widgets/enumeration_block/enumeration_block.dart';
import 'package:obs_blade/views/settings/faq/widgets/faq_block.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/social_block.dart';
import '../../../shared/general/themed/themed_rich_text.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../utils/icons/jam_icons.dart';

class FAQView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'FAQ | Help',
        listViewChildren: [
          Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              right: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Icon(
                    CupertinoIcons.chat_bubble_text_fill,
                    size: 92.0,
                  ),
                ),
                SizedBox(width: 24.0),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Frequently Asked Questions',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BaseCard(
            paddingChild: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Since I received several questions and problems regarding using OBS Blade, I tried to compile some information here which might help others as well if they encounter problems or are not sure about some functions / possibilities.'),
                SizedBox(height: 12.0),
                Divider(height: 0),
                SizedBox(height: 12.0),
                FAQBlock(
                  heading: 'Autodiscover does not find my OBS instance, why?',
                  customBody: EnumerationBlock(
                    title:
                        'There are several things which have to be checked for that problem:',
                    customEntries: [
                      EnumerationEntry(
                        text:
                            'Make sure you are on the latest version of OBS, OBS WebSocket and OBS Blade',
                      ),
                      EnumerationEntry(
                        text:
                            'Your device using OBS Blade needs to be connected via WLAN and needs to be in the same network as the device running OBS',
                      ),
                      EnumerationEntry(
                        text:
                            'Additionally to being in the same network, they also have to be in the same IP range (subnet). By default, devices being in different subnets cannot communicate with each other. Make sure only the last digit of the IP address differ:',
                      ),
                      EnumerationEntry(
                        level: 2,
                        text:
                            '192.168.178.20 (OBS)\n192.168.120.90 (OBS Blade)\nwon\'t work!',
                      ),
                      EnumerationEntry(
                        level: 2,
                        text:
                            '192.168.178.20 (OBS)\n192.168.178.90 (OBS Blade)\nwill work!',
                      ),
                    ],
                  ),
                ),
                ThemedRichText(
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
                    ),
                    SocialEntry(
                      icon: JamIcons.apple,
                      link: 'https://apple.com/legal/privacy/en-ww/',
                    ),
                  ],
                ),
                Text(
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
                Text('Thanks for reading! :)')
              ],
            ),
          ),
        ],
      ),
    );
  }
}

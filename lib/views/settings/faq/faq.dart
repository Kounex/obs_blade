import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/enumeration_block/enumeration_block.dart';
import '../../../shared/general/enumeration_block/enumeration_entry.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import 'widgets/faq_block.dart';

const kFAQSpaceHeight = 24.0;

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
                            'The port where OBS is running is not opened. Your firewall might block this port or your router might not allow communicating with this port (port forwarding)',
                      ),
                      EnumerationEntry(
                        text:
                            'On iOS: make sure you enabled the "Local Network Permission" in your phone settings:\nSettings > Privacy > Local Network > OBS Blade',
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
                SizedBox(height: kFAQSpaceHeight),
                FAQBlock(
                  heading: 'I can\'t connect to OBS, what to do?',
                  customBody: EnumerationBlock(
                    title:
                        'In most cases you should be able to connect to OBS if it\'s listed in autodiscover. If you try to connect to OBS manually because it\'s not listed in autodiscover, there is usually an underlying problem (check the list above). Additionally check that:',
                    customEntries: [
                      EnumerationEntry(
                        text:
                            'The correct password is used (if set in the OBS WebSocket settings)',
                      ),
                      EnumerationEntry(
                        text:
                            'The host (device running OBS) is reachable with the given IP address. The internal IP address can only be used when both devices are in the same network and the previous points are covered',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: kFAQSpaceHeight),
                FAQBlock(
                  heading: 'When will feature XY be available?',
                  text:
                      'I have quite a backlog to work through - some stuff I want to implement in general and some have been requested by you! I dont\'t have a public board showcasing all the tasks currently (might be added in the future). Feel free to contact me for feature requests / bugs or check the GitHub page!',
                ),
                SizedBox(height: kFAQSpaceHeight),
                FAQBlock(
                  heading: 'I think I found a bug! What to do?',
                  text:
                      'This app does not have any bugs, they are all features of course... All jokes aside, feel free to contact me (check the About page for different ways) or check the GitHub page for issues - if your bug is not listed, please add a new issue! If it already exists, leave a thumbs up or a comment to emphasize it so I will focus on fixing it!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

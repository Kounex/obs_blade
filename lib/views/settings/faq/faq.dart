import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/base/divider.dart';
import '../../../shared/general/enumeration_block/enumeration_block.dart';
import '../../../shared/general/enumeration_block/enumeration_entry.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../widgets/accent_icon_tile.dart';
import '../widgets/subpage_header.dart';
import 'widgets/faq_block.dart';

class FAQView extends StatelessWidget {
  const FAQView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'FAQ | Help',
        listViewChildren: [
          const StaggeredEntrance(
            index: 0,
            child: Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: SubpageHeader(
                visual: AccentIconTile(
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  size: 64.0,
                  iconSize: 32.0,
                ),
                title: 'Frequently Asked Questions',
              ),
            ),
          ),
          const StaggeredEntrance(
            index: 1,
            child: BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Since I received several questions and problems regarding using OBS Blade, I tried to compile some information here which might help others as well if they encounter problems or are not sure about some functions / possibilities.',
                  ),
                  BaseDivider(height: 32),
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
                              'Your device using OBS Blade needs to be connected via WLAN and in the same network as the device running OBS',
                        ),
                        EnumerationEntry(
                          text:
                              'The port where OBS is running is not opened. Your firewall might block this port or your router might not allow communicating with this port',
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
                  SizedBox(height: AppSpacing.xxl),
                  FAQBlock(
                    heading: 'I can\'t connect to OBS, what to do?',
                    customBody: EnumerationBlock(
                      title:
                          'In most cases you should be able to connect to OBS if it\'s listed in autodiscover. If you try to connect to OBS manually because it\'s not listed in autodiscover, there is usually an underlying problem (check the list above). Additionally check that:',
                      entries: [
                        'Tools → WebSocket Server Settings → Enable WebSocket Server is checked',
                        'The correct password is used (copy it from Show Connect Info — OBS generates one by default)',
                        'You are using OBS Studio 28+ (built-in WebSocket v5). Legacy 4.x plugins are not supported',
                        'On Windows: set the PC network to Private and allow OBS through the firewall (port 4455 by default)',
                        'Nothing else is bound to the WebSocket port (some camera plugins also use 4455)',
                        'For Domain / remote mode prefer ws:// on the LAN; use wss:// only behind a TLS reverse proxy',
                        'The host is reachable with the given IP / hostname on the same network',
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  FAQBlock(
                    heading: 'When will feature XY be available?',
                    text:
                        'I have quite a backlog to work through - some stuff I want to implement in general and some have been requested by you! I dont\'t have a public board showcasing all the tasks currently (might be added in the future). Feel free to contact me for feature requests / bugs or check the GitHub page!',
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  FAQBlock(
                    heading: 'I think I found a bug! What to do?',
                    text:
                        'This app does not have any bugs, they are all features of course... All jokes aside, feel free to contact me (check the About page for different ways) or check the GitHub page for issues - if your bug is not listed, please add a new issue! If it already exists, leave a thumbs up or a comment to emphasize it so I will focus on fixing it!',
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

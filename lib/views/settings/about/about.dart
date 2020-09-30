import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/themed/themed_rich_text.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/social_block.dart';
import '../../../shared/general/themed/themed_cupertino_scaffold.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../utils/icons/jam_icons.dart';
import '../../../utils/modal_handler.dart';
import 'widgets/about_header/about_header.dart';
import 'widgets/license_modal/license_modal.dart';

class AboutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      body: Builder(
        builder: (context) => TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'About',
          listViewChildren: [
            Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Column(
                children: [
                  AboutHeader(),
                  // LightDivider(
                  //   height: 32.0,
                  // ),
                  BaseCard(
                    paddingChild: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Greetings!\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ThemedRichText(
                          textSpans: [
                            TextSpan(
                                text:
                                    'Hope you enjoy using OBS Blade. If you want to get in touch me with, you can visit those sites and message me. For now this is also the preferred way to let me know of any bugs / problems / feature requests. I will add some '),
                            TextSpan(
                              text: 'real',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' ways to do that in the future.'),
                          ],
                        ),
                        SocialBlock(
                          socialInfos: [
                            SocialEntry(
                              // svgPath: 'assets/svgs/twitter.svg',
                              icon: JamIcons.twitter,
                              link: 'https://twitter.com/Kounexx',
                              linkText: 'Twitter',
                            ),
                            SocialEntry(
                              // svgPath: 'assets/svgs/linkedin.svg',
                              icon: JamIcons.linkedin,
                              iconSize: 26.0,
                              link:
                                  'https://www.linkedin.com/in/ren%C3%A9-schramowski-a35342157/',
                              linkText: 'LinkedIn',
                            ),
                          ],
                        ),
                        Text(
                            'OBS Blade is open source which means you can take look behind the scenes and see the actual source code. I might need to hide some sensitive stuff like keys / tokens / credentials (obviously), but everything else should be accessible.'),
                        SocialBlock(
                          socialInfos: [
                            SocialEntry(
                              // svgPath: 'assets/svgs/twitter.svg',
                              icon: JamIcons.github,
                              link: 'https://github.com/Kounex/obs_blade',
                              linkText: 'GitHub',
                            ),
                          ],
                        ),
                        Text(
                            'This app (as in a lot of cases) started as a small passion project since I wanted to be able to control OBS on the fly without the need of any third party apps / devices. Sometimes I stream some stuff myself - gaming related - so if you want to drop by:'),
                        SocialBlock(
                          socialInfos: [
                            SocialEntry(
                              // svgPath: 'assets/svgs/twitter.svg',
                              icon: JamIcons.twitch,
                              link: 'https://www.twitch.tv/Kounex',
                              linkText: 'Twitch',
                            ),
                          ],
                        ),
                        Divider(height: 0),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 14.0, bottom: 8.0),
                          child: Text(
                              'For a short overview of the used libraries, you can take a look here:'),
                        ),
                        RaisedButton(
                          child: Text('Packages'),
                          onPressed: () =>
                              ModalHandler.showBaseCupertinoBottomSheet(
                            context: context,
                            modalWidgetBuilder: (context, scrollController) =>
                                LicenseModal(
                              scrollController: scrollController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // LightDivider(
                  //   height: 32.0,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

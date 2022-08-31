import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/modal_handler.dart';
import '../dialogs/info.dart';

const double kSocialEntryDefaultIconSize = 28.0;

class SocialEntry {
  final String link;
  final String? deepLink;
  final String? svgPath;
  final IconData? icon;
  final String? linkText;
  final double iconSize;
  final TextStyle? textStyle;

  SocialEntry({
    required this.link,
    this.deepLink,
    this.svgPath,
    this.icon,
    this.linkText,
    this.iconSize = 28.0,
    this.textStyle,
  }) : assert(svgPath == null && icon == null ||
            svgPath != null && icon == null ||
            svgPath == null && icon != null);
}

class SocialBlock extends StatelessWidget {
  final List<SocialEntry> socialInfos;
  final double topPadding;
  final double bottomPadding;

  SocialBlock({
    Key? key,
    required this.socialInfos,
    this.topPadding = 18.0,
    this.bottomPadding = 18.0,
  })  : assert(socialInfos.isNotEmpty),
        super(key: key);

  Future<void> _handleSocialTap(
      BuildContext context, SocialEntry social) async {
    try {
      if (social.deepLink != null &&
          await canLaunchUrl(Uri.parse(
            social.deepLink!,
          ))) {
        if (!await launchUrl(
          Uri.parse(social.deepLink!),
          mode: LaunchMode.externalApplication,
        )) {
          await launchUrl(
            Uri.parse(social.deepLink!),
          );
        }
      } else if (await canLaunchUrl(
        Uri.parse(social.link),
      )) {
        if (!await launchUrl(
          Uri.parse(social.link),
          mode: LaunchMode.externalApplication,
        )) {
          await launchUrl(
            Uri.parse(social.link),
          );
        }
      } else {
        throw 'Could not launch ${social.link}';
      }
    } catch (_) {
      ModalHandler.showBaseDialog(
        context: context,
        dialogWidget: InfoDialog(
          title: 'Couldn\'t open link',
          body:
              'Couldn\'t open the following link on this device:\n\n${social.link}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> socialEntries = [];

    for (var social in this.socialInfos) {
      socialEntries.add(
        GestureDetector(
          onTap: () => _handleSocialTap(context, social),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (social.icon != null || social.svgPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                      width: kSocialEntryDefaultIconSize >= social.iconSize
                          ? kSocialEntryDefaultIconSize
                          : social.iconSize,
                      child: social.icon != null
                          ? Icon(
                              social.icon,
                              size: social.iconSize,
                              color: Theme.of(context).iconTheme.color,
                            )
                          : Icon(
                              Icons.warning,
                              size: social.iconSize,
                              color: Theme.of(context).iconTheme.color,
                            )
                      // : SvgPicture.asset(
                      //     social.svgPath,
                      //     height: social.iconSize,
                      //     color: Theme.of(context).iconTheme.color,
                      //   ),
                      ),
                ),
              Flexible(
                child: Text(
                  social.linkText ?? social.link,
                  softWrap: true,
                  style: (social.textStyle ??
                          Theme.of(context).textTheme.bodyText1!)
                      .copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    // decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding:
          EdgeInsets.only(top: this.topPadding, bottom: this.bottomPadding),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: socialEntries,
      ),
    );
  }
}

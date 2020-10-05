import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

const double kSocialEntryDefaultIconSize = 28.0;

class SocialEntry {
  final String svgPath;
  final IconData icon;
  final String link;
  final String linkText;
  final double iconSize;

  SocialEntry({
    @required this.link,
    this.svgPath,
    this.icon,
    this.linkText,
    this.iconSize = 28.0,
  }) : assert(svgPath == null && icon == null ||
            svgPath != null && icon == null ||
            svgPath == null && icon != null);
}

class SocialBlock extends StatelessWidget {
  final List<SocialEntry> socialInfos;
  final double verticalPadding;

  SocialBlock({
    @required this.socialInfos,
    this.verticalPadding = 18.0,
  }) : assert(socialInfos != null && socialInfos.length > 0);

  Future<void> _handleSocialTap(SocialEntry social) async {
    if (await canLaunch(social.link)) {
      await launch(social.link);
    } else {
      throw 'Could not launch ${social.link}';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> socialEntries = [];

    this.socialInfos.forEach((social) {
      socialEntries.add(
        GestureDetector(
          onTap: () => _handleSocialTap(social),
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
                        : SvgPicture.asset(
                            social.svgPath,
                            height: social.iconSize,
                            color: Theme.of(context).iconTheme.color,
                          ),
                  ),
                ),
              Text(
                social.linkText ?? social.link,
                softWrap: true,
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Padding(
      padding: EdgeInsets.symmetric(vertical: this.verticalPadding),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: socialEntries,
      ),
    );
  }
}

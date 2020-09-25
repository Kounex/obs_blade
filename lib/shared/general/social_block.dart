import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialEntry {
  final String svgPath;
  final String link;
  final String linkText;
  final double logoSize;

  SocialEntry(
      {@required this.svgPath,
      @required this.link,
      this.linkText,
      this.logoSize = 32.0});
}

class SocialBlock extends StatelessWidget {
  final List<SocialEntry> socialInfos;

  SocialBlock({@required this.socialInfos})
      : assert(socialInfos != null && socialInfos.length > 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: this
          .socialInfos
          .map(
            (social) => GestureDetector(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 42.0,
                      child: SvgPicture.asset(
                        social.svgPath,
                        height: social.logoSize,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      social.linkText ?? social.link,
                      softWrap: true,
                      style: TextStyle(
                        color: Theme.of(context).accentColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

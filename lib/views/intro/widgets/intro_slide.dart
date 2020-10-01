import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/animator/fader.dart';
import '../../../shared/general/base_card.dart';
import '../intro.dart';

class IntroSlide extends StatelessWidget {
  final String imagePath;
  final String slideText;
  final bool showBetaCard;

  IntroSlide({
    @required this.imagePath,
    @required this.slideText,
    this.showBetaCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Fader(
      duration: Duration(milliseconds: 750),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).padding.bottom +
              kIntroControlsBottomPadding +
              32.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1.3,
              child: Transform.translate(
                offset: Offset(0.0, -MediaQuery.of(context).size.height * 0.05),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 3,
                  ),
                  child: Image.asset(this.imagePath),
                ),
              ),
            ),
            if (this.showBetaCard)
              BaseCard(
                bottomPadding: 12,
                backgroundColor:
                    Theme.of(context).cardColor.computeLuminance() <= 0.2
                        ? Colors.white24
                        : Colors.black26,
                paddingChild: EdgeInsets.all(12.0),
                child: Text(
                  'Beta Version!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6.copyWith(
                        color: CupertinoColors.destructiveRed,
                      ),
                ),
              ),
            BaseCard(
              topPadding: 0,
              bottomPadding: 0,
              backgroundColor:
                  Theme.of(context).cardColor.computeLuminance() <= 0.2
                      ? Colors.white24
                      : Colors.black26,
              paddingChild: EdgeInsets.all(12.0),
              child: Text(
                this.slideText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            )
          ],
        ),
      ),
    );
  }
}

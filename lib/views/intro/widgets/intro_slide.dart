import 'package:flutter/material.dart';
import '../../../shared/general/themed/rich_text.dart';

import '../../../shared/animator/fader.dart';
import '../../../shared/general/base/card.dart';
import '../intro.dart';

class IntroSlide extends StatelessWidget {
  final String imagePath;
  final List<InlineSpan> slideTextSpans;
  final Widget? additionalChild;

  const IntroSlide({
    Key? key,
    required this.imagePath,
    required this.slideTextSpans,
    this.additionalChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Fader(
      duration: const Duration(milliseconds: 750),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 32.0,
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).padding.bottom +
              kIntroControlsBottomPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: Image.asset(this.imagePath),
            ),
            SizedBox(
              height: 275.0,
              child: BaseCard(
                backgroundColor: Colors.transparent,
                paddingChild: const EdgeInsets.all(0),
                centerChild: false,
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 32.0),
                    ThemedRichText(
                      textSpans: this.slideTextSpans,
                      textAlign: TextAlign.justify,
                      textStyle: Theme.of(context).textTheme.headline6,
                    ),
                    if (this.additionalChild != null) this.additionalChild!,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../shared/animator/fader.dart';
import '../../intro.dart';

class IntroSlide extends StatelessWidget {
  final String imagePath;
  final Widget child;

  const IntroSlide({
    super.key,
    required this.imagePath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Fader(
      duration: const Duration(milliseconds: 750),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: kIntroControlsBottomPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(this.imagePath),
              ),
            ),
            this.child,
          ],
        ),
      ),
    );
    // return Fader(
    //   duration: const Duration(milliseconds: 750),
    //   child: Padding(
    //     padding: EdgeInsets.only(
    //       top: MediaQuery.paddingOf(context).top + 32.0,
    //       left: 24.0,
    //       right: 24.0,
    //       bottom: MediaQuery.paddingOf(context).bottom +
    //           kIntroControlsBottomPadding,
    //     ),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         SizedBox(
    //           height: MediaQuery.sizeOf(context).height / 3,
    //           child: Image.asset(this.imagePath),
    //         ),
    //         SizedBox(
    //           height: 275.0,
    //           child: BaseCard(
    //             backgroundColor: Colors.transparent,
    //             paddingChild: const EdgeInsets.all(0),
    //             centerChild: false,
    //             child: Column(
    //               children: [
    //                 const Divider(),
    //                 const SizedBox(height: 32.0),
    //                 ThemedRichText(
    //                   textSpans: this.slideTextSpans,
    //                   textAlign: TextAlign.justify,
    //                   textStyle: Theme.of(context).textTheme.headline6,
    //                 ),
    //                 if (this.additionalChild != null) this.additionalChild!,
    //               ],
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}

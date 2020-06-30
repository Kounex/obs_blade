import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

class AboutView extends StatelessWidget {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('About'),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        color: Colors.yellow,
        child: ListView.builder(
          controller: controller,
          itemBuilder: (c, i) => i == 10
              ? Container(
                  height: 150,
                  color: Colors.red,
                  child: NotificationListener<OverscrollNotification>(
                    onNotification: (value) {
                      if ((controller.offset <=
                                      controller.position.minScrollExtent &&
                                  value.overscroll < 0 ||
                              controller.offset >=
                                      controller.position.maxScrollExtent &&
                                  value.overscroll > 0) &&
                          value.overscroll.abs() > 20.0) {
                        double damper = 1;
                        if (controller.offset != 0) {
                          damper = controller.offset.abs() /
                              (controller.offset.abs() * 2);
                        }
                        controller.jumpTo(
                            controller.offset + value.overscroll * damper);
                      } else if (value.overscroll.abs() > 20.0) {
                        controller.jumpTo(controller.offset + value.overscroll);
                      }
                      return true;
                    },
                    child: ListView.builder(
                      physics: ClampingScrollPhysics(),
                      itemBuilder: (c, ii) => Text('-->' + ii.toString()),
                      itemCount: 20,
                    ),
                  ),
                )
              : Text(i.toString()),
          itemCount: 35,
        ),
      ),
    );
  }
}

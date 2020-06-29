import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                    onNotification: (OverscrollNotification value) {
                      if (value.overscroll < 0 &&
                          controller.offset + value.overscroll <= 0) {
                        controller.jumpTo(controller.offset + value.overscroll);
                        return true;
                      }
                      if (controller.offset + value.overscroll >=
                          controller.position.maxScrollExtent) {
                        controller.jumpTo(controller.position.maxScrollExtent);
                        return true;
                      }
                      controller.jumpTo(controller.offset + value.overscroll);
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
          itemCount: 45,
        ),
      ),
    );
  }
}

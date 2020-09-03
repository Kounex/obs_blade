import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../models/connection.dart';
import '../../../../types/enums/hive_keys.dart';
import 'connection_box.dart';
import 'placeholder_connection.dart';

class SavedConnections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 24.0),
          child: Text(
            'Saved Connections',
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        Divider(),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 18.0,
            ),
            child: ValueListenableBuilder(
              valueListenable:
                  Hive.box<Connection>(HiveKeys.SavedConnections.name)
                      .listenable(),
              builder: (context, Box<Connection> savedConnectionsBox, child) {
                double height = 180.0;
                double width = 250.0;

                if (savedConnectionsBox.values.length == 0) {
                  return PlaceholderConnection(
                    height: height,
                    width: width,
                  );
                } else {
                  List<Widget> connectionBoxes = savedConnectionsBox.values
                      .map(
                        (savedConnection) => ConnectionBox(
                          connection: savedConnection,
                          width: width,
                          height: height,
                        ),
                      )
                      .toList();
                  return MediaQuery.of(context).size.width < width * 2.5
                      ? SizedBox(
                          height: height,
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.75),
                            itemCount: connectionBoxes.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(
                                  left: 18.0, right: 18.0),
                              child: connectionBoxes[index],
                            ),
                          ),
                        )
                      : Center(
                          child: Wrap(
                            spacing: 32.0,
                            runSpacing: 32.0,
                            children: connectionBoxes,
                          ),
                        );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

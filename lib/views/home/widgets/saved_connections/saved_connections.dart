import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../models/connection.dart';
import '../../../../types/enums/hive_keys.dart';
import 'connection_box.dart';

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
                  Hive.box<Connection>(HiveKeys.SAVED_CONNECTIONS.name)
                      .listenable(),
              builder: (context, Box<Connection> savedConnectionsBox, child) {
                double height = 175.0;
                double width = 250.0;
                List<Widget> connectionBoxes = savedConnectionsBox.values
                    .map(
                      (savedConnection) => ConnectionBox(
                        connection: savedConnection,
                        width: width,
                      ),
                    )
                    .toList();
                // return SizedBox(
                //   height: height,
                //   child: RotatedBox(
                //     quarterTurns: 3,
                //     child: ListWheelScrollView(
                //       clipToSize: false,
                //       squeeze: 0.9,
                //       diameterRatio: 1000.0,
                //       itemExtent: width,
                //       physics: FixedExtentScrollPhysics(),
                //       children: box.values
                //           .map(
                //             (savedConnection) => RotatedBox(
                //               quarterTurns: 1,
                //               child: ConnectionBox(
                //                 connection: savedConnection,
                //                 width: width,
                //               ),
                //             ),
                //           )
                //           .toList(),
                //     ),
                //   ),
                // );

                return MediaQuery.of(context).size.width < width * 2
                    ? CarouselSlider(
                        options: CarouselOptions(
                          height: height,
                          autoPlay: false,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          viewportFraction: width /
                              (MediaQuery.of(context).size.width -
                                  MediaQuery.of(context).size.width / 10),
                        ),
                        items: connectionBoxes,
                      )
                    : Center(
                        child: Wrap(
                          spacing: 24.0,
                          runSpacing: 24.0,
                          children: connectionBoxes,
                        ),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }
}

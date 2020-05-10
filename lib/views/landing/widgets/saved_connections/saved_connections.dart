import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_station/views/landing/widgets/saved_connections/connection_box.dart';

class SavedConnections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Container(
            padding: EdgeInsets.only(top: 4.0, bottom: 12.0),
            child: ValueListenableBuilder(
              valueListenable:
                  Hive.box<Connection>(HiveKeys.SAVED_CONNECTIONS.name)
                      .listenable(),
              builder: (context, Box<Connection> box, child) {
                double height = 175.0;
                double width = 250.0;
                return CarouselSlider(
                  key: UniqueKey(),
                  options: CarouselOptions(
                    height: height,
                    autoPlay: false,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    viewportFraction: width / MediaQuery.of(context).size.width,
                  ),
                  items: box.values
                      .map(
                        (savedConnection) => ConnectionBox(
                          connection: savedConnection,
                          width: width,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

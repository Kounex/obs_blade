import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/basic/base_card.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:obs_station/views/landing/widgets/saved_connections/widgets/connection_box/connection_box.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavedConnections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseCard(
      noPaddingChild: true,
      child: Column(
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
          Container(
            padding: EdgeInsets.only(top: 4.0, bottom: 12.0),
            height: 150.0,
            child: SizedBox.expand(
              child: ValueListenableBuilder(
                valueListenable:
                    Hive.box<Connection>(HiveKeys.SAVED_CONNECTIONS.name)
                        .listenable(),
                builder: (context, Box<Connection> box, child) =>
                    CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: false,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    viewportFraction: 6 / 10,
                  ),
                  items: box.values
                      .map(
                        (savedConnection) =>
                            ConnectionBox(connection: savedConnection),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

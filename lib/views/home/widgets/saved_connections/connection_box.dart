import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/basic/status_dot.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/views/home/widgets/saved_connections/edit_dialog.dart';
import 'package:provider/provider.dart';

class ConnectionBox extends StatelessWidget {
  final Connection connection;
  final double height;
  final double width;

  ConnectionBox(
      {@required this.connection, this.height = 200.0, this.width = 250.0});

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);
    LandingStore landingStore = Provider.of<LandingStore>(context);

    return Container(
      width: this.width,
      height: this.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                if (this.connection.name != null)
                  Text(
                    this.connection.name,
                    style: Theme.of(context).textTheme.headline6,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                Text(
                  '(${this.connection.ssid})',
                  style: Theme.of(context).textTheme.caption,
                ),
                Text(
                  '(${this.connection.ip})',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
            Observer(
              builder: (_) => FutureBuilder<List<Connection>>(
                future: landingStore.autodiscoverConnections,
                builder: (context, snapshot) {
                  bool reachable = snapshot.hasData &&
                      snapshot.data.any((discoverConnection) =>
                          discoverConnection.ip == this.connection.ip &&
                          discoverConnection.port == this.connection.port);
                  return Center(
                    child: StatusDot(
                      color: reachable ? Colors.green : Colors.red,
                      text: reachable ? 'Reachable' : 'Not reachable',
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RaisedButton(
                    child: Text('Connect'),
                    onPressed: () {
                      networkStore.setOBSWebSocket(this.connection);
                    }),
                IconButton(
                  icon: Icon(CupertinoIcons.pencil),
                  onPressed: () => showCupertinoDialog(
                    context: context,
                    builder: (context) =>
                        EditConnectionDialog(connection: this.connection),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

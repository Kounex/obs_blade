import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/shared/basic/status_dot.dart';
import 'package:obs_station/stores/shared/network.dart';
import 'package:obs_station/stores/views/landing.dart';
import 'package:obs_station/views/landing/widgets/saved_connections/edit_dialog.dart';
import 'package:provider/provider.dart';

class ConnectionBox extends StatelessWidget {
  final Connection connection;

  ConnectionBox({@required this.connection});

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = Provider.of<NetworkStore>(context);
    LandingStore landingStore = Provider.of<LandingStore>(context);

    return Container(
      width: 250.0,
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
                  '(${this.connection.ip})',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
            Observer(
              builder: (_) => FutureBuilder<List<Connection>>(
                future: landingStore.autodiscoverConnections,
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: snapshot.hasData &&
                                snapshot.data.any((discoverConnection) =>
                                    discoverConnection.ip ==
                                        this.connection.ip &&
                                    discoverConnection.port ==
                                        this.connection.port)
                            ? [
                                StatusDot(color: Colors.green),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Reachable',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                )
                              ]
                            : [
                                StatusDot(),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Not reachable',
                                    style:
                                        Theme.of(context).textTheme.bodyText1,
                                  ),
                                )
                              ],
                      ),
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

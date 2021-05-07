import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../models/connection.dart';
import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/general/base_card.dart';
import '../../../../stores/shared/network.dart';
import 'edit_dialog.dart';

class ConnectionBox extends StatelessWidget {
  final Connection connection;
  final double height;
  final double width;

  ConnectionBox(
      {required this.connection, this.height = 200.0, this.width = 250.0});

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return SizedBox(
      width: this.width,
      child: BaseCard(
        topPadding: 0.0,
        rightPadding: 0.0,
        bottomPadding: 0.0,
        leftPadding: 0.0,
        paddingChild: EdgeInsets.all(0),
        child: SizedBox(
          height: this.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  if (this.connection.name != null)
                    Text(
                      this.connection.name!,
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  // Text(
                  //   '(${this.connection.ssid})',
                  //   style: Theme.of(context).textTheme.caption,
                  // ),
                  Text(
                    '(${this.connection.ip})',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              Center(
                child: StatusDot(
                  color: this.connection.reachable!
                      ? Colors.green
                      : CupertinoColors.destructiveRed,
                  text: this.connection.reachable!
                      ? 'Reachable'
                      : 'Not reachable',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                      child: Text('Connect'),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        networkStore.setOBSWebSocket(this.connection);
                      }),
                  IconButton(
                    icon: Icon(Icons.edit),
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
      ),
    );
  }
}

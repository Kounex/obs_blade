import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/models/connection.dart';
import 'package:obs_station/utils/network_helper.dart';
import 'package:obs_station/utils/styling_helper.dart';

class SessionTile extends StatelessWidget {
  final Connection connection;

  SessionTile({@required this.connection});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        StylingHelper.CUPERTINO_MACBOOK_ICON,
      ),
      title: Text(this.connection.ip),
      trailing: Icon(CupertinoIcons.right_chevron),
      onTap: () => NetworkHelper.establishWebSocket(this.connection),
    );
  }
}

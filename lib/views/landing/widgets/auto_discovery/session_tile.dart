import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/utils/network_helper.dart';

class SessionTile extends StatelessWidget {
  final String ip;

  SessionTile({@required this.ip});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        const IconData(0xf390,
            fontFamily: CupertinoIcons.iconFont,
            fontPackage: CupertinoIcons.iconFontPackage),
      ),
      title: Text(this.ip),
      trailing: Icon(CupertinoIcons.right_chevron),
      onTap: () => NetworkHelper.establishWebSocket(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/utils/routing_helper.dart';

class StreamEntry extends StatelessWidget {
  final PastStreamData pastStreamData;

  StreamEntry({@required this.pastStreamData});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.pushNamed(
          context, StaticticsTabRoutingKeys.Detail.route,
          arguments: this.pastStreamData),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      title: Text('Unnamed stream'),
      subtitle: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 45.0,
                child: Text('From: '),
              ),
              Text(
                  '${DateFormat.yMd('de_DE').format(DateTime.fromMillisecondsSinceEpoch(this.pastStreamData.streamEndedMS - this.pastStreamData.totalStreamTime * 1000))}'),
              Text(' - '),
              Text(
                  '${DateFormat.Hms('en_US').format(DateTime.fromMillisecondsSinceEpoch(this.pastStreamData.streamEndedMS - this.pastStreamData.totalStreamTime * 1000))}'),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 45.0,
                child: Text('To: '),
              ),
              Text(
                  '${DateFormat.yMd('de_DE').format(DateTime.fromMillisecondsSinceEpoch(this.pastStreamData.streamEndedMS))}'),
              Text(' - '),
              Text(
                  '${DateFormat.Hms('en_US').format(DateTime.fromMillisecondsSinceEpoch(this.pastStreamData.streamEndedMS))}'),
            ],
          ),
        ],
      ),
    );
  }
}

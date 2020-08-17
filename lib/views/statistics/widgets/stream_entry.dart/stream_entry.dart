import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StreamEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
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
                  '${DateFormat.yMd('de_DE').format(DateTime.fromMillisecondsSinceEpoch(1597661113942))}'),
              Text(' - '),
              Text(
                  '${DateFormat.Hms('en_US').format(DateTime.fromMillisecondsSinceEpoch(1597661113942))}'),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 45.0,
                child: Text('To: '),
              ),
              Text(
                  '${DateFormat.yMd('de_DE').format(DateTime.fromMillisecondsSinceEpoch(1597677813942))}'),
              Text(' - '),
              Text(
                  '${DateFormat.Hms('en_US').format(DateTime.fromMillisecondsSinceEpoch(1597677813942))}'),
            ],
          ),
        ],
      ),
    );
  }
}

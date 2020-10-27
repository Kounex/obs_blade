import 'package:flutter/material.dart';

import '../../../models/past_stream_data.dart';
import 'stream_entry.dart';

class PaginatedStatistics extends StatefulWidget {
  final List<PastStreamData> filteredAndSortedStreamData;

  PaginatedStatistics({@required this.filteredAndSortedStreamData});

  @override
  _PaginatedStatisticsState createState() => _PaginatedStatisticsState();
}

class _PaginatedStatisticsState extends State<PaginatedStatistics> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => StreamEntry(
            pastStreamData: widget.filteredAndSortedStreamData[index]),
        separatorBuilder: (context, index) => Divider(height: 0),
        itemCount: widget.filteredAndSortedStreamData.length);
    return Column(
      children: [
        ...this.widget.filteredAndSortedStreamData.map(
              (pastStreamData) => Column(
                children: [
                  StreamEntry(pastStreamData: pastStreamData),
                  Divider(
                    height: 0.0,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

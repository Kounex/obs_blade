// Create new instances of this class in each test.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:obs_station/models/past_stream_data.dart';
import 'package:obs_station/models/stream_stats.dart';

import '../mocks/stream_stats.dart';

class MockPastStream extends Mock implements PastStreamData {}

main() {
  group('PastStream use cases', () {
    test('finish up PastStream to see if properties apply', () async {
      PastStreamData pastStreamData = PastStreamData();

      pastStreamData.addStreamStats(StreamStatsMocker.random());
      pastStreamData.finishUpStats();

      expect(pastStreamData.averageFrameTime, isNotNull);
    });

    test(
        'lists should contain the following amount: (AmountStreamStats ~/ kAmountStreamStatsForAverage)',
        () async {
      int amountStreamStats = 563;
      PastStreamData pastStreamData = PastStreamData();
      List<StreamStats> streamStatsList = [];

      List.generate(amountStreamStats, (index) {
        streamStatsList.add(StreamStatsMocker.random());
        pastStreamData.addStreamStats(streamStatsList.last);
      });

      pastStreamData.finishUpStats();

      expect(pastStreamData.fpsList.length,
          amountStreamStats ~/ kAmountStreamStatsForAverage);
    });

    test(
        'lists should contain worst value of a full cache list (kAmountStreamStatsForAverage)',
        () async {
      PastStreamData pastStreamData = PastStreamData();
      List<StreamStats> streamStatsList = [];

      List.generate(11, (index) {
        streamStatsList.add(StreamStatsMocker.random());
        pastStreamData.addStreamStats(streamStatsList.last);
      });
      streamStatsList.removeLast();

      pastStreamData.finishUpStats();

      expect(
          pastStreamData.fpsList.first,
          streamStatsList
              .reduce(
                  (value, element) => value..fps = min(value.fps, element.fps))
              .fps);
    });
  });
}

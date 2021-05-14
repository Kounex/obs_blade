import 'package:intl/intl.dart';

extension IntStuff on int {
  String secondsToFormattedDurationString() {
    String streamTimeHours = (this ~/ 3600).toString();
    String streamTimeMinutes = ((this ~/ 60) % 60).toString();
    String streamTimeSeconds = (this % 60).toString();
    return '$streamTimeHours:${(streamTimeMinutes.length == 1 ? '0' : '') + streamTimeMinutes}:${(streamTimeSeconds.length == 1 ? '0' : '') + streamTimeSeconds}';
  }

  String millisecondsToFormattedDateString() =>
      DateFormat.yMd('de_DE').format(DateTime.fromMillisecondsSinceEpoch(this));

  String millisecondsToFormattedTimeString([bool withoutSeconds = false]) =>
      (withoutSeconds ? DateFormat.Hm('de_DE') : DateFormat.Hms('de_DE'))
          .format(DateTime.fromMillisecondsSinceEpoch(this));

  String millisecondsToFileNameDate() {
    DateTime now = DateTime.fromMillisecondsSinceEpoch(this);
    String month = (now.month < 10 ? '0' : '') + now.month.toString();
    String day = (now.day < 10 ? '0' : '') + now.day.toString();
    return '${now.year}$month$day';
  }

  bool millisecondsSameDay(int ms) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(this);
    DateTime otherDate = DateTime.fromMillisecondsSinceEpoch(ms);

    return date.day == otherDate.day &&
        date.month == otherDate.month &&
        date.year == otherDate.year;
  }
}

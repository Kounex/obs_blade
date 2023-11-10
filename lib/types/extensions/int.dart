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

  String millisecondsToFileNameDate(
      {String separator = '', bool withTime = false}) {
    DateTime now = DateTime.fromMillisecondsSinceEpoch(this);

    String month = (now.month < 10 ? '0' : '') + now.month.toString();
    String day = (now.day < 10 ? '0' : '') + now.day.toString();

    if (!withTime) {
      return '${now.year}$separator$month$separator$day';
    }

    String hour = (now.hour < 10 ? '0' : '') + now.hour.toString();
    String minute = (now.minute < 10 ? '0' : '') + now.minute.toString();
    String second = (now.second < 10 ? '0' : '') + now.second.toString();

    return '${now.year}$separator$month$separator$day $hour$separator$minute$separator$second';
  }

  bool millisecondsSameDay(int ms) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(this);
    DateTime otherDate = DateTime.fromMillisecondsSinceEpoch(ms);

    return date.day == otherDate.day &&
        date.month == otherDate.month &&
        date.year == otherDate.year;
  }
}

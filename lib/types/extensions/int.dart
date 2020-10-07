extension IntStuff on int {
  String secondsToFormattedTimeString() {
    String streamTimeHours = (this ~/ 3600).toString();
    String streamTimeMinutes = ((this ~/ 60) % 60).toString();
    String streamTimeSeconds = (this % 60).toString();
    return '$streamTimeHours:${(streamTimeMinutes.length == 1 ? '0' : '') + streamTimeMinutes}:${(streamTimeSeconds.length == 1 ? '0' : '') + streamTimeSeconds}';
  }
}

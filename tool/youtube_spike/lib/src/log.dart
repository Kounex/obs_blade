/// Timestamped single-line logger shared by the spike modes.
void log(String message) {
  final now = DateTime.now().toIso8601String();
  // ignore: avoid_print
  print('[$now] $message');
}

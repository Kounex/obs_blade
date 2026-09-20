/// Compact "x ago" rendering for decorative metadata stamps like the
/// saved-connection "Last used" line. Fixed English, no intl - the label
/// never drives logic.
String relativeTimeAgo(DateTime then, {DateTime? now}) {
  final Duration diff = (now ?? DateTime.now()).difference(then);
  if (diff.isNegative || diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  final String day = then.day.toString().padLeft(2, '0');
  final String month = then.month.toString().padLeft(2, '0');
  return '$day.$month.${then.year}';
}

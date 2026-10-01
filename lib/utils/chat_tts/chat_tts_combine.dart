import 'chat_tts_phrases.dart';
import 'chat_tts_queue.dart';

/// Most names read for a combined line - the rest become "N others"
const int kChatTtsCombineMaxNames = 3;

/// One line for a [group] of identical short messages (first one first):
/// - usernames off: "KEKW 15 times"
/// - one person repeating: "Viewer: KEKW 5 times"
/// - several people: the first author plus highlighted users / mods / the
///   streamer among them (up to [kChatTtsCombineMaxNames] names), the rest
///   counted - "Viewer, ModName and 13 others: KEKW"
String chatTtsCombinedLine(
  List<ChatTtsQueueItem> group, {
  required bool readUsernames,
  required ChatTtsPhrases phrases,
}) {
  final first = group.first;
  final String body = first.detectionText ?? first.text;
  if (!readUsernames) return '$body ${phrases.times(group.length)}';

  final List<String> authors = [];
  final Set<String> notable = {};
  for (final item in group) {
    final author = item.author ?? '';
    if (!authors.contains(author)) authors.add(author);
    if (item.notable) notable.add(author);
  }
  if (authors.length == 1) {
    return '${authors.single}: $body ${phrases.times(group.length)}';
  }

  final List<String> names = [authors.first];
  for (final author in authors.skip(1)) {
    if (names.length >= kChatTtsCombineMaxNames) break;
    if (notable.contains(author)) names.add(author);
  }
  return '${phrases.names(names, authors.length - names.length)}: $body';
}

import '../../models/enums/chat_type.dart';
import '../chat_highlight_helper.dart';
import '../chat_mute_helper.dart';
import 'chat_tts_phrases.dart';

/// Who text-to-speech reads out loud
enum ChatTtsAudience {
  /// Every message (minus the skip rules)
  everyone,

  /// Highlighted users, moderators and the broadcaster - plus anything
  /// that mentions you
  highlightedAndMods,

  /// Only messages that mention you or match a highlight keyword
  mentions;

  static ChatTtsAudience parse(Object? raw) => ChatTtsAudience.values
      .firstWhere((value) => value.name == raw, orElse: () => everyone);
}

/// One piece of a chat message as the platforms deliver it: text, or a
/// first-party emote (Twitch fragment, Kick `[emote:…]` token)
class ChatTtsPart {
  final String text;
  final bool isEmote;

  const ChatTtsPart.text(this.text) : isEmote = false;

  const ChatTtsPart.emote(this.text) : isEmote = true;
}

/// A live chat message from any native engine, reduced to what
/// text-to-speech needs
class ChatTtsMessage {
  final String id;
  final ChatType platform;

  /// Name read out loud
  final String author;

  /// Every name the author goes by (login, display name) - matched against
  /// the highlighted / ignored user lists
  final List<String?> authorNames;
  final List<ChatTtsPart> parts;
  final bool isModerator;
  final bool isBroadcaster;

  /// Sent by the signed-in account (own echo)
  final bool isOwn;

  /// The signed-in account's names on this platform - mention matching
  final List<String?> selfNames;

  /// Third-party emote check for a single word (7TV / BTTV / FFZ) - these
  /// arrive as plain text
  final bool Function(String word) isThirdPartyEmote;

  final DateTime receivedAt;

  ChatTtsMessage({
    required this.id,
    required this.platform,
    required this.author,
    required this.authorNames,
    required this.parts,
    this.isModerator = false,
    this.isBroadcaster = false,
    this.isOwn = false,
    this.selfNames = const [],
    bool Function(String word)? isThirdPartyEmote,
    DateTime? receivedAt,
  }) : isThirdPartyEmote = isThirdPartyEmote ?? _noEmote,
       receivedAt = receivedAt ?? DateTime.now();

  static bool _noEmote(String word) => false;

  /// The message as one plain string (emotes by name)
  String get plainText => this.parts.map((part) => part.text).join();
}

/// What gets read and how - mirrors the TTS settings sheet
class ChatTtsSettings {
  final ChatTtsAudience audience;
  final bool readUsernames;
  final bool skipEmotes;
  final bool skipLinks;
  final bool skipCommands;
  final bool readOwnMessages;

  /// Characters per message, cut at a word boundary - 0 = no limit
  final int maxLength;

  /// Drop messages with nothing but emotes (only matters while emotes are
  /// read - skipped emotes leave such messages empty anyway)
  final bool skipEmoteOnly;

  /// The filler words TTS adds ("5 times"), in the voice's language
  final ChatTtsPhrases phrases;

  const ChatTtsSettings({
    this.audience = ChatTtsAudience.everyone,
    this.readUsernames = true,
    this.skipEmotes = true,
    this.skipLinks = true,
    this.skipCommands = true,
    this.readOwnMessages = false,
    this.maxLength = kChatTtsDefaultMaxLength,
    this.skipEmoteOnly = false,
    this.phrases = ChatTtsPhrases.english,
  });
}

const int kChatTtsDefaultMaxLength = 150;

/// The chat-wide filters TTS honours like the timeline does (see
/// `ChatFilterSettings`) plus the highlight inputs for the audience rule
class ChatTtsFilters {
  final List<String> muteWords;
  final bool muteReplace;
  final Set<String> highlightUsers;
  final Set<String> ignoredUsers;
  final bool selfMentionEnabled;
  final List<String> keywords;

  const ChatTtsFilters({
    this.muteWords = const [],
    this.muteReplace = false,
    this.highlightUsers = const {},
    this.ignoredUsers = const {},
    this.selfMentionEnabled = true,
    this.keywords = const [],
  });
}

final RegExp _kWhitespace = RegExp(r'\s+');

/// http(s)://…, www.…, or a bare domain with a path / common TLD
final RegExp _kLink = RegExp(
  r'^(https?://|www\.)\S+$|^[\w-]+(\.[\w-]+)*\.(com|net|org|tv|gg|io|ly|me|co|de|uk|be|app|live|link)(/\S*)?$',
  caseSensitive: false,
);

/// YouTube custom emoji shortcodes (`:hand-pink-waving:`)
final RegExp _kShortcode = RegExp(r'^:[\w-]+:$');

/// Spam runs ("aaaaaaaa", "!!!!!!") - 4+ of the same character. Digits
/// stay: "10000 bits" must not turn into "1000"
final RegExp _kCharRun = RegExp(r'(\D)\1{3,}');

/// A run of this many identical words ("KEKW KEKW KEKW") is read once with
/// a count - two stay ("no no" is just speech)
const int kChatTtsWordRunMin = 3;

/// Messages up to this many words can be combined with identical ones
/// waiting in the queue (emote waves, "W", "gg")
const int kChatTtsCombineMaxWords = 3;

/// [words] with every run of [kChatTtsWordRunMin]+ identical words
/// (case-insensitive) replaced by the word plus "N times"
List<String> collapseChatTtsWordRuns(
  List<String> words,
  ChatTtsPhrases phrases,
) {
  final List<String> collapsed = [];
  var i = 0;
  while (i < words.length) {
    var j = i + 1;
    final lower = words[i].toLowerCase();
    while (j < words.length && words[j].toLowerCase() == lower) {
      j++;
    }
    final run = j - i;
    if (run >= kChatTtsWordRunMin) {
      collapsed.add('${words[i]} ${phrases.times(run)}');
    } else {
      collapsed.addAll(words.sublist(i, j));
    }
    i = j;
  }
  return collapsed;
}

/// The text TTS speaks for [message], or null when it's skipped. Applies,
/// in order: own messages, ignored users / mute words (same as the
/// timeline), the audience, `!commands`, then builds the text without
/// emotes / links, collapses spam runs and cuts it to the max length.
String? chatTtsUtterance(
  ChatTtsMessage message,
  ChatTtsSettings settings,
  ChatTtsFilters filters,
) => chatTtsSpoken(message, settings, filters)?.text;

/// What TTS reads for one message: [text] is spoken, [body] is the message
/// alone (no username) - language detection looks at that. [author] and
/// [notable] (highlighted user, mod, streamer) name people when identical
/// messages get combined; [combineKey] is set for short messages that may
/// be combined (null = never). A combined line reads [combineText] and
/// counts [repeats] per message: a message that is one word repeated
/// ("KEKW KEKW KEKW") combines as that word, 3 times - never as "KEKW 3
/// times" counted again.
typedef ChatTtsSpoken = ({
  String text,
  String body,
  String author,
  bool notable,
  String? combineKey,
  String combineText,
  int repeats,
});

/// [chatTtsUtterance] plus the bare message body for language detection
ChatTtsSpoken? chatTtsSpoken(
  ChatTtsMessage message,
  ChatTtsSettings settings,
  ChatTtsFilters filters,
) {
  if (message.isOwn && !settings.readOwnMessages) return null;

  final String plain = message.plainText;
  if (chatAuthorInList(filters.ignoredUsers, message.authorNames)) {
    return null;
  }
  final bool muted = chatContentIsMuted(plain, filters.muteWords);
  if (muted && !filters.muteReplace) return null;

  final bool mentionsMe = chatContentIsHighlighted(
    plain,
    selfMentionEnabled: filters.selfMentionEnabled,
    selfNames: message.selfNames,
    keywords: filters.keywords,
  );
  switch (settings.audience) {
    case ChatTtsAudience.everyone:
      break;
    case ChatTtsAudience.highlightedAndMods:
      if (!mentionsMe &&
          !message.isModerator &&
          !message.isBroadcaster &&
          !chatAuthorInList(filters.highlightUsers, message.authorNames)) {
        return null;
      }
    case ChatTtsAudience.mentions:
      if (!mentionsMe) return null;
  }

  if (settings.skipCommands && plain.trimLeft().startsWith('!')) return null;

  List<String> words = [];
  var hasText = false;
  for (final part in message.parts) {
    if (part.isEmote) {
      if (!settings.skipEmotes) words.add(part.text);
      continue;
    }
    for (final word in part.text.split(_kWhitespace)) {
      if (word.isEmpty) continue;
      final bool emote =
          message.isThirdPartyEmote(word) || _kShortcode.hasMatch(word);
      if (emote && settings.skipEmotes) continue;
      if (settings.skipLinks && _kLink.hasMatch(word)) continue;
      if (!emote) hasText = true;
      words.add(word);
    }
  }
  if (settings.skipEmoteOnly && !hasText) return null;
  final List<String> uncollapsed = words;
  words = collapseChatTtsWordRuns(words, settings.phrases);

  /// After the collapse: "KEKW KEKW KEKW KEKW" is one entry
  final int wordCount = words.length;
  final bool collapsed = words.length != uncollapsed.length;

  /// The whole message is one word repeated - combined as that word
  final bool singleRun = collapsed && wordCount == 1;

  String text = words.join(' ');
  if (muted) {
    /// Censor mode: the matches aren't read at all
    text = censorChatContent(
      text,
      filters.muteWords,
    ).replaceAll('***', ' ').replaceAll(_kWhitespace, ' ').trim();
  }
  text = text.replaceAllMapped(_kCharRun, (match) => match[1]! * 3).trim();
  if (text.isEmpty) return null;

  if (settings.maxLength > 0 && text.length > settings.maxLength) {
    final cut = text.substring(0, settings.maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    text = lastSpace > settings.maxLength ~/ 2
        ? cut.substring(0, lastSpace)
        : cut;
  }

  /// A count inside a longer message ("KEKW 3 times nice") can't be
  /// combined without reading two counts; censored runs neither
  final String? unit = singleRun && !muted
      ? uncollapsed.first
            .replaceAllMapped(_kCharRun, (match) => match[1]! * 3)
            .trim()
      : null;
  final bool combinable = singleRun
      ? unit != null && unit.isNotEmpty
      : !collapsed && wordCount <= kChatTtsCombineMaxWords;

  return (
    text: settings.readUsernames ? '${message.author}: $text' : text,
    body: text,
    author: message.author,
    notable:
        message.isModerator ||
        message.isBroadcaster ||
        chatAuthorInList(filters.highlightUsers, message.authorNames),
    combineKey: combinable ? (unit ?? text).toLowerCase() : null,
    combineText: unit ?? text,
    repeats: unit != null ? uncollapsed.length : 1,
  );
}

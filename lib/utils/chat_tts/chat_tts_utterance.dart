import '../../models/enums/chat_type.dart';
import '../chat_highlight_helper.dart';
import '../chat_mute_helper.dart';

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

  const ChatTtsSettings({
    this.audience = ChatTtsAudience.everyone,
    this.readUsernames = true,
    this.skipEmotes = true,
    this.skipLinks = true,
    this.skipCommands = true,
    this.readOwnMessages = false,
    this.maxLength = kChatTtsDefaultMaxLength,
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

/// Spam runs ("aaaaaaaa", "!!!!!!") - 4+ of the same character
final RegExp _kCharRun = RegExp(r'(.)\1{3,}');

/// The text TTS speaks for [message], or null when it's skipped. Applies,
/// in order: own messages, ignored users / mute words (same as the
/// timeline), the audience, `!commands`, then builds the text without
/// emotes / links, collapses spam runs and cuts it to the max length.
String? chatTtsUtterance(
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

  final List<String> words = [];
  for (final part in message.parts) {
    if (part.isEmote) {
      if (!settings.skipEmotes) words.add(part.text);
      continue;
    }
    for (final word in part.text.split(_kWhitespace)) {
      if (word.isEmpty) continue;
      if (settings.skipEmotes &&
          (message.isThirdPartyEmote(word) || _kShortcode.hasMatch(word))) {
        continue;
      }
      if (settings.skipLinks && _kLink.hasMatch(word)) continue;
      words.add(word);
    }
  }

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

  return settings.readUsernames ? '${message.author}: $text' : text;
}

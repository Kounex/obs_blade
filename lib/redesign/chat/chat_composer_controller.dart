import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../../stores/pro_store.dart';
import '../../stores/views/twitch_chat.dart';
import '../../stores/views/youtube_chat.dart';
import '../../types/classes/twitch/eventsub/channel_chat_message.dart';
import 'chat_access.dart';
import 'chat_access_projection.dart';
import 'chat_timeline.dart';

typedef ChatConversation = ({
  ChatType platform,
  Object? account,
  String channel,
});
typedef ChatChannelChoice = ({ChatType platform, String id, String label});

/// Owns composition above panes; stores continue to own transport and history.
/// The host supplies initialized stores and persists engine/platform preferences.
/// Construction, focus changes and disposal never initialize or stop a service.
class ChatComposerController extends ChangeNotifier {
  ChatComposerController({
    required this.pro,
    required this.twitch,
    required this.youtube,
    required ChatType platform,
    required ChatEngine engine,
  }) : _presentation = Observable((platform: platform, engine: engine)) {
    _observe = autorun((_) => _sync());
  }

  final ProStore pro;
  final TwitchChatStore twitch;
  final YouTubeChatStore youtube;
  late final ReactionDisposer _observe;
  final _drafts = <ChatConversation, _Draft>{};
  final Observable<({ChatType platform, ChatEngine engine})> _presentation;
  ChatType get _platform => _presentation.value.platform;
  ChatEngine get _engine => _presentation.value.engine;
  List<ChatChannelChoice> _channels = const [];
  String? _twitchAccount;
  Object _twitchSession = Object();
  bool _youtubeSignedIn = false;
  Object? _youtubeAccount;
  ChatConversation? _conversation;
  late ChatAccess _access;
  ChatTimeline _timeline = const ChatTimeline();
  bool _sending = false;
  bool _changingChannel = false;
  bool _disposed = false;

  ChatAccess get access => _access;
  ChatTimeline get timeline => _timeline;
  ChatConversation? get conversation => _conversation;
  String get text => _draft?.text ?? '';
  ChatMessageEvent? get reply => _draft?.reply;
  String? get error => _draft?.error;
  bool get sending => _sending;
  bool get changingChannel => _changingChannel;
  bool get canSend => !busy && access.canSend && text.trim().isNotEmpty;
  bool get busy =>
      _sending ||
      _changingChannel ||
      access.sending ||
      (_platform == ChatType.Twitch && twitch.isSwitchingChannel);
  _Draft? get _draft => _drafts[_conversation];

  List<ChatChannelChoice> get channels => _channels;
  List<ChatChannelChoice> _projectChannels() => switch (_platform) {
    ChatType.Twitch => [
      if (twitch.isLoggedIn && twitch.user != null)
        (
          platform: ChatType.Twitch,
          id: twitch.user!.id,
          label: twitch.user!.displayName ?? twitch.user!.login,
        ),
      for (final channel in twitch.channels)
        (platform: ChatType.Twitch, id: channel.id, label: channel.displayName),
    ],
    ChatType.YouTube => [
      for (final channel in youtube.channels)
        (platform: ChatType.YouTube, id: channel.videoId, label: channel.label),
    ],
    _ => const [],
  };

  void _sync() {
    if (_disposed) return;
    // Scope-upgrade authorization retains the existing user. Keep that user's
    // draft through the prompt; clear only on logout or a different account.
    final twitchAccount = twitch.authState == TwitchAuthState.loggedOut
        ? null
        : twitch.user?.id;
    final youtubeSignedIn = youtube.isSignedInState;
    if (twitchAccount != _twitchAccount) {
      _drafts.removeWhere((key, _) => key.platform == ChatType.Twitch);
      _twitchAccount = twitchAccount;
      _twitchSession = Object();
    }
    if (youtubeSignedIn != _youtubeSignedIn) {
      _drafts.removeWhere((key, _) => key.platform == ChatType.YouTube);
      _youtubeSignedIn = youtubeSignedIn;
      // YouTube's persisted record has a title, not an account ID. Never key
      // drafts by that title or credentials; use this in-memory login lifetime.
      _youtubeAccount = youtubeSignedIn ? Object() : null;
    }
    _access = projectChatAccess(
      platform: _platform,
      preferredEngine: _engine,
      pro: pro,
      twitch: twitch,
      youtube: youtube,
    );
    final channel = switch (_platform) {
      ChatType.Twitch =>
        twitchAccount == null ? null : twitch.effectiveBroadcasterIdSafe,
      ChatType.YouTube =>
        youtube.channels
            .where((channel) => channel.label == youtube.selectedChannelLabel)
            .firstOrNull
            ?.videoId,
      _ => null,
    };
    _conversation = channel == null
        ? null
        : (
            platform: _platform,
            account: _platform == ChatType.Twitch
                ? (id: twitchAccount, session: _twitchSession)
                : _youtubeAccount,
            channel: channel,
          );
    if (_conversation case final key?) {
      _drafts.putIfAbsent(key, _Draft.new);
    }
    // Register saved-channel changes even when the active channel stays put.
    _channels = List.unmodifiable(_projectChannels());
    _timeline = projectChatTimeline(
      access: _access,
      twitch: twitch,
      youtube: youtube,
    );
    notifyListeners();
  }

  bool setPresentation(ChatType platform, ChatEngine engine) {
    if (_disposed || busy) return false;
    runInAction(
      () => _presentation.value = (platform: platform, engine: engine),
    );
    return true;
  }

  void setText(String text) {
    final draft = _draft;
    if (_disposed || draft == null || draft.text == text) return;
    draft.text = text;
    draft.revision++;
    draft.error = null;
    notifyListeners();
  }

  bool setReply(ChatMessageEvent? message) {
    final draft = _draft;
    if (_disposed || draft == null || _platform != ChatType.Twitch) {
      return false;
    }
    if (message != null &&
        (message.broadcasterUserId != _conversation?.channel ||
            !twitch.messages.any(
              (item) => item.messageId == message.messageId,
            ) ||
            twitch.isMessageDeleted(message.messageId))) {
      return false;
    }
    draft.reply = message;
    draft.revision++;
    notifyListeners();
    return true;
  }

  Future<bool> selectChannel(ChatChannelChoice choice) async {
    _sync();
    if (_disposed ||
        busy ||
        (access.gate != ChatGate.open && access.gate != ChatGate.channel) ||
        !channels.contains(choice)) {
      return false;
    }
    _changingChannel = true;
    notifyListeners();
    try {
      switch (choice.platform) {
        case ChatType.Twitch:
          await twitch.selectChannel(
            choice.id == twitch.user?.id ? null : choice.id,
          );
        case ChatType.YouTube:
          await youtube.selectChannel(choice.label);
        default:
          return false;
      }
      return !_disposed && _conversation?.channel == choice.id;
    } finally {
      _changingChannel = false;
      _sync();
    }
  }

  Future<bool> send() async {
    // Re-read the gate at action time, including entitlement and connection.
    _sync();
    if (_disposed || !canSend) return false;
    final key = _conversation!;
    final draft = _draft!;
    final revision = draft.revision;
    _sending = true;
    draft.error = null;
    notifyListeners();
    try {
      if (key.platform == ChatType.Twitch) {
        final target = draft.reply;
        if (target == null) {
          twitch.clearReplyTarget();
        } else {
          twitch.setReplyTarget(target);
        }
      }
      final accepted = key.platform == ChatType.Twitch
          ? await twitch.sendChatMessage(draft.text)
          : await youtube.sendChatMessage(draft.text);
      // Other owners may switch channels or log out while the request awaits.
      // Only the original, still-owned draft can receive its completion.
      if (!_disposed &&
          identical(_drafts[key], draft) &&
          draft.revision == revision) {
        if (accepted) {
          draft.text = '';
          draft.reply = null;
        } else {
          final storeError = key == _conversation
              ? key.platform == ChatType.Twitch
                    ? twitch.sendChatError
                    : youtube.sendChatError
              : null;
          draft.error =
              storeError ??
              'Message was not confirmed. Check chat before retrying.';
        }
      }
      return accepted;
    } finally {
      _sending = false;
      _sync();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _observe();
    _drafts.clear();
    super.dispose();
  }
}

class _Draft {
  String text = '';
  ChatMessageEvent? reply;
  String? error;
  int revision = 0;
}

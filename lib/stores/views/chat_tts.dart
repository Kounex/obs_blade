import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/chat_highlight_helper.dart';
import '../../utils/chat_tts/chat_tts_adapters.dart';
import '../../utils/chat_tts/chat_tts_queue.dart';
import '../../utils/chat_tts/chat_tts_utterance.dart';
import '../../utils/general_helper.dart';
import '../pro_store.dart';
import 'combined_chat.dart';
import 'kick_chat.dart';
import 'third_party_emotes.dart';
import 'twitch_chat.dart';
import 'youtube_chat.dart';

part 'chat_tts.g.dart';

/// Messages older than this are skipped when their turn comes - only with
/// [SettingsKeys.ChatTtsSkipStale] on (off by default)
const Duration kChatTtsStaleAfter = Duration(seconds: 15);

/// [ChatTtsSpeaker] on the system voices (`flutter_tts`). iOS: playback
/// category so it speaks with the silent switch on, mixing with other
/// apps' audio and briefly lowering it (voice-prompt mode).
class FlutterTtsSpeaker implements ChatTtsSpeaker {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setup;

  Future<void> _ensureSetup() => _setup ??= () async {
    await _tts.awaitSpeakCompletion(true);
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ], IosTextToSpeechAudioMode.voicePrompt);
    }
  }();

  /// [multiplier] 1.0 = normal speed (flutter_tts: 0.5 is normal on both
  /// platforms, 1.0 the fastest)
  Future<void> setSpeed(double multiplier) async {
    await _ensureSetup();
    await _tts.setSpeechRate((0.5 * multiplier).clamp(0.1, 1.0));
  }

  @override
  Future<void> speak(String text) async {
    await _ensureSetup();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

/// Chat text-to-speech: reads live messages of the chat the Chat tab shows
/// (one native platform, or every Combined source) out loud while the app
/// is open. Pro, like the native engines it listens to.
///
/// What's read follows [chatTtsUtterance] with the settings sheet's
/// options plus the chat-wide filters (ignored users, mute words); the
/// queue never drops on its own - see [ChatTtsQueue].
class ChatTtsStore = _ChatTtsStore with _$ChatTtsStore;

abstract class _ChatTtsStore with Store {
  _ChatTtsStore({
    ChatTtsSpeaker? speaker,
    bool Function()? isProResolver,
    Stream<ChatTtsMessage> Function()? messages,
  }) : _speaker = speaker ?? FlutterTtsSpeaker(),
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro),
       _messagesFactory = messages {
    _queue = ChatTtsQueue(_speaker, onChanged: _syncQueueState);
  }

  final ChatTtsSpeaker _speaker;
  final bool Function() _isProResolver;

  /// Test seam - replaces the three platform store streams
  final Stream<ChatTtsMessage> Function()? _messagesFactory;
  late final ChatTtsQueue _queue;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @observable
  bool enabled = false;

  /// Messages waiting behind the one being read
  @observable
  int waiting = 0;

  @observable
  bool speaking = false;

  Box get _settings => Hive.box(HiveKeys.Settings.name);

  /// Picks up the persisted on/off state - call once at startup
  void init() {
    final on =
        _settings.get(SettingsKeys.ChatTtsEnabled.name, defaultValue: false)
            as bool;
    if (on) setEnabled(true, persist: false);
  }

  @action
  void setEnabled(bool on, {bool persist = true}) {
    if (persist) _settings.put(SettingsKeys.ChatTtsEnabled.name, on);
    if (on == this.enabled) return;
    this.enabled = on;
    if (on) {
      applySettings();
      _listen();
    } else {
      _cancel();
      unawaited(_queue.clear());
    }
  }

  void toggle() => setEnabled(!this.enabled);

  /// Drop everything waiting + stop the current message
  Future<void> jumpToLatest() => _queue.clear();

  /// Re-read speed / stale skip after the settings sheet changed them
  void applySettings() {
    final speaker = _speaker;
    if (speaker is FlutterTtsSpeaker) {
      unawaited(
        speaker
            .setSpeed(
              (_settings.get(SettingsKeys.ChatTtsSpeed.name, defaultValue: 1.0)
                      as num)
                  .toDouble(),
            )
            .catchError(
              (Object e) => GeneralHelper.advLog('TTS speed failed - $e'),
            ),
      );
    }
    _queue.skipStaleAfter =
        _settings.get(SettingsKeys.ChatTtsSkipStale.name, defaultValue: false)
            as bool
        ? kChatTtsStaleAfter
        : null;
  }

  void dispose() {
    _cancel();
    unawaited(_queue.clear());
  }

  @action
  void _syncQueueState() {
    this.waiting = _queue.waiting;
    this.speaking = _queue.speaking;
  }

  void _cancel() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _listen() {
    _cancel();
    final factory = _messagesFactory;
    if (factory != null) {
      _subscriptions.add(factory().listen(_onMessage));
      return;
    }
    final getIt = GetIt.instance;
    final emotes = getIt<ThirdPartyEmoteStore>();

    final twitch = getIt<TwitchChatStore>();
    _subscriptions.add(
      twitch.liveMessages.listen(
        (event) => _onMessage(
          chatTtsFromTwitch(
            event,
            selfUserId: twitch.user?.id,
            selfNames: [twitch.user?.login, twitch.user?.displayName],
            isThirdPartyEmote: (word) =>
                emotes.emote(word, broadcasterId: event.broadcasterUserId) !=
                null,
          ),
        ),
      ),
    );

    final youTube = getIt<YouTubeChatStore>();
    _subscriptions.add(
      youTube.liveMessages.listen((message) {
        final tts = chatTtsFromYouTube(
          message,
          selfChannelId: youTube.selfChannelId,
          selfNames: [youTube.selfChannelTitle],
        );
        if (tts != null) _onMessage(tts);
      }),
    );

    final kick = getIt<KickChatStore>();
    _subscriptions.add(
      kick.liveMessages.listen((message) {
        final broadcasterId = kick.channelInfo?.userId?.toString();
        _onMessage(
          chatTtsFromKick(
            message,
            selfUserId: kick.selfUserId,
            selfNames: [kick.selfUsername],
            isThirdPartyEmote: broadcasterId == null
                ? null
                : (word) =>
                      emotes.emote(word, broadcasterId: broadcasterId) != null,
          ),
        );
      }),
    );
  }

  /// Whether the Chat tab currently shows [platform]'s native chat - alone
  /// or as a Combined source
  bool _platformShown(ChatType platform) {
    final type = _settings.get(
      SettingsKeys.SelectedChatType.name,
      defaultValue: ChatType.Twitch,
    );
    if (type == ChatType.Combined) {
      final getIt = GetIt.instance;
      if (!getIt.isRegistered<CombinedChatStore>()) return false;
      return getIt<CombinedChatStore>().activeSources.any(
        (source) => source.platform == platform && !source.unavailable,
      );
    }
    final engine = _settings.get(
      SettingsKeys.SelectedChatEngine.name,
      defaultValue: ChatEngine.webView,
    );
    return type == platform &&
        nativeChatAvailableFor(platform) &&
        engine == ChatEngine.native;
  }

  void _onMessage(ChatTtsMessage message) {
    if (!this.enabled || !_isProResolver()) return;
    if (_messagesFactory == null && !_platformShown(message.platform)) return;

    final text = chatTtsUtterance(message, _readSettings(), _readFilters());
    if (text != null) _queue.add(text, receivedAt: message.receivedAt);
  }

  ChatTtsSettings _readSettings() {
    final box = _settings;
    bool flag(SettingsKeys key, bool fallback) =>
        box.get(key.name, defaultValue: fallback) as bool;
    return ChatTtsSettings(
      audience: ChatTtsAudience.parse(
        box.get(SettingsKeys.ChatTtsAudience.name),
      ),
      readUsernames: flag(SettingsKeys.ChatTtsReadUsernames, true),
      skipEmotes: flag(SettingsKeys.ChatTtsSkipEmotes, true),
      skipLinks: flag(SettingsKeys.ChatTtsSkipLinks, true),
      skipCommands: flag(SettingsKeys.ChatTtsSkipCommands, true),
      readOwnMessages: flag(SettingsKeys.ChatTtsReadOwnMessages, false),
      maxLength:
          (box.get(
                    SettingsKeys.ChatTtsMaxLength.name,
                    defaultValue: kChatTtsDefaultMaxLength,
                  )
                  as num)
              .toInt(),
    );
  }

  ChatTtsFilters _readFilters() {
    final box = _settings;
    String raw(SettingsKeys key) =>
        box.get(key.name, defaultValue: '') as String;
    return ChatTtsFilters(
      muteWords: parseChatHighlightKeywords(raw(SettingsKeys.ChatMuteWords)),
      muteReplace:
          box.get(SettingsKeys.ChatMuteReplace.name, defaultValue: false) ==
          true,
      highlightUsers: parseChatUserList(raw(SettingsKeys.ChatHighlightUsers)),
      ignoredUsers: parseChatUserList(raw(SettingsKeys.ChatIgnoredUsers)),
      selfMentionEnabled:
          box.get(
            SettingsKeys.ChatHighlightSelfMention.name,
            defaultValue: true,
          ) ==
          true,
      keywords: parseChatHighlightKeywords(
        raw(SettingsKeys.ChatHighlightKeywords),
      ),
    );
  }
}

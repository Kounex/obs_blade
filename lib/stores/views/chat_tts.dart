import 'dart:async';

import 'package:flutter/services.dart';
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
import '../../utils/chat_tts/chat_tts_voice.dart';
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

/// [ChatTtsSpeaker] on the system voices through the app's own platform
/// channel (iOS `AVSpeechSynthesizer` in `AppDelegate.swift`, Android
/// `TextToSpeech` in `MainActivity.kt`). [speak] completes when the
/// message was read or stopped. iOS speaks with the silent switch on and
/// lowers other apps' audio while reading.
class PlatformTtsSpeaker implements ChatTtsSpeaker {
  static const MethodChannel _channel = MethodChannel(
    'com.kounex.obsBlade/tts',
  );

  /// Platforms without the channel (desktop, tests) stay silent
  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      GeneralHelper.advLog('Chat TTS $method failed - $e');
    }
  }

  /// [multiplier] 1.0 = normal speed
  Future<void> setSpeed(double multiplier) => _invoke('setRate', multiplier);

  /// [volume] 0.0 … 1.0, relative to the device volume
  Future<void> setVolume(double volume) => _invoke('setVolume', volume);

  /// Installed voices - empty where the channel doesn't exist
  Future<List<ChatTtsVoice>> voices() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('voices');
      return [
        for (final entry in raw ?? const <Object?>[])
          if (entry is Map) ChatTtsVoice.fromMap(entry),
      ];
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (e) {
      GeneralHelper.advLog('Chat TTS voices failed - $e');
      return const [];
    }
  }

  /// Default language (BCP 47 tag, null = the phone's) and whether each
  /// message's language is detected - kept natively until changed
  Future<void> setLanguage({String? language, required bool detect}) =>
      _invoke('setLanguage', {'language': language, 'detect': detect});

  @override
  Future<void> speak(String text, {String? detectionText}) =>
      _invoke('speak', {'text': text, 'detectionText': detectionText});

  @override
  Future<void> stop() => _invoke('stop');
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
    Future<List<ChatTtsVoice>> Function()? voicesLoader,
  }) : _speaker = speaker ?? PlatformTtsSpeaker(),
       _isProResolver =
           isProResolver ?? (() => GetIt.instance<ProStore>().isPro),
       _messagesFactory = messages,
       _voicesOverride = voicesLoader {
    _queue = ChatTtsQueue(_speaker, onChanged: _syncQueueState);
  }

  final ChatTtsSpeaker _speaker;
  final bool Function() _isProResolver;

  /// Test seam - replaces the three platform store streams
  final Stream<ChatTtsMessage> Function()? _messagesFactory;

  /// Test seam - replaces the platform voices query
  final Future<List<ChatTtsVoice>> Function()? _voicesOverride;
  late final ChatTtsQueue _queue;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @observable
  bool enabled = false;

  /// Messages waiting behind the one being read
  @observable
  int waiting = 0;

  @observable
  bool speaking = false;

  /// Installed system voices - null until [loadVoices] answered
  @observable
  List<ChatTtsVoice>? voices;

  /// Asks the platform which voices / languages it can read with
  Future<void> loadVoices() async {
    final speaker = _speaker;
    final loader = _voicesOverride;
    final List<ChatTtsVoice> loaded = loader != null
        ? await loader()
        : speaker is PlatformTtsSpeaker
        ? await speaker.voices()
        : const [];
    runInAction(() => this.voices = loaded);
  }

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
    if (speaker is PlatformTtsSpeaker) {
      unawaited(
        speaker.setSpeed(
          (_settings.get(SettingsKeys.ChatTtsSpeed.name, defaultValue: 1.0)
                  as num)
              .toDouble(),
        ),
      );
      unawaited(
        speaker.setVolume(
          (_settings.get(SettingsKeys.ChatTtsVolume.name, defaultValue: 1.0)
                  as num)
              .toDouble(),
        ),
      );
      unawaited(
        speaker.setLanguage(
          language: _settings.get(SettingsKeys.ChatTtsLanguage.name) as String?,
          detect:
              _settings.get(
                SettingsKeys.ChatTtsDetectLanguage.name,
                defaultValue: false,
              ) ==
              true,
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

    final spoken = chatTtsSpoken(message, _readSettings(), _readFilters());
    if (spoken != null) {
      _queue.add(
        spoken.text,
        receivedAt: message.receivedAt,
        detectionText: spoken.body,
      );
    }
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

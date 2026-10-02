import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/chat_highlight_helper.dart';
import '../../utils/chat_tts/chat_tts_adapters.dart';
import '../../utils/chat_tts/chat_tts_combine.dart';
import '../../utils/chat_tts/chat_tts_phrases.dart';
import '../../utils/chat_tts/chat_tts_queue.dart';
import '../../utils/chat_tts/chat_tts_utterance.dart';
import '../../utils/chat_tts/chat_tts_voice.dart';
import '../../utils/general_helper.dart';
import '../../utils/pro_ids.dart';
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
  Future<void> setLanguage({
    String? language,
    required bool detect,
    Map<String, String> voices = const {},
  }) => _invoke('setLanguage', {
    'language': language,
    'detect': detect,
    'voices': voices,
  });

  @override
  Future<void> preview({
    String? voiceId,
    String? language,
    required String text,
  }) => _invoke('preview', {
    'voiceId': voiceId,
    'language': language,
    'text': text,
  });

  /// Android: the phone's text-to-speech settings / the engine's voice data
  /// download - false where that isn't possible (iOS has no such link)
  Future<bool> openTtsSettings() => _invokeBool('openTtsSettings');

  Future<bool> installVoiceData() => _invokeBool('installVoiceData');

  Future<bool> _invokeBool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      GeneralHelper.advLog('Chat TTS $method failed - $e');
      return false;
    }
  }

  /// The bridges answer false when the audio is taken (phone call,
  /// another app's audio focus) and nothing was read
  @override
  Future<bool> speak(String text, {String? detectionText}) async {
    try {
      return await _channel.invokeMethod<Object?>('speak', {
            'text': text,
            'detectionText': detectionText,
          }) !=
          false;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (e) {
      GeneralHelper.advLog('Chat TTS speak failed - $e');
      return true;
    }
  }

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

  /// Platform chat stores [_subscriptions] already listens to
  final Set<ChatType> _attached = {};

  /// Bumped per [loadVoices] - an older answer arriving late is dropped
  int _voicesRequest = 0;

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

  /// The voice the bridge reads the default language with - null until
  /// [loadVoices] answered (or the platform has none)
  ChatTtsVoice? get defaultVoice =>
      this.voices?.where((voice) => voice.isDefault).firstOrNull;

  /// Asks the platform which voices / languages it can read with
  Future<void> loadVoices() async {
    final request = ++_voicesRequest;
    final speaker = _speaker;
    final loader = _voicesOverride;
    final List<ChatTtsVoice> loaded = loader != null
        ? await loader()
        : speaker is PlatformTtsSpeaker
        ? await speaker.voices()
        : const [];
    if (request != _voicesRequest) return;
    runInAction(() => this.voices = loaded);
    if (loader == null && (kDebugMode || kProReleaseTestUnlock)) {
      unawaited(_exportVoices(loaded));
    }
  }

  /// Dogfood / debug builds only: the device's voice list as
  /// `Documents/tts-voices.json`, pulled off the phone (devicectl / adb) to
  /// see which languages people really have - e.g. for [ChatTtsPhrases]
  Future<void> _exportVoices(List<ChatTtsVoice> voices) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      await File('${directory.path}/tts-voices.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert([
          for (final voice in voices)
            {
              'id': voice.id,
              'name': voice.name,
              'language': voice.language,
              'languageName': voice.languageName,
              'quality': voice.quality,
              'network': voice.network,
            },
        ]),
      );
    } catch (e) {
      GeneralHelper.advLog('Chat TTS voice export failed - $e');
    }
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

      /// The default voice tells which language the filler words are in
      if (this.voices == null) unawaited(loadVoices());
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
          voices: this.voicePicks,
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
    _attached.clear();
  }

  void _listen() {
    _cancel();
    _subscriptions.add(_watchChatSelection());
    final factory = _messagesFactory;
    if (factory != null) {
      _subscriptions.add(factory().listen(_onMessage));
      return;
    }
    _attachChatStores();
  }

  /// A platform chat store was just created (`main.dart` registers this as
  /// its `onCreated`) - read it too while text-to-speech is on
  void chatStoreCreated() {
    if (this.enabled && _messagesFactory == null) _attachChatStores();
  }

  /// Whether [T]'s lazy singleton exists already - never creates it
  static bool _created<T extends Object>() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<T>()) return false;
    try {
      return getIt.checkLazySingletonInstanceExists<T>();
    } on StateError {
      /// Registered as a plain singleton (tests) - it exists
      return true;
    }
  }

  /// Listens to the platform stores that exist. Creating one here would
  /// start its sign-in / connection work (a YouTube poll that spends quota)
  /// for a chat nobody opened - the rest attach via [chatStoreCreated].
  void _attachChatStores() {
    final getIt = GetIt.instance;

    if (!_attached.contains(ChatType.Twitch) && _created<TwitchChatStore>()) {
      _attached.add(ChatType.Twitch);
      final twitch = getIt<TwitchChatStore>();
      _subscriptions.add(
        twitch.liveMessages.listen((event) {
          final channel = twitch.selectedChannelId;
          _onMessage(
            chatTtsFromTwitch(
              event,
              selfUserId: twitch.user?.id,
              selfNames: [twitch.user?.login, twitch.user?.displayName],
              isThirdPartyEmote: (word) =>
                  getIt<ThirdPartyEmoteStore>().emote(
                    word,
                    broadcasterId: event.broadcasterUserId,
                  ) !=
                  null,
            ),
            isCurrent: () =>
                _platformShown(ChatType.Twitch) &&
                twitch.selectedChannelId == channel,
          );
        }),
      );
    }

    if (!_attached.contains(ChatType.YouTube) && _created<YouTubeChatStore>()) {
      _attached.add(ChatType.YouTube);
      final youTube = getIt<YouTubeChatStore>();
      _subscriptions.add(
        youTube.liveMessages.listen((message) {
          final tts = chatTtsFromYouTube(
            message,
            selfChannelId: youTube.selfChannelId,
            selfNames: [youTube.selfChannelTitle],
          );
          final channel = youTube.selectedChannelLabel;
          if (tts != null) {
            _onMessage(
              tts,
              isCurrent: () =>
                  _platformShown(ChatType.YouTube) &&
                  youTube.selectedChannelLabel == channel,
            );
          }
        }),
      );
    }

    if (!_attached.contains(ChatType.Kick) && _created<KickChatStore>()) {
      _attached.add(ChatType.Kick);
      final kick = getIt<KickChatStore>();
      _subscriptions.add(
        kick.liveMessages.listen((message) {
          final broadcasterId = kick.channelInfo?.userId?.toString();
          final channel = kick.selectedChannelSlug;
          _onMessage(
            chatTtsFromKick(
              message,
              selfUserId: kick.selfUserId,
              selfNames: [kick.selfUsername],
              isThirdPartyEmote: broadcasterId == null
                  ? null
                  : (word) =>
                        getIt<ThirdPartyEmoteStore>().emote(
                          word,
                          broadcasterId: broadcasterId,
                        ) !=
                        null,
            ),
            isCurrent: () =>
                _platformShown(ChatType.Kick) &&
                kick.selectedChannelSlug == channel,
          );
        }),
      );
    }
  }

  /// Switching the chat type or engine stops reading right away - what's
  /// waiting belongs to the chat that was on screen (a channel switch
  /// skips the old channel's messages when their turn comes, see
  /// [ChatTtsQueueItem.isCurrent])
  StreamSubscription<BoxEvent> _watchChatSelection() {
    Object? type = _settings.get(SettingsKeys.SelectedChatType.name);
    Object? engine = _settings.get(SettingsKeys.SelectedChatEngine.name);
    return _settings.watch().listen((event) {
      if (event.key == SettingsKeys.SelectedChatType.name) {
        if (event.value == type) return;
        type = event.value;
      } else if (event.key == SettingsKeys.SelectedChatEngine.name) {
        if (event.value == engine) return;
        engine = event.value;
      } else {
        return;
      }
      unawaited(_queue.clear());
    });
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

  void _onMessage(ChatTtsMessage message, {bool Function()? isCurrent}) {
    if (!this.enabled || !_isProResolver()) return;
    if (_messagesFactory == null && !_platformShown(message.platform)) return;

    final settings = _readSettings();
    final spoken = chatTtsSpoken(message, settings, _readFilters());
    if (spoken == null) return;

    /// Re-read per message - the switch applies to what's waiting right away
    _queue.combine =
        _settings.get(
              SettingsKeys.ChatTtsCombineRepeats.name,
              defaultValue: true,
            ) ==
            true
        ? (group) => chatTtsCombinedLine(
            group,
            readUsernames: settings.readUsernames,
            phrases: settings.phrases,
          )
        : null;
    _queue.add(
      spoken.text,
      receivedAt: message.receivedAt,
      detectionText: spoken.body,
      combineKey: spoken.combineKey,
      combineText: spoken.combineText,
      repeats: spoken.repeats,
      author: spoken.author,
      notable: spoken.notable,
      isCurrent: isCurrent,
    );
  }

  /// The user's voice per language (tag → voice id)
  Map<String, String> get voicePicks {
    final raw = _settings.get(SettingsKeys.ChatTtsVoices.name) as String?;
    if (raw == null || raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      );
    } catch (_) {
      return const {};
    }
  }

  /// Pick [voiceId] for [language] - null goes back to automatic
  void setVoicePick(String language, String? voiceId) {
    final picks = Map<String, String>.of(this.voicePicks);
    if (voiceId == null || voiceId.isEmpty) {
      picks.remove(language);
    } else {
      picks[language] = voiceId;
    }
    _settings.put(SettingsKeys.ChatTtsVoices.name, jsonEncode(picks));
    applySettings();

    /// The bridge marks its pick as preferred - the list shows it after a
    /// re-read (channel calls run in order, the new picks are there first)
    unawaited(loadVoices());
  }

  /// Plays a short sample in [language] with [voiceId] (null = the voice
  /// TTS would use) - what's waiting to be read is dropped, the sample
  /// interrupts it anyway, and new messages wait until it's over
  Future<void> previewVoice({required String language, String? voiceId}) {
    final text = ChatTtsPhrases.sample(language);
    return _queue.hold(
      () => _speaker
          .preview(voiceId: voiceId, language: language, text: text)
          .timeout(
            _queue.utteranceTimeout(text),
            onTimeout: () => _speaker.stop(),
          ),
    );
  }

  /// Android shortcuts for more voices - false where not possible
  Future<bool> openTtsSettings() async {
    final speaker = _speaker;
    return speaker is PlatformTtsSpeaker ? speaker.openTtsSettings() : false;
  }

  Future<bool> installVoiceData() async {
    final speaker = _speaker;
    return speaker is PlatformTtsSpeaker ? speaker.installVoiceData() : false;
  }

  /// The language TTS reads in by default - the setting, else the default
  /// voice's (Android: the speech engine's language, not the phone's),
  /// else the phone's
  String get _defaultLanguage =>
      (_settings.get(SettingsKeys.ChatTtsLanguage.name) as String?) ??
      this.defaultVoice?.language ??
      PlatformDispatcher.instance.locale.toLanguageTag();

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
      skipEmoteOnly: flag(SettingsKeys.ChatTtsSkipEmoteOnly, false),
      phrases: ChatTtsPhrases.of(_defaultLanguage),
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

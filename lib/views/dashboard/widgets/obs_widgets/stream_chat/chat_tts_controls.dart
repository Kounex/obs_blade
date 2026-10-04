import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../shared/general/base/dropdown.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/pro_store.dart';
import '../../../../../stores/views/chat_tts.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/chat_tts/chat_tts_utterance.dart';
import '../../../../../utils/chat_tts/chat_tts_voice.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/wake_lock_helper.dart';
import 'native_chat_chrome.dart';

ChatTtsStore? _ttsStoreOrNull() => GetIt.instance.isRegistered<ChatTtsStore>()
    ? GetIt.instance<ChatTtsStore>()
    : null;

/// Opens the text-to-speech settings (also reachable from the native chat
/// options sheet)
void showChatTtsSheet(BuildContext context) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) => NativeChatSheetScaffold(
    header: Text('Text to speech', style: nativeChatSheetTitleStyle(context)),
    body: const ChatTtsSettingsRows(),
  ),
);

/// Speaker toggle in the native chat header: tap = read chat aloud on /
/// off, long-press = settings. While reading falls behind, a "N waiting"
/// chip next to it jumps to the latest message. The first switch-on shows
/// a speech bubble anchored above the speaker (tail pointing at it) saying
/// that holding it opens the settings - tapping the bubble opens them too,
/// it closes on its own after [kChatTtsHintDuration]. Pro only (the native
/// engines it reads are).
class ChatTtsButton extends StatefulWidget {
  const ChatTtsButton({super.key});

  @override
  State<ChatTtsButton> createState() => _ChatTtsButtonState();
}

/// How long the one-off "hold for settings" bubble stays
const Duration kChatTtsHintDuration = Duration(seconds: 5);

class _ChatTtsButtonState extends State<ChatTtsButton> {
  final LayerLink _anchor = LayerLink();
  final OverlayPortalController _hint = OverlayPortalController();
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _hideHint() {
    _hintTimer?.cancel();
    if (this.mounted && _hint.isShowing) _hint.hide();
  }

  void _toggle(ChatTtsStore store) {
    store.toggle();
    if (!store.enabled) {
      _hideHint();
      return;
    }
    final box = Hive.box(HiveKeys.Settings.name);
    if (box.get(
          SettingsKeys.HasUserSeenChatTtsHint.name,
          defaultValue: false,
        ) ==
        true) {
      return;
    }
    box.put(SettingsKeys.HasUserSeenChatTtsHint.name, true);
    _hint.show();
    _hintTimer?.cancel();
    _hintTimer = Timer(kChatTtsHintDuration, _hideHint);
  }

  /// The bubble: right edges aligned with the speaker (it sits at the
  /// header's right end, a centred bubble would leave the screen), tail
  /// under the speaker's centre
  Widget _hintBubble(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fill = theme.colorScheme.secondary;
    final Color text = theme.colorScheme.onSecondary;
    const double tailWidth = 14.0;
    const double tailHeight = 7.0;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _anchor,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topRight,
        followerAnchor: Alignment.bottomRight,
        offset: const Offset(0.0, -2.0),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.9 + 0.1 * t,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
          child: Semantics(
            liveRegion: true,
            button: true,
            label: 'Reading chat aloud. Hold the speaker for settings.',
            hint: 'Opens text to speech settings',
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('chat-tts-hint'),
              onTap: () {
                _hideHint();
                showChatTtsSheet(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220.0),
                    child: Material(
                      color: fill,
                      elevation: 6.0,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Reading chat aloud\n',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: 'Hold the speaker for settings',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// Tail centred under the 44pt speaker
                  Padding(
                    padding: EdgeInsets.only(
                      right:
                          kMinInteractiveDimensionCupertino / 2 - tailWidth / 2,
                    ),
                    child: CustomPaint(
                      size: const Size(tailWidth, tailHeight),
                      painter: _BubbleTailPainter(fill),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatTtsStore? store = _ttsStoreOrNull();
    if (store == null || !GetIt.instance.isRegistered<ProStore>()) {
      return const SizedBox.shrink();
    }

    /// Root overlay: the bubble sits above the tab shell, never clipped by
    /// the chat pane
    return OverlayPortal(
      controller: _hint,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: this._hintBubble,
      child: Observer(
        builder: (context) {
          if (!GetIt.instance<ProStore>().isPro) {
            return const SizedBox.shrink();
          }
          final bool on = store.enabled;
          final int waiting = store.waiting;
          final Color accent = Theme.of(context).colorScheme.secondary;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (on && waiting > 0)
                Semantics(
                  button: true,
                  label: '$waiting waiting, jump to the latest message',
                  excludeSemantics: true,
                  child: Pressable(
                    haptic: true,
                    springy: false,
                    onTap: store.jumpToLatest,
                    child: Container(
                      key: const Key('chat-tts-waiting'),
                      height: 24.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$waiting',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 2.0),
                          const Icon(
                            CupertinoIcons.forward_end_fill,
                            size: 12.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Semantics(
                button: true,
                toggled: on,
                label: 'Read chat aloud',
                hint: 'Long press for text to speech settings',
                excludeSemantics: true,
                child: GestureDetector(
                  onLongPress: () {
                    _hideHint();
                    showChatTtsSheet(context);
                  },
                  child: Pressable(
                    haptic: true,
                    springy: false,
                    onTap: () => this._toggle(store),
                    child: CompositedTransformTarget(
                      link: _anchor,
                      child: SizedBox(
                        key: const Key('chat-tts-button'),
                        width: kMinInteractiveDimensionCupertino,
                        height: kMinInteractiveDimensionCupertino,
                        child: Center(
                          child: Icon(
                            on
                                ? CupertinoIcons.speaker_2_fill
                                : CupertinoIcons.speaker_slash,
                            size: 20.0,
                            color: on
                                ? accent
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Downward triangle under the hint bubble
class _BubbleTailPainter extends CustomPainter {
  final Color color;

  const _BubbleTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0.0, 0.0)
      ..lineTo(size.width, 0.0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = this.color);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.color != this.color;
}

/// The text-to-speech settings - the sheet body and the options-sheet page
/// share it
class ChatTtsSettingsRows extends StatelessWidget {
  /// The short explanation on top - off where the page carries its own
  final bool showIntro;

  const ChatTtsSettingsRows({super.key, this.showIntro = true});

  static const String intro =
      'Reads new messages of the native chat out loud while OBS Blade is '
      'open. It stops when the screen locks.';

  /// Every key a row below reads - a missing one leaves its switch stuck
  /// (the write lands, the row never rebuilds)
  static const List<SettingsKeys> _keys = [
    SettingsKeys.ChatTtsAudience,
    SettingsKeys.ChatTtsReadUsernames,
    SettingsKeys.ChatTtsSkipEmotes,
    SettingsKeys.ChatTtsSkipLinks,
    SettingsKeys.ChatTtsSkipCommands,
    SettingsKeys.ChatTtsReadOwnMessages,
    SettingsKeys.ChatTtsMaxLength,
    SettingsKeys.ChatTtsSpeed,
    SettingsKeys.ChatTtsVolume,
    SettingsKeys.ChatTtsSkipStale,
    SettingsKeys.ChatTtsDetectLanguage,
    SettingsKeys.ChatTtsCombineRepeats,
    SettingsKeys.ChatTtsSkipEmoteOnly,
    SettingsKeys.WakeLock,
  ];

  static const List<(ChatTtsAudience, String, String)> _audiences = [
    (ChatTtsAudience.everyone, 'Everyone', 'Every message'),
    (
      ChatTtsAudience.highlightedAndMods,
      'Highlighted users and mods',
      'Your highlighted users, moderators, the streamer, and mentions',
    ),
    (
      ChatTtsAudience.mentions,
      'Mentions only',
      'Messages with your name or a highlight keyword',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ChatTtsStore? store = _ttsStoreOrNull();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: _keys,
      builder: (context, box, child) {
        bool flag(SettingsKeys key, bool fallback) =>
            box.get(key.name, defaultValue: fallback) == true;
        void set(SettingsKeys key, Object value) {
          box.put(key.name, value);
          store?.applySettings();
        }

        final audience = ChatTtsAudience.parse(
          box.get(SettingsKeys.ChatTtsAudience.name),
        );
        final double speed =
            (box.get(SettingsKeys.ChatTtsSpeed.name, defaultValue: 1.0) as num)
                .toDouble();
        final double volume =
            (box.get(SettingsKeys.ChatTtsVolume.name, defaultValue: 1.0) as num)
                .toDouble();
        final int maxLength =
            (box.get(
                      SettingsKeys.ChatTtsMaxLength.name,
                      defaultValue: kChatTtsDefaultMaxLength,
                    )
                    as num)
                .toInt();

        Widget toggle(
          SettingsKeys key,
          bool fallback,
          String title, [
          String? subtitle,
        ]) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: subtitle != null
              ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
              : null,
          trailing: BaseAdaptiveSwitch(
            value: flag(key, fallback),
            onChanged: (value) => set(key, value),
          ),
        );

        Widget section(String label) => Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xs,
          ),
          child: Text(label, style: nativeChatSheetSectionStyle(context)),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (this.showIntro)
              Text(intro, style: Theme.of(context).textTheme.bodySmall),
            if (store != null)
              Observer(
                builder: (context) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Read chat aloud'),
                      trailing: BaseAdaptiveSwitch(
                        value: store.enabled,
                        onChanged: store.setEnabled,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        store.waiting == 0
                            ? 'Nothing waiting'
                            : '${store.waiting} waiting',
                      ),
                      subtitle: Text(
                        'Busy chat? Jump to the latest message instead of '
                        'catching up.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: TextButton(
                        onPressed: store.waiting > 0
                            ? store.jumpToLatest
                            : null,
                        child: const Text('Jump to latest'),
                      ),
                    ),
                  ],
                ),
              ),
            if (!flag(SettingsKeys.WakeLock, false))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.device_phone_portrait),
                title: const Text('Keep the screen on'),
                subtitle: Text(
                  'Wake Lock keeps reading going while the app is open.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: BaseAdaptiveSwitch(
                  value: false,
                  onChanged: (value) {
                    box.put(SettingsKeys.WakeLock.name, value);
                    applyWakeLockSetting();
                  },
                ),
              ),
            section('Who'),
            for (final (value, title, subtitle) in _audiences)
              PressFlash(
                onTap: () => set(SettingsKeys.ChatTtsAudience, value.name),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(title),
                  subtitle: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: value == audience
                      ? Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                      : null,
                ),
              ),
            section('What'),
            toggle(SettingsKeys.ChatTtsReadUsernames, true, 'Read usernames'),
            toggle(SettingsKeys.ChatTtsSkipEmotes, true, 'Skip emotes'),
            toggle(
              SettingsKeys.ChatTtsSkipEmoteOnly,
              false,
              'Skip emote-only messages',
              'For when emotes are read: drops messages that are nothing '
                  'but emotes.',
            ),
            toggle(
              SettingsKeys.ChatTtsCombineRepeats,
              true,
              'Combine repeated messages',
              'When reading falls behind, identical short messages waiting '
                  'in line are read once - e.g. "Viewer, a mod and 13 others: '
                  'KEKW".',
            ),
            toggle(SettingsKeys.ChatTtsSkipLinks, true, 'Skip links'),
            toggle(SettingsKeys.ChatTtsSkipCommands, true, 'Skip !commands'),
            toggle(
              SettingsKeys.ChatTtsReadOwnMessages,
              false,
              'Read my own messages',
            ),
            toggle(
              SettingsKeys.ChatTtsSkipStale,
              false,
              'Skip old messages',
              'Skips messages that waited longer than '
                  '${kChatTtsStaleAfter.inSeconds}s. Off: nothing is skipped.',
            ),
            section('How'),
            _TtsSlider(
              label: 'Speed',
              valueLabel: '${speed.toStringAsFixed(2)}×',
              value: speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) => set(SettingsKeys.ChatTtsSpeed, value),
            ),
            _TtsSlider(
              label: 'Volume',
              valueLabel: '${(volume * 100).round()}%',
              value: volume,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (value) => set(SettingsKeys.ChatTtsVolume, value),
            ),
            _TtsSlider(
              label: 'Max length',
              valueLabel: maxLength == 0 ? 'No limit' : '$maxLength chars',
              value: maxLength.toDouble(),
              min: 0,
              max: 300,
              divisions: 12,
              onChanged: (value) =>
                  set(SettingsKeys.ChatTtsMaxLength, value.round()),
            ),
            section('Language'),
            toggle(
              SettingsKeys.ChatTtsDetectLanguage,
              false,
              "Detect each message's language",
              Platform.isAndroid
                  ? 'Reads a message in its own language when a voice for it '
                        'is installed (Android 10 or newer), otherwise in the '
                        'language below. Short messages stay in the language '
                        'below.'
                  : 'Reads a message in its own language when a voice for it '
                        'is installed, otherwise in the language below. Short '
                        'messages stay in the language below.',
            ),
            if (store != null) _LanguagePicker(store: store),
          ],
        );
      },
    );
  }
}

/// Dropdown value for "the phone's language" (no setting)
const String _kPhoneLanguage = '';

/// The default TTS language as a dropdown: "Phone language" (Android: the
/// speech engine's default - it reads in that, not the phone's language)
/// or one of the languages the system has voices for. Also the fallback
/// when detection finds nothing usable. The voice it reads with shows
/// underneath. Asks the platform for its voices once per sheet and after
/// each change (the bridge reports which voice it reads with).
class _LanguagePicker extends StatefulWidget {
  final ChatTtsStore store;

  const _LanguagePicker({required this.store});

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  @override
  void initState() {
    super.initState();
    this.widget.store.loadVoices();
  }

  void _select(Box box, String? language) {
    if (language == null || language == _kPhoneLanguage) {
      box.delete(SettingsKeys.ChatTtsLanguage.name);
    } else {
      box.put(SettingsKeys.ChatTtsLanguage.name, language);
    }
    this.widget.store
      ..applySettings()
      ..loadVoices();
  }

  /// The language row the phone's own language reads with - only used
  /// while the bridge hasn't said which voice it reads with
  static ChatTtsLanguage? _phoneLanguage(List<ChatTtsLanguage> languages) {
    final locale = PlatformDispatcher.instance.locale;
    final tag = locale.toLanguageTag();
    for (final language in languages) {
      if (language.language == tag) return language;
    }
    for (final language in languages) {
      if (language.language.split('-').first == locale.languageCode) {
        return language;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ChatTtsLanguage,
        SettingsKeys.ChatTtsVoices,
        SettingsKeys.ChatTtsDetectLanguage,
      ],
      builder: (context, box, child) => Observer(
        builder: (context) {
          final voices = this.widget.store.voices;
          final languages = voices == null
              ? const <ChatTtsLanguage>[]
              : chatTtsLanguages(voices);
          final String? stored =
              box.get(SettingsKeys.ChatTtsLanguage.name) as String?;

          /// A stored language without voices anymore reads with whatever
          /// the bridge falls back to - the row of its default voice
          final ChatTtsLanguage? picked = stored == null
              ? null
              : languages.where((l) => l.language == stored).firstOrNull;
          final String? defaultLanguage =
              this.widget.store.defaultVoice?.language;
          final ChatTtsLanguage? reading =
              picked ??
              languages
                  .where((l) => l.language == defaultLanguage)
                  .firstOrNull ??
              _phoneLanguage(languages);
          final String automatic = Platform.isAndroid
              ? 'Text-to-speech default'
              : 'Phone language';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              BaseDropdown<String>(
                key: const Key('tts-language-dropdown'),
                label: 'Read in',
                value: picked?.language ?? _kPhoneLanguage,
                menuMaxHeight: kChatChannelMenuMaxHeight,
                items: [
                  BaseDropdownItem(
                    value: _kPhoneLanguage,
                    text: picked == null && reading != null
                        ? '$automatic (${reading.languageName})'
                        : automatic,
                  ),
                  for (final language in languages)
                    BaseDropdownItem(
                      value: language.language,
                      text: language.languageName,
                    ),
                ],
                onChanged: (value) => this._select(box, value),
              ),
              if (reading != null)
                ChatTtsVoicePicker(
                  key: const Key('tts-voice-picker'),
                  store: this.widget.store,
                  language: reading,
                  label: 'Voice',
                ),
              if (voices != null &&
                  languages.length > 1 &&
                  box.get(
                        SettingsKeys.ChatTtsDetectLanguage.name,
                        defaultValue: false,
                      ) ==
                      true)
                PressFlash(
                  key: const Key('tts-voices-other-languages'),
                  onTap: () =>
                      showChatTtsVoicesSheet(context, store: this.widget.store),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Voices for other languages'),
                    subtitle: Text(
                      'Which voice detected languages are read with',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(
                      CupertinoIcons.chevron_forward,
                      size: 16.0,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                voices == null
                    ? 'Looking up voices…'
                    : languages.isEmpty
                    ? 'No voices reported by the system.'
                    : '${languages.length} languages installed.',
                key: const Key('tts-language-voice'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              ChatTtsMoreVoicesHelp(store: this.widget.store),
            ],
          );
        },
      ),
    );
  }
}

/// Opens the voice choice for every installed language - the ones
/// detection may switch to
void showChatTtsVoicesSheet(
  BuildContext context, {
  required ChatTtsStore store,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (context) => NativeChatSheetScaffold(
    header: Text(
      'Voices per language',
      style: nativeChatSheetTitleStyle(context),
    ),
    body: Observer(
      builder: (context) {
        final languages = chatTtsLanguages(store.voices ?? const []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages detected in another language are read with the '
              'voice picked here. Automatic picks the best installed one.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final language in languages)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: ChatTtsVoicePicker(
                  key: ValueKey('tts-voice-picker-${language.language}'),
                  store: store,
                  language: language,
                  label: language.languageName,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            ChatTtsMoreVoicesHelp(store: store),
          ],
        );
      },
    ),
  ),
);

/// Voice dropdown for one language ("Automatic" or one of its voices) and
/// a preview button that reads a short sample with the chosen voice
class ChatTtsVoicePicker extends StatelessWidget {
  final ChatTtsStore store;
  final ChatTtsLanguage language;
  final String label;

  const ChatTtsVoicePicker({
    super.key,
    required this.store,
    required this.language,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool ios = Platform.isIOS;
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ChatTtsVoices],
      builder: (context, box, child) {
        final String? pick = this.store.voicePicks[this.language.language];
        final bool installed =
            pick != null && this.language.voices.any((v) => v.id == pick);
        final voices = [...this.language.voices]
          ..sort(
            (a, b) => chatTtsVoiceLabel(
              a,
              ios: ios,
            ).compareTo(chatTtsVoiceLabel(b, ios: ios)),
          );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: BaseDropdown<String>(
                label: this.label,
                value: installed ? pick : _kAutomaticVoice,
                menuMaxHeight: kChatChannelMenuMaxHeight,
                items: [
                  BaseDropdownItem(
                    value: _kAutomaticVoice,
                    text: installed
                        ? 'Automatic'
                        : 'Automatic (${chatTtsVoiceLabel(this.language.best, ios: ios)})',
                  ),
                  for (final voice in voices)
                    BaseDropdownItem(
                      value: voice.id,
                      text: chatTtsVoiceLabel(voice, ios: ios),
                    ),
                ],
                onChanged: (value) => this.store.setVoicePick(
                  this.language.language,
                  value == _kAutomaticVoice ? null : value,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Preview the ${this.language.languageName} voice',
              excludeSemantics: true,
              child: Pressable(
                key: Key('tts-voice-preview-${this.language.language}'),
                haptic: true,
                springy: false,
                onTap: () => this.store.previewVoice(
                  language: this.language.language,
                  voiceId: installed ? pick : null,
                ),
                child: SizedBox(
                  width: kMinInteractiveDimensionCupertino,
                  height: kMinInteractiveDimensionCupertino,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.play_circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dropdown value for "pick the best installed voice"
const String _kAutomaticVoice = '';

/// Where better / more voices come from, per platform. iOS can't link
/// into its voice settings (only private URLs exist), so it's directions;
/// Android opens the text-to-speech settings / voice data download.
class ChatTtsMoreVoicesHelp extends StatelessWidget {
  final ChatTtsStore store;

  const ChatTtsMoreVoicesHelp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;
    if (Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          'More and better voices: open the Settings app and search for '
          '"Voices" - the menu moves between iOS versions (it has been under '
          'Accessibility, e.g. Spoken Content or Live Speech). Enhanced and '
          'Premium voices are a download but sound much more natural; they '
          'show up here afterwards and are picked automatically.',
          key: const Key('tts-voices-help'),
          style: style,
        ),
      );
    }
    return Column(
      key: const Key('tts-voices-help'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Voices come from your phone\'s speech engine (e.g. Google). Voice '
          'data for more languages and higher quality voices is installed '
          'there - use the buttons below, or search the Settings app for '
          '"text-to-speech" (menus differ between phones). Voices marked '
          '"needs internet" use mobile data while reading.',
          style: style,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            TextButton(
              onPressed: this.store.openTtsSettings,
              child: const Text('Text-to-speech settings'),
            ),
            TextButton(
              onPressed: this.store.installVoiceData,
              child: const Text('Install voice data'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TtsSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _TtsSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                this.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              this.valueLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColors.highlightText,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: this.value.clamp(this.min, this.max),
            min: this.min,
            max: this.max,
            divisions: this.divisions,
            onChanged: this.onChanged,
          ),
        ),
      ],
    );
  }
}

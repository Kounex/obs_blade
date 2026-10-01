import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/pro_store.dart';
import '../../../../../stores/views/chat_tts.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/chat_tts/chat_tts_utterance.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/overlay_handler.dart';
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
/// chip next to it jumps to the latest message. The first switch-on tells
/// once that holding the speaker opens the settings. Pro only (the native
/// engines it reads are).
class ChatTtsButton extends StatelessWidget {
  const ChatTtsButton({super.key});

  void _toggle(BuildContext context, ChatTtsStore store) {
    store.toggle();
    if (!store.enabled) return;
    final box = Hive.box(HiveKeys.Settings.name);
    if (box.get(
          SettingsKeys.HasUserSeenChatTtsHint.name,
          defaultValue: false,
        ) ==
        true) {
      return;
    }
    box.put(SettingsKeys.HasUserSeenChatTtsHint.name, true);
    OverlayHandler.showStatusOverlay(
      context: context,
      replaceIfActive: true,
      showDuration: const Duration(seconds: 4),
      content: const BaseResult(
        icon: BaseResultIcon.Positive,
        text: 'Reading chat aloud\nHold the speaker for settings',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatTtsStore? store = _ttsStoreOrNull();
    if (store == null || !GetIt.instance.isRegistered<ProStore>()) {
      return const SizedBox.shrink();
    }

    return Observer(
      builder: (context) {
        if (!GetIt.instance<ProStore>().isPro) return const SizedBox.shrink();
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
                        const Icon(CupertinoIcons.forward_end_fill, size: 12.0),
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
                onLongPress: () => showChatTtsSheet(context),
                child: Pressable(
                  haptic: true,
                  springy: false,
                  onTap: () => this._toggle(context, store),
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
                        color: on ? accent : Theme.of(context).disabledColor,
                      ),
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

/// The text-to-speech settings - the sheet body and the options-sheet page
/// share it
class ChatTtsSettingsRows extends StatelessWidget {
  /// The short explanation on top - off where the page carries its own
  final bool showIntro;

  const ChatTtsSettingsRows({super.key, this.showIntro = true});

  static const String intro =
      'Reads new messages of the native chat out loud while OBS Blade is '
      'open. It stops when the screen locks.';

  static const List<SettingsKeys> _keys = [
    SettingsKeys.ChatTtsAudience,
    SettingsKeys.ChatTtsReadUsernames,
    SettingsKeys.ChatTtsSkipEmotes,
    SettingsKeys.ChatTtsSkipLinks,
    SettingsKeys.ChatTtsSkipCommands,
    SettingsKeys.ChatTtsReadOwnMessages,
    SettingsKeys.ChatTtsMaxLength,
    SettingsKeys.ChatTtsSpeed,
    SettingsKeys.ChatTtsSkipStale,
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
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;

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
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColors.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
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
              label: 'Max length',
              valueLabel: maxLength == 0 ? 'No limit' : '$maxLength chars',
              value: maxLength.toDouble(),
              min: 0,
              max: 300,
              divisions: 12,
              onChanged: (value) =>
                  set(SettingsKeys.ChatTtsMaxLength, value.round()),
            ),
          ],
        );
      },
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart';

/// Dock toggle for [ChatEmotePickerSheet] — styled like the chat bar's
/// control containers, 44pt touch target. Refocuses the dock's field when
/// the sheet closed after Done (compose continuation), not on a bare
/// dismiss.
class ChatEmotePickerButton extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Whether the persisted token carries the read-emotes scope — the sheet
  /// shows a re-login CTA instead of first-party sections when false.
  final bool canReadEmotes;

  /// Brand accent (CTA text), same value the dock gets.
  final Color accentColor;

  /// Starts the re-login flow from the sheet's pre-upgrade CTA.
  final VoidCallback onRelogin;

  const ChatEmotePickerButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canReadEmotes,
    required this.accentColor,
    required this.onRelogin,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Emotes',
      child: Pressable(
        haptic: true,
        onTap: () async {
          /// Drop the dock's keyboard first — the sheet rides above an
          /// open keyboard (ModalHandler viewInsets padding), and on
          /// small phones sheet + keyboard would overflow vertically.
          /// After Done the field is refocused below.
          this.focusNode.unfocus();
          final applied = await ModalHandler.showBaseBottomSheet<bool>(
            context: context,
            barrierDismissible: true,
            maxHeightFraction: 0.85,
            builder: (context) => ChatEmotePickerSheet(
              controller: this.controller,
              canReadEmotes: this.canReadEmotes,
              accentColor: this.accentColor,
              onRelogin: this.onRelogin,
            ),
          );
          if ((applied ?? false) && this.focusNode.canRequestFocus) {
            this.focusNode.requestFocus();
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          /// Bottom-align with the growing text field / send control — the
          /// 44pt box is the hit target; chrome matches
          /// [kNativeChatDockControlSize].
          alignment: Alignment.bottomCenter,
          child: Container(
            width: kNativeChatDockControlSize,
            height: kNativeChatDockControlSize,
            decoration: BoxDecoration(
              color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                width: 0.0,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.smiley,
              size: 20.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Emote picker sheet: first-party sections (Channel / Global) from
/// [TwitchEmoteStore] plus the combined third-party section from
/// [ThirdPartyEmoteStore] (only when the third-party toggle is on).
/// Emote taps append into a local draft; [Done] writes it back to
/// [controller] and pops with `true` so the caller can refocus the dock.
class ChatEmotePickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final bool canReadEmotes;
  final Color accentColor;

  /// Starts the re-login flow — invoked after the sheet pops itself.
  final VoidCallback onRelogin;

  const ChatEmotePickerSheet({
    super.key,
    required this.controller,
    required this.canReadEmotes,
    required this.accentColor,
    required this.onRelogin,
  });

  @override
  State<ChatEmotePickerSheet> createState() => _ChatEmotePickerSheetState();
}

class _ChatEmotePickerSheetState extends State<ChatEmotePickerSheet> {
  String _query = '';
  late final TextEditingController _draft;
  late final FocusNode _draftFocus;

  @override
  void initState() {
    super.initState();
    final seed = this.widget.controller.text;
    this._draft = TextEditingController(text: seed)
      ..selection = TextSelection.collapsed(offset: seed.length);
    this._draftFocus = FocusNode();
  }

  @override
  void dispose() {
    this._draft.dispose();
    this._draftFocus.dispose();
    super.dispose();
  }

  /// (code, imageUrl) pairs of one section.
  List<(String, String)> _filtered(
    Iterable<(String, String)> entries,
    String query,
  ) =>
      [
        for (final entry in entries)
          if (query.isEmpty || entry.$1.toLowerCase().contains(query)) entry,
      ];

  void _insert(String code) {
    final insert = '$code ';
    final selection = this._draft.selection;
    if (selection.isValid) {
      this._draft
        ..text = this._draft.text.replaceRange(
              selection.start,
              selection.end,
              insert,
            )
        ..selection = TextSelection.collapsed(
          offset: selection.start + insert.length,
        );
    } else {
      this._draft
        ..text = this._draft.text + insert
        ..selection =
            TextSelection.collapsed(offset: this._draft.text.length);
    }
  }

  void _done() {
    final text = this._draft.text;
    this.widget.controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          NativeChatTextField(
            onChanged: (value) => this.setState(() => this._query = value),
            hintText: 'Search emotes…',
            prefixIcon: const Icon(CupertinoIcons.search, size: 16.0),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36.0,
              minHeight: 0.0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 280.0,
            child: Observer(
              builder: (context) {
                final emoteStore = GetIt.instance<TwitchEmoteStore>();
                final thirdPartyStore =
                    GetIt.instance<ThirdPartyEmoteStore>();
                final chatStore = GetIt.instance<TwitchChatStore>();
                final broadcasterId = chatStore.user == null
                    ? ''
                    : chatStore.effectiveBroadcasterId;

                /// Tracked so catalogs landing while the sheet is open
                /// pop in once.
                // ignore: unused_local_variable
                final catalogVersions = emoteStore.catalogVersion +
                    thirdPartyStore.catalogVersion;

                return HiveBuilder<dynamic>(
                  hiveKey: HiveKeys.Settings,
                  rebuildKeys: const [
                    SettingsKeys.TwitchChatThirdPartyEmotes,
                  ],
                  builder: (context, settingsBox, child) {
                    final query = this._query.trim().toLowerCase();

                    final thirdPartyEntries = (settingsBox.get(
                      SettingsKeys.TwitchChatThirdPartyEmotes.name,
                      defaultValue: true,
                    ) as bool)
                        ? this._filtered(
                            [
                              for (final emote in thirdPartyStore
                                  .emotesFor(broadcasterId))
                                (emote.name, emote.imageUrl),
                            ]..sort((a, b) => a.$1.compareTo(b.$1)),
                            query,
                          )
                        : const <(String, String)>[];

                    final sections = <(String, List<(String, String)>)>[
                      if (this.widget.canReadEmotes) ...[
                        (
                          'Channel',
                          this._filtered(
                            [
                              for (final emote
                                  in emoteStore.channelEmotes)
                                (emote.name, twitchEmoteUrl(emote.id)),
                            ],
                            query,
                          ),
                        ),
                        (
                          'Global',
                          this._filtered(
                            [
                              for (final emote
                                  in emoteStore.globalEmotes)
                                (emote.name, twitchEmoteUrl(emote.id)),
                            ],
                            query,
                          ),
                        ),
                      ],
                      ('Third-party (7TV/BTTV)', thirdPartyEntries),
                    ].where((section) => section.$2.isNotEmpty).toList();

                    return ListView(
                      children: [
                        if (!this.widget.canReadEmotes) ...[
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.lock_fill,
                                size: 14.0,
                                color: this.widget.accentColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Log in again to load your Twitch emotes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                              Pressable(
                                haptic: true,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  this.widget.onRelogin();
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight:
                                        kMinInteractiveDimensionCupertino,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Re-login',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: this.widget.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (this.widget.canReadEmotes &&
                            emoteStore.isLoading &&
                            emoteStore.channelEmotes.isEmpty &&
                            emoteStore.globalEmotes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: StylingHelper.isApple(context)
                                  ? const CupertinoActivityIndicator()
                                  : const SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                            ),
                          )
                        else if (sections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Text(
                                'No emotes available',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                        else
                          for (final section in sections) ...[
                            Text(
                              section.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            GridView(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 56.0,
                                mainAxisSpacing: AppSpacing.xs,
                                crossAxisSpacing: AppSpacing.xs,
                              ),
                              children: [
                                for (final emote in section.$2)
                                  _EmoteCell(
                                    code: emote.$1,
                                    imageUrl: emote.$2,
                                    onTap: () => this._insert(emote.$1),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: NativeChatTextField(
                    fieldKey: const Key('emote-draft-field'),
                    controller: this._draft,
                    focusNode: this._draftFocus,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 500,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => this._done(),
                    hintText: 'Add emotes…',
                    focusBorderColor: this.widget.accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Pressable(
                  haptic: true,
                  onTap: this._done,
                  child: Container(
                    key: const Key('emote-done-button'),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: kMinInteractiveDimensionCupertino,
                    ),
                    decoration: BoxDecoration(
                      color: this.widget.accentColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'Done',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One selectable emote in [ChatEmotePickerSheet] — 2x image with the code
/// as tooltip and as fallback text when the image fails (same policy as
/// the message rows).
class _EmoteCell extends StatelessWidget {
  final String code;
  final String imageUrl;
  final VoidCallback onTap;

  const _EmoteCell({
    required this.code,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: this.code,
      child: Pressable(
        haptic: true,
        onTap: this.onTap,
        child: Center(
          child: Image.network(
            this.imageUrl,
            height: 32.0,
            width: 32.0,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              this.code,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

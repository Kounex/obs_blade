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

/// Dock toggle for [ChatEmotePickerSheet] — styled like the chat bar's
/// control containers, 44pt touch target. Refocuses the dock's field when
/// the sheet closed after an insert (compose continuation), not on a bare
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
          /// After an insert the field is refocused below.
          this.focusNode.unfocus();
          final inserted = await ModalHandler.showBaseBottomSheet<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => ChatEmotePickerSheet(
              controller: this.controller,
              canReadEmotes: this.canReadEmotes,
              accentColor: this.accentColor,
              onRelogin: this.onRelogin,
            ),
          );
          if ((inserted ?? false) && this.focusNode.canRequestFocus) {
            this.focusNode.requestFocus();
          }
        },
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: const Icon(
            CupertinoIcons.smiley,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

/// Emote picker sheet: first-party sections (Channel / Global) from
/// [TwitchEmoteStore] plus the combined third-party section from
/// [ThirdPartyEmoteStore] (only when the third-party toggle is on).
/// Tapping an emote inserts `code + ' '` into [controller] at the cursor
/// and pops with `true` so the caller can refocus the dock.
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

  /// Set on the first insert — a second tap landing inside the sheet's exit
  /// animation must not re-insert and re-pop (the double pop trips a
  /// navigator assert in debug builds).
  bool _inserted = false;

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
    if (_inserted) return;
    _inserted = true;
    final controller = this.widget.controller;
    final insert = '$code ';
    final selection = controller.selection;
    if (selection.isValid) {
      controller
        ..text = controller.text.replaceRange(
          selection.start,
          selection.end,
          insert,
        )
        ..selection = TextSelection.collapsed(
          offset: selection.start + insert.length,
        );
    } else {
      controller
        ..text = controller.text + insert
        ..selection =
            TextSelection.collapsed(offset: controller.text.length);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.pill,
      borderSide: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        width: 0.0,
      ),
    );

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
          TextField(
            onChanged: (value) =>
                this.setState(() => this._query = value),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor),
              hintText: 'Search emotes…',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              prefixIcon: const Icon(CupertinoIcons.search, size: 16.0),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36.0,
                minHeight: 0.0,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: inputBorder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 320.0,
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

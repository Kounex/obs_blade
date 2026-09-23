import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart'
    show kickEmoteUrl;
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'chat_emote_picker.dart' show ChatEmoteCell;
import 'native_chat_chrome.dart';
import 'native_chat_input.dart';

/// Dock toggle for [KickEmotePickerSheet] — same chrome/tap contract as
/// Twitch's [ChatEmotePickerButton], minus any scope gate: Kick's first-
/// and third-party emote catalogs are both anonymous reads, so there is
/// no "log in again" state to carry.
class KickEmotePickerButton extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;

  const KickEmotePickerButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Emotes',
      child: Pressable(
        haptic: true,
        onTap: () async {
          this.focusNode.unfocus();
          final applied = await ModalHandler.showBaseBottomSheet<bool>(
            context: context,
            barrierDismissible: true,
            enableDrag: true,
            maxHeightFraction: 0.85,
            builder: (context) => KickEmotePickerSheet(
              controller: this.controller,
              accentColor: this.accentColor,
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
          alignment: Alignment.bottomCenter,
          child: Container(
            width: kNativeChatDockControlSize,
            height: kNativeChatDockControlSize,
            decoration: BoxDecoration(
              color: StylingHelper.lightenDarkenColor(
                Theme.of(context).cardColor,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                width: 0.0,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.smiley, size: 20.0),
          ),
        ),
      ),
    );
  }
}

/// Emote picker sheet for native Kick chat: `Channel` / `Global` /
/// `Emojis` sections from [KickEmoteStore] (`GET /emotes/{slug}`, no
/// auth) plus the `Third-party (7TV)` section from [ThirdPartyEmoteStore]
/// (only when that toggle is on). Same tap-to-append-into-a-draft / Done
/// mechanics as Twitch's picker, no first-party scope gate.
class KickEmotePickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;

  const KickEmotePickerSheet({
    super.key,
    required this.controller,
    required this.accentColor,
  });

  @override
  State<KickEmotePickerSheet> createState() => _KickEmotePickerSheetState();
}

class _KickEmotePickerSheetState extends State<KickEmotePickerSheet> {
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
  ) => [
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
        ..selection = TextSelection.collapsed(offset: this._draft.text.length);
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
    final AppTextColors textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nativeChatSheetDragHandle(context),
          Text('Emotes', style: nativeChatSheetTitleStyle(context)),
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
                final emoteStore = GetIt.instance<KickEmoteStore>();
                final thirdPartyStore = GetIt.instance<ThirdPartyEmoteStore>();
                final chatStore = GetIt.instance<KickChatStore>();
                final broadcasterId =
                    chatStore.channelInfo?.userId?.toString() ?? '';

                /// Tracked so catalogs landing while the sheet is open
                /// pop in once.
                // ignore: unused_local_variable
                final catalogVersions =
                    emoteStore.catalogVersion + thirdPartyStore.catalogVersion;

                return HiveBuilder<dynamic>(
                  hiveKey: HiveKeys.Settings,
                  rebuildKeys: const [SettingsKeys.KickChatThirdPartyEmotes],
                  builder: (context, settingsBox, child) {
                    final query = this._query.trim().toLowerCase();

                    final thirdPartyEntries =
                        (settingsBox.get(
                              SettingsKeys.KickChatThirdPartyEmotes.name,
                              defaultValue: true,
                            )
                            as bool)
                        ? this._filtered(
                            [
                              for (final emote in thirdPartyStore.emotesFor(
                                broadcasterId,
                              ))
                                (emote.name, emote.imageUrl),
                            ]..sort((a, b) => a.$1.compareTo(b.$1)),
                            query,
                          )
                        : const <(String, String)>[];

                    final sections = <(String, List<(String, String)>)>[
                      for (final section in emoteStore.sections)
                        (
                          section.label,
                          this._filtered([
                            for (final emote in section.emotes)
                              (emote.name, kickEmoteUrl(emote.id)),
                          ], query),
                        ),
                      ('Third-party (7TV)', thirdPartyEntries),
                    ].where((section) => section.$2.isNotEmpty).toList();

                    return ListView(
                      children: [
                        if (emoteStore.isLoading && emoteStore.sections.isEmpty)
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
                          StaggeredEntrance(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.smiley,
                                    size: 28.0,
                                    color: textColors.textOrnament,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    query.isEmpty
                                        ? 'No emotes available'
                                        : 'No emotes match your search',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final (index, section) in sections.indexed) ...[
                            StaggeredEntrance(
                              index: index,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.$1.toUpperCase(),
                                    style: nativeChatSheetSectionStyle(context),
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
                                        ChatEmoteCell(
                                          code: emote.$1,
                                          imageUrl: emote.$2,
                                          onTap: () => this._insert(emote.$1),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
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
                    fieldKey: const Key('kick-emote-draft-field'),
                    controller: this._draft,
                    focusNode: this._draftFocus,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 500,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => this._done(),
                    hintText: 'Add emotes…',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Pressable(
                  haptic: true,
                  onTap: this._done,
                  child: Container(
                    key: const Key('kick-emote-done-button'),
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
                        fontSize: 17.0,
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

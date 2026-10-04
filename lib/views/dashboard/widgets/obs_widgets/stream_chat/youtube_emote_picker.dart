import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../stores/views/youtube_emojis.dart';
import '../../../../../utils/youtube/youtube_emoji.dart';
import 'chat_emote_picker.dart' show ChatEmoteCell;
import 'kick_emote_picker.dart' show EmotePickerDockButton;
import 'native_chat_chrome.dart';
import 'chat_type_brand.dart';
import 'native_chat_text_field.dart';
import 'youtube_emoji_spans.dart';

/// Dock toggle for [YouTubeEmotePickerSheet].
class YouTubeEmotePickerButton extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const YouTubeEmotePickerButton({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) => EmotePickerDockButton(
    focusNode: this.focusNode,
    sheet: (context) => YouTubeEmotePickerSheet(controller: this.controller),
  );
}

/// YouTube's emoji picker: recently used, the member emojis of the
/// channel whose chat is open (seen in its chat so far - YouTube only
/// lets that channel's members send them), then YouTube's standard set
/// (bundled + learned from chat pages). A tap appends the `:code:` to a draft,
/// Done hands it to the input - the same mechanics as the Kick picker.
class YouTubeEmotePickerSheet extends StatefulWidget {
  final TextEditingController controller;

  /// The broadcasting channel (member section) - read from the YouTube
  /// chat when null
  final String? channelId;

  const YouTubeEmotePickerSheet({
    super.key,
    required this.controller,
    this.channelId,
  });

  @override
  State<YouTubeEmotePickerSheet> createState() =>
      _YouTubeEmotePickerSheetState();
}

class _YouTubeEmotePickerSheetState extends State<YouTubeEmotePickerSheet> {
  String _query = '';
  late final TextEditingController _draft;

  /// Recently used as the sheet opened - picking reorders the store's
  /// list, the grid must not move under the finger
  late final List<YouTubeEmoji> _recent;

  @override
  void initState() {
    super.initState();
    this._recent = youTubeEmojiStoreOrNull()?.recent ?? const [];
    final seed = this.widget.controller.text;
    this._draft = TextEditingController(text: seed)
      ..selection = TextSelection.collapsed(offset: seed.length);
  }

  @override
  void dispose() {
    this._draft.dispose();
    super.dispose();
  }

  String? get _channelId {
    if (this.widget.channelId != null) return this.widget.channelId;
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<YouTubeChatStore>() ||
        !getIt.checkLazySingletonInstanceExists<YouTubeChatStore>()) {
      return null;
    }
    return getIt<YouTubeChatStore>().selectedLiveChannelId;
  }

  void _insert(YouTubeEmojiStore store, YouTubeEmoji emoji) {
    /// A code glued to the word before it isn't converted by YouTube
    final text = this._draft.text;
    final selection = this._draft.selection;
    final at = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final needsSpace = at > 0 && text[at - 1] != ' ';
    final insert = '${needsSpace ? ' ' : ''}${emoji.code} ';
    if (text.length - (end - at) + insert.length >
        kYouTubeChatMessageMaxLength) {
      HapticFeedback.heavyImpact();
      return;
    }
    this._draft
      ..text = text.replaceRange(at, end, insert)
      ..selection = TextSelection.collapsed(offset: at + insert.length);
    store.used(emoji);
  }

  void _done() {
    final text = this._draft.text;
    this.widget.controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    Navigator.of(context).pop(true);
  }

  bool _matches(YouTubeEmoji emoji, String query) =>
      query.isEmpty ||
      emoji.codes.any((code) => code.toLowerCase().contains(query));

  @override
  Widget build(BuildContext context) {
    final store = youTubeEmojiStoreOrNull();
    final textColors =
        Theme.of(context).extension<AppTextColors>() ?? AppTextColors.standard;
    final pixels = (48.0 * MediaQuery.devicePixelRatioOf(context)).ceil();

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
            child: store == null
                ? const SizedBox.shrink()
                : Observer(
                    builder: (context) {
                      final query = this._query.trim().toLowerCase();
                      final members = store.membersOf(this._channelId);
                      final sections = <(String, String?, List<YouTubeEmoji>)>[
                        (
                          'Recent',
                          null,
                          [
                            for (final emoji in this._recent)
                              if (this._matches(emoji, query)) emoji,
                          ],
                        ),

                        /// The channel's own first (like Kick / Twitch channel
                        /// emotes) - YouTube's set is long
                        (
                          'Members only',
                          members.isEmpty
                              ? null
                              : 'Seen in this chat - only the channel\'s '
                                    'members can send these',
                          [
                            for (final emoji in members)
                              if (this._matches(emoji, query)) emoji,
                          ],
                        ),
                        (
                          'YouTube',
                          null,
                          [
                            for (final emoji in store.standard)
                              if (this._matches(emoji, query)) emoji,
                          ],
                        ),
                      ].where((s) => s.$3.isNotEmpty).toList();

                      if (sections.isEmpty) {
                        return Center(
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
                                    ? 'No emotes yet'
                                    : 'No emotes match your search',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        children: [
                          for (final (label, hint, emojis) in sections) ...[
                            Text(
                              label,
                              style: nativeChatSheetSectionStyle(context),
                            ),
                            if (hint != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  hint,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.xs),
                            GridView(
                              key: Key('yt-emoji-section-$label'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 56.0,
                                    mainAxisSpacing: AppSpacing.xs,
                                    crossAxisSpacing: AppSpacing.xs,
                                  ),
                              children: [
                                for (final emoji in emojis)
                                  ChatEmoteCell(
                                    code: emoji.code,
                                    imageUrl: emoji.imageUrl(pixels),
                                    onTap: () => this._insert(store, emoji),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
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
                    fieldKey: const Key('yt-emoji-draft-field'),
                    controller: this._draft,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: kYouTubeChatMessageMaxLength,
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
                    key: const Key('yt-emoji-done'),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: kMinInteractiveDimensionCupertino,
                    ),
                    decoration: BoxDecoration(
                      color:
                          ChatType.YouTube.brandColor ??
                          Theme.of(context).colorScheme.secondary,
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

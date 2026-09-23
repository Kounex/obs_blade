import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/chat_autocomplete.dart';
import '../../../../../utils/styling_helper.dart';
import 'twitch_chat_message_row.dart' show chatImageFadeIn;

/// Candidate source for [ChatAutocompleteStrip] — engines return every
/// candidate of [kind] (recency / catalog order); ranking happens here.
typedef ChatCompletionSource =
    Iterable<ChatCompletionCandidate> Function(ChatCompletionKind kind);

/// Horizontal chip strip above the native chat input: follows the word at
/// the cursor of [controller] (`@name`, `:emote`, or a bare word ≥ 3
/// chars) and replaces it with the tapped suggestion. Collapses to
/// nothing when there's no query or no match — the dock doesn't jump
/// unless there's something to offer.
class ChatAutocompleteStrip extends StatefulWidget {
  final TextEditingController controller;
  final ChatCompletionSource source;

  const ChatAutocompleteStrip({
    super.key,
    required this.controller,
    required this.source,
  });

  @override
  State<ChatAutocompleteStrip> createState() => _ChatAutocompleteStripState();
}

class _ChatAutocompleteStripState extends State<ChatAutocompleteStrip> {
  ChatCompletionQuery? _query;
  List<ChatCompletionCandidate> _candidates = const [];

  /// Suppresses the strip for the text we just produced by accepting a
  /// suggestion (until the user types again).
  String? _acceptedText;

  @override
  void initState() {
    super.initState();
    this.widget.controller.addListener(this._recompute);
    this._recompute();
  }

  @override
  void didUpdateWidget(ChatAutocompleteStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != this.widget.controller) {
      oldWidget.controller.removeListener(this._recompute);
      this.widget.controller.addListener(this._recompute);
    }
    this._recompute();
  }

  @override
  void dispose() {
    this.widget.controller.removeListener(this._recompute);
    super.dispose();
  }

  void _recompute() {
    final value = this.widget.controller.value;
    ChatCompletionQuery? query;
    var candidates = const <ChatCompletionCandidate>[];
    if (value.text != this._acceptedText &&
        value.selection.isValid &&
        value.selection.isCollapsed) {
      query = chatCompletionQueryAt(value.text, value.selection.baseOffset);
      if (query != null) {
        candidates = rankChatCompletions(
          query.prefix,
          this.widget.source(query.kind),
          allowSubstring: query.explicit,
        );
      }
    }
    if (candidates.isEmpty) query = null;
    if (!this.mounted) return;
    if (query?.start == this._query?.start &&
        query?.end == this._query?.end &&
        _sameLabels(candidates, this._candidates)) {
      return;
    }
    this.setState(() {
      this._query = query;
      this._candidates = candidates;
    });
  }

  static bool _sameLabels(
    List<ChatCompletionCandidate> a,
    List<ChatCompletionCandidate> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) return false;
    }
    return true;
  }

  void _accept(ChatCompletionCandidate candidate) {
    final query = this._query;
    if (query == null) return;
    final result = applyChatCompletion(
      this.widget.controller.text,
      query,
      candidate,
    );
    this._acceptedText = result.text;
    this.widget.controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = this._candidates;
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.bottomCenter,
      child: candidates.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: SizedBox(
                height: 34.0,
                child: ListView.separated(
                  key: const ValueKey('chat-autocomplete-strip'),
                  scrollDirection: Axis.horizontal,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) => _CompletionChip(
                    candidate: candidates[index],
                    onTap: () => this._accept(candidates[index]),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  final ChatCompletionCandidate candidate;
  final VoidCallback onTap;

  const _CompletionChip({required this.candidate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = this.candidate.imageUrl;
    return Pressable(
      haptic: true,
      onTap: this.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null) ...[
              Image.network(
                imageUrl,
                height: 22.0,
                fit: BoxFit.contain,
                frameBuilder: chatImageFadeIn,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              this.candidate.label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../stores/views/third_party_emotes.dart';
import 'chat_link.dart';
import 'twitch_chat_message_row.dart' show chatImageFadeIn;

/// Plain chat text with third-party emote tokens (7TV / BTTV / FFZ)
/// swapped for inline images — shared by the Twitch and Kick rows.
///
/// Split on single spaces so the original spacing survives exactly.
/// Zero-width emotes (Chatterino's `enableZeroWidthEmotes`) that directly
/// follow another third-party emote are stacked on top of it in one
/// [Stack] instead of taking their own slot; a zero-width token with
/// nothing to sit on renders as a normal inline emote.
List<InlineSpan> thirdPartyEmoteTextSpans(
  BuildContext context,
  String text, {
  required ThirdPartyEmoteStore store,
  required String broadcasterId,
  required double emoteSize,
}) {
  final tokens = text.split(' ');
  final spans = <InlineSpan>[];

  /// Layers of the emote group being built (base + overlays) and whether
  /// a separating space is owed before it.
  var layers = <Widget>[];
  var spaceBeforeGroup = false;

  Widget image(String url, String token) => Image.network(
    url,
    height: emoteSize,
    fit: BoxFit.contain,
    frameBuilder: chatImageFadeIn,
    errorBuilder: (_, _, _) => Text(token),
  );

  void flush() {
    if (layers.isEmpty) return;
    if (spaceBeforeGroup) spans.add(const TextSpan(text: ' '));
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: layers.length == 1
            ? layers.single
            : Stack(alignment: Alignment.center, children: layers),
      ),
    );
    layers = <Widget>[];
  }

  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    final emote = store.emote(token, broadcasterId: broadcasterId);
    if (emote != null && emote.zeroWidth && layers.isNotEmpty) {
      /// Overlay: joins the group, swallowing the space before it.
      layers.add(image(emote.imageUrl, token));
      continue;
    }
    flush();
    if (emote != null) {
      spaceBeforeGroup = i > 0;
      layers = [image(emote.imageUrl, token)];
      continue;
    }
    if (i > 0) spans.add(const TextSpan(text: ' '));
    spans.addAll(chatLinkTextSpans(context, token));
  }
  flush();
  return spans;
}

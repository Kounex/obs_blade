import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/youtube_emojis.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_emoji.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_emote_picker.dart';

import '../../test/chat/youtube_chat_message_row_test.dart' show ytMessage;
import 'support/shots_harness.dart';

/// YouTube emojis: rows with codes drawn as images (placeholder squares -
/// no YouTube artwork in the repo), an unknown code as text, and the
/// picker with its member section.
void main() {
  final harness = ShotsHarness();
  late YouTubeEmojiStore store;

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    store = YouTubeEmojiStore(persistence: MemoryYouTubeEmojiPersistence())
      ..addAll(const [
        YouTubeEmoji(
          id: 'UCmembers0000000000000/a',
          codes: [':_hype:', ':hype:'],
          imageBase: 'https://yt3.ggpht.com/hype',
        ),
        YouTubeEmoji(
          id: 'UCmembers0000000000000/b',
          codes: [':_gg:', ':gg:'],
          imageBase: 'https://yt3.ggpht.com/gg',
        ),
      ]);
    GetIt.instance.registerSingleton<YouTubeEmojiStore>(store);
  });
  tearDown(() async {
    store.dispose();
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  /// Every emoji URL the shot can ask for gets a placeholder square in
  /// the image cache (flutter_test answers network images with 400; no
  /// YouTube artwork in the repo)
  Future<void> placeholders(WidgetTester tester) async {
    final image = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawCircle(
        const Offset(32, 32),
        30,
        Paint()..color = const Color(0xFFFF4654),
      );
      return recorder.endRecording().toImage(64, 64);
    });
    final emojis = [...store.standard, ...store.membersOf(_members)];

    /// The two sizes the shots draw: inline at the chat's emote size and
    /// the picker's 48 pt cells, at the harness' 2x
    final rowPixels =
        (NativeChatAppearance.emoteSize(Hive.box(HiveKeys.Settings.name)) * 2)
            .ceil();
    for (final emoji in emojis) {
      for (final pixels in [rowPixels, 96]) {
        imageCache.putIfAbsent(
          NetworkImage(emoji.imageUrl(pixels)),
          () => OneFrameImageStreamCompleter(
            SynchronousFuture(ImageInfo(image: image!.clone())),
          ),
        );
      }
    }
  }

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget child, {
    Size size = kShotPhone,
  }) async {
    await placeholders(tester);
    await harness.shot(tester, name, child, size: size);
  }

  Widget rows() {
    final settings = Hive.box(HiveKeys.Settings.name);
    final medal = store.lookup(':medal-yellow-first-red:') != null
        ? ':medal-yellow-first-red:'
        : store.standard.first.code;
    final messages = [
      ytMessage('1', authorName: 'Remy', text: 'Thanks Remy $medal'),
      ytMessage(
        '2',
        authorName: 'Viewer',
        text: ':yt::face-blue-smiling: that clutch was insane :hype:',
      ),
      ytMessage(
        '3',
        authorName: 'Long Name Viewer',
        text:
            'starts at 10:30:45 tonight, see you there ${store.standard.last.code} '
            'and bring snacks ${store.standard.first.code}',
      ),
      ytMessage(
        '4',
        authorName: 'Newcomer',
        text: 'what is :some-new-emoji: lol',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final message in messages)
            YouTubeChatMessageRow(message: message, settingsBox: settings),
        ],
      ),
    );
  }

  testWidgets('rows', (tester) async {
    await shot(tester, 'youtube_emoji_rows', rows());
  });

  testWidgets('rows narrow', (tester) async {
    await shot(
      tester,
      'youtube_emoji_rows_narrow',
      rows(),
      size: const Size(320, 640),
    );
  });

  testWidgets('picker', (tester) async {
    store.used(store.standard.first);
    await shot(
      tester,
      'youtube_emoji_picker',
      SingleChildScrollView(
        child: YouTubeEmotePickerSheet(
          controller: TextEditingController(text: 'gg'),
          channelId: _members,
        ),
      ),
    );
  });
}

const String _members = 'UCmembers0000000000000';

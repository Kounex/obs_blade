import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/youtube_emojis.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_emoji.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_emote_picker.dart';

import '../persistence/support/hive_test_harness.dart';
import 'youtube_chat_message_row_test.dart' show ytMessage;

const _member = YouTubeEmoji(
  id: 'UCmembers0000000000000/abc',
  codes: [':_hype:', ':hype:'],
  imageBase: 'https://yt3.ggpht.com/hype',
);

const _learned = YouTubeEmoji(
  id: '$kYouTubeStandardEmojiOwner/zz',
  codes: [':zz-test-only-medal:'],
  imageBase: 'https://yt3.ggpht.com/zz',
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late YouTubeEmojiStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yt_emoji_ui');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    store = YouTubeEmojiStore(persistence: MemoryYouTubeEmojiPersistence());
    GetIt.instance.registerSingleton<YouTubeEmojiStore>(store);
  });

  tearDown(() async {
    store.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  List<String> imageUrls(WidgetTester tester) => [
    for (final image in tester.widgetList<Image>(find.byType(Image)))
      if (image.image is NetworkImage) (image.image as NetworkImage).url,
  ];

  testWidgets('row: a known code is an image, the rest stays text', (
    tester,
  ) async {
    final known = store.standard.first;
    await tester.pumpWidget(
      wrap(
        YouTubeChatMessageRow(
          message: ytMessage(
            '1',
            text: 'Thanks Remy ${known.code} at 10:30:45',
          ),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        ),
      ),
    );
    expect(imageUrls(tester).single, startsWith(known.imageBase));
    final text = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) => rich.text.toPlainText())
        .join();
    expect(text, contains('Thanks Remy'));
    expect(text, contains('10:30:45'));
    expect(text, isNot(contains(known.code)));
  });

  testWidgets('row: an unknown code is text until it is learned', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        YouTubeChatMessageRow(
          message: ytMessage('1', text: 'gg :zz-test-only-medal:'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        ),
      ),
    );
    expect(imageUrls(tester), isEmpty);
    store.addAll(const [_learned]);
    await tester.pump();
    expect(imageUrls(tester).single, startsWith('https://yt3.ggpht.com/zz'));
  });

  testWidgets('picker: sections, insert with a space, recently used', (
    tester,
  ) async {
    store.addAll(const [_member]);
    final controller = TextEditingController(text: 'gg');
    await tester.pumpWidget(
      wrap(
        SizedBox(
          height: 700,
          child: YouTubeEmotePickerSheet(
            controller: controller,
            channelId: 'UCmembers0000000000000',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('yt-emoji-section-YouTube')), findsOneWidget);
    expect(
      find.byKey(const Key('yt-emoji-section-Members only')),
      findsOneWidget,
    );
    expect(find.textContaining('only the channel'), findsOneWidget);
    expect(find.byKey(const Key('yt-emoji-section-Recent')), findsNothing);

    final first = store.standard.first;
    await tester.tap(find.byTooltip(first.code).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('yt-emoji-done')));
    await tester.pump();
    expect(controller.text, 'gg ${first.code} ');
    expect(store.recent.single.id, first.id);
  });

  testWidgets('picker: another channel shows no member section', (
    tester,
  ) async {
    store.addAll(const [_member]);
    await tester.pumpWidget(
      wrap(
        SizedBox(
          height: 700,
          child: YouTubeEmotePickerSheet(
            controller: TextEditingController(),
            channelId: 'UCsomeoneelse000000000',
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('yt-emoji-section-Members only')),
      findsNothing,
    );
  });
}

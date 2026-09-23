import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';

import '../persistence/support/hive_test_harness.dart';

YouTubeEntryNamer namer({int status = 200}) => YouTubeEntryNamer(
  client: MockClient((request) async {
    if (status != 200) return http.Response('', status);
    if (request.url.path == '/feeds/videos.xml') {
      return http.Response(
        '<?xml version="1.0"?><feed><title>NASA</title>'
        '<entry><title>Some video</title></entry></feed>',
        200,
      );
    }
    if (request.url.path == '/@LofiGirl' || request.url.path == '/c/LofiGirl') {
      return http.Response(
        '<html><head>${'x' * 9000}'
        '<meta property="og:title" content="Lofi Girl &amp; Co">',
        200,
      );
    }
    if (request.url.path == '/oembed') {
      return http.Response(
        '{"title":"Live ISS","author_name":"NASA &amp; Friends"}',
        200,
      );
    }
    return http.Response('', 404);
  }),
);

void main() {
  group('YouTubeEntryNamer', () {
    test('@handle and c/ resolve to the channel title, no @', () async {
      expect(
        await namer().nameFor(parseYouTubeTarget('@LofiGirl')!),
        'Lofi Girl & Co',
      );
      expect(
        await namer().nameFor(parseYouTubeTarget('youtube.com/c/LofiGirl')!),
        'Lofi Girl & Co',
      );
    });

    test('an offline lookup falls back to the handle without @', () async {
      final n = YouTubeEntryNamer(
        client: MockClient((_) async => throw StateError('no network')),
      );
      expect(await n.nameFor(parseYouTubeTarget('@LofiGirl')!), 'LofiGirl');
    });

    test('channel id → RSS feed title', () async {
      expect(
        await namer().nameFor(parseYouTubeTarget('UCLA_DiR1FfKNvjuUpBHmylQ')!),
        'NASA',
      );
    });

    test('video → oEmbed channel name', () async {
      expect(
        await namer().nameFor(parseYouTubeTarget('M3HKLzjvKPc')!),
        'NASA & Friends',
      );
    });

    test('lookup failures fall back to a local name', () async {
      final failing = namer(status: 404);
      expect(
        await failing.nameFor(parseYouTubeTarget('UCLA_DiR1FfKNvjuUpBHmylQ')!),
        'UCLA_DiR1FfKNvjuUpBHmylQ',
      );
      expect(
        await failing.nameFor(parseYouTubeTarget('M3HKLzjvKPc')!),
        'Stream M3HKLzjvKPc',
      );
      expect(
        await failing.nameFor(parseYouTubeTarget('youtube.com/c/LofiGirl')!),
        'LofiGirl',
      );
    });

    test('uniqueYouTubeEntryLabel avoids collisions', () {
      expect(uniqueYouTubeEntryLabel('NASA', ['Other']), 'NASA');
      expect(uniqueYouTubeEntryLabel('NASA', ['NASA', 'NASA (2)']), 'NASA (3)');
    });
  });

  group('add dialog', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    Box box() => Hive.box(HiveKeys.Settings.name);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('yt_entry_name_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
    });

    tearDown(() async {
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets('saving without a name uses the channel name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddEditYouTubeUsernameDialog(
                    settingsBox: box(),
                    namer: namer(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, 'M3HKLzjvKPc');
      await tester.runAsync(() async {
        await tester.tap(find.text('Save'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(box().get(SettingsKeys.YouTubeUsernames.name), {
        'NASA & Friends': 'M3HKLzjvKPc',
      });
      expect(
        box().get(SettingsKeys.SelectedYouTubeUsername.name),
        'NASA & Friends',
      );
      expect(find.text('Save'), findsNothing);
    });
  });
}

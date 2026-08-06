import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// `Text` wraps the span passed to `Text.rich` in an outer [TextSpan] that
/// carries the ambient style, so the row's spans sit one level down.
List<WidgetSpan> collectWidgetSpans(InlineSpan span) {
  final spans = <WidgetSpan>[];
  void visit(InlineSpan s) {
    if (s is WidgetSpan) spans.add(s);
    if (s is TextSpan) s.children?.forEach(visit);
  }

  visit(span);
  return spans;
}

ChatMessageEvent textEvent(String id, String author, String text) =>
    ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: id,
      chatterUserLogin: author.toLowerCase(),
      chatterUserName: author,
      messageId: id,
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

ChatMessageEvent badgeEvent() => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'modder',
      chatterUserName: 'Modder',
      messageId: '1',
      message: ChatMessageText(
        text: 'secured',
        fragments: [ChatMessageFragment(type: 'text', text: 'secured')],
      ),
      badges: const [ChatMessageBadge(setId: 'moderator', id: '1')],
    );

void main() {
  late TwitchChatStore store;
  late TwitchBadgeStore badgeStore;
  late ThirdPartyEmoteStore emoteStore;
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_chat_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox(HiveKeys.Settings.name);

    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    badgeStore = TwitchBadgeStore(service: FakeTwitchBadgeService());
    GetIt.instance.registerSingleton<TwitchBadgeStore>(badgeStore);
    emoteStore = ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(emoteStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TwitchChatMessageRow', () {
    testWidgets('renders author and text', (tester) async {
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Viewer32: Hi chat');
    });

    testWidgets('emote fragment becomes an inline network image', (tester) async {
      final event = ChatMessageEvent(
        broadcasterUserId: 'b1',
        chatterUserId: '1',
        chatterUserLogin: 'emoter',
        chatterUserName: 'Emoter',
        messageId: '1',
        message: ChatMessageText(
          text: 'Hello Kappa',
          fragments: [
            ChatMessageFragment(type: 'text', text: 'Hello '),
            ChatMessageFragment(
              type: 'emote',
              text: 'Kappa',
              emote: ChatFragmentEmote(id: '25'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: event,
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final widgetSpan = collectWidgetSpans(richText.text).single;
      final image = widgetSpan.child as Image;
      expect(
        (image.image as NetworkImage).url,
        'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0',
      );
    });

    testWidgets('renders the badge image before the author', (tester) async {
      badgeStore.globalBadges['moderator'] = {
        '1': FakeTwitchBadgeService.moderatorSet.versions.single,
      };

      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: badgeEvent(),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));

      /// `toPlainText` renders a WidgetSpan as the object replacement
      /// character — the badge sits before the author.
      expect(richText.text.toPlainText(), '\u{FFFC}Modder: secured');
      final badgeSpan = collectWidgetSpans(richText.text).single;
      final image = (badgeSpan.child as Padding).child as Image;
      expect(
        (image.image as NetworkImage).url,
        'https://badges.example/mod/2x.png',
      );
    });

    testWidgets('a disabled badge category is hidden', (tester) async {
      badgeStore.globalBadges['moderator'] = {
        '1': FakeTwitchBadgeService.moderatorSet.versions.single,
      };

      /// Real file I/O never completes inside the test body's FakeAsync
      /// zone — runAsync escapes it (same pattern as the retry test below)
      await tester.runAsync(() async {
        await Hive.box(HiveKeys.Settings.name)
            .put(SettingsKeys.TwitchChatBadgeModerator.name, false);
      });

      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: badgeEvent(),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Modder: secured');
      expect(collectWidgetSpans(richText.text), isEmpty);
    });

    testWidgets('unknown badges are skipped', (tester) async {
      /// Catalog deliberately left empty
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: badgeEvent(),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Modder: secured');
      expect(collectWidgetSpans(richText.text), isEmpty);
    });
  });

  group('NativeTwitchChatView', () {
    testWidgets('connecting state', (tester) async {
      store.chatConnection = TwitchChatConnectionState.connecting;

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      expect(find.text('Connecting to Twitch chat…'), findsOneWidget);
    });

    testWidgets('renders buffered messages', (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.messages.add(textEvent('1', 'Viewer32', 'Hi chat'));
      store.messages.add(textEvent('2', 'Emoter', 'Hello Kappa'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((r) => r.text.toPlainText());
      expect(
        richTexts,
        containsAll(<String>['Viewer32: Hi chat', 'Emoter: Hello Kappa']),
      );
    });

    testWidgets('failed state offers a retry that reconnects', (tester) async {
      /// Logged in with a still-valid stored token → connectChat proceeds
      /// without a refresh call and stays in `connecting` (the fake
      /// EventSub never reports a state change)
      store.authState = TwitchAuthState.loggedIn;
      store.user = FakeTwitchAuthService.user;

      /// Real file I/O never completes inside the test body's FakeAsync
      /// zone (setUp/tearDown run outside it) — runAsync escapes it
      await tester.runAsync(() async {
        await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
          TwitchAuth.kBoxKey,
          TwitchAuth(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
            scopes: const ['user:read:chat'],
            userId: 'user-1',
          ),
        );
      });
      store.chatConnection = TwitchChatConnectionState.failed;
      store.chatError = 'Could not connect to Twitch chat';

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      expect(find.text('Could not connect to Twitch chat'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(store.chatConnection, TwitchChatConnectionState.connecting);
    });
  });
}

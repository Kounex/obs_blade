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
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_notification_row.dart';

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

/// Finds the first TextSpan carrying exactly [text] (the row's spans sit
/// one level down inside `Text.rich`'s wrapper).
TextSpan findTextSpan(InlineSpan root, String text) {
  TextSpan? found;
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text == text) found ??= span;
      span.children?.forEach(visit);
    }
  }

  visit(root);
  if (found == null) throw StateError('no TextSpan with text "$text"');
  return found!;
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

ChatMessageEvent mentionEvent({
  required String id,
  required String author,
  required String mentionedUserId,
  required String mentionText,
}) =>
    ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: id,
      chatterUserLogin: author.toLowerCase(),
      chatterUserName: author,
      messageId: id,
      message: ChatMessageText(
        text: '$mentionText hi',
        fragments: [
          ChatMessageFragment(
            type: 'mention',
            text: mentionText,
            mention: ChatFragmentMention(
              userId: mentionedUserId,
              userLogin: mentionText.substring(1).toLowerCase(),
              userName: mentionText.substring(1),
            ),
          ),
          const ChatMessageFragment(type: 'text', text: ' hi'),
        ],
      ),
    );

ChatNotificationEvent noticeEvent({
  required String id,
  required String author,
  String systemMessage = '',
}) =>
    ChatNotificationEvent(
      broadcasterUserId: 'b1',
      chatterUserId: id,
      chatterUserLogin: author.toLowerCase(),
      chatterUserName: author,
      messageId: id,
      systemMessage: systemMessage.isEmpty
          ? '$author subscribed at Tier 1.'
          : systemMessage,
      noticeType: 'sub',
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
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          FakeTwitchEventSubService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    badgeStore = TwitchBadgeStore(service: FakeTwitchBadgeService());
    GetIt.instance.registerSingleton<TwitchBadgeStore>(badgeStore);
    emoteStore = ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(emoteStore);
  });

  tearDown(() async {
    await store.dispose();
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

    testWidgets('a deleted message shows dimmed content plus the marker',
        (tester) async {
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
          isDeleted: true,
        )),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));

      /// Content stays (emote included) — only the marker is appended.
      expect(richText.text.toPlainText(), 'Emoter: Hello \u{FFFC} —Deleted');
      /// Twitch mod view: content non-italic and dimmed harder than the
      /// (italic) marker; the emote dims via a matching Opacity. The text
      /// fragment is split for third-party emote tokenization, so the
      /// first token carries the dimmed style.
      final marker = findTextSpan(richText.text, ' —Deleted');
      expect(marker.style?.fontStyle, FontStyle.italic);
      final content = findTextSpan(richText.text, 'Hello');
      expect(content.style?.fontStyle, isNull);
      expect(content.style!.color!.a, lessThan(marker.style!.color!.a));
      final emote = collectWidgetSpans(richText.text).single;
      expect(emote.child, isA<Opacity>());
      expect((emote.child as Opacity).opacity, 0.5);
    });

    testWidgets('tapping a deleted row with an actor fires the callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          deletedActor: 'Cool_Mod',
          onDeletedTap: () => tapped = true,
        )),
      );

      await tester.tap(find.byType(TwitchChatMessageRow));
      expect(tapped, isTrue);
    });

    testWidgets('an expanded deleted row reveals who deleted it',
        (tester) async {
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          deletedActor: 'Cool_Mod',
          isDeletedExpanded: true,
        )),
      );

      expect(
        find.text("Cool_Mod deleted Viewer32's message"),
        findsOneWidget,
      );
    });

    testWidgets('a purged message (no actor) is not tappable, no reveal',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          isDeleted: true,
          isDeletedExpanded: true,
          onDeletedTap: () => tapped = true,
        )),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.textContaining('deleted Viewer32'), findsNothing);

      await tester.tap(find.byType(TwitchChatMessageRow));
      expect(tapped, isFalse);
    });

    testWidgets('author tap fires the card callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onAuthorTap: () => tapped = true,
        )),
      );

      await tester.tap(find.text('Viewer32'));
      expect(tapped, isTrue);
    });

    testWidgets('mention tap fires the card callback with that user id',
        (tester) async {
      String? tappedId;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: mentionEvent(
            id: '1',
            author: 'Viewer32',
            mentionedUserId: 'u2',
            mentionText: '@Bob',
          ),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onMentionTap: (id) => tappedId = id,
        )),
      );

      await tester.tap(find.text('@Bob'));
      expect(tappedId, 'u2');
    });

    testWidgets('reply parent @name tap fires mention callback',
        (tester) async {
      String? tappedId;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: ChatMessageEvent(
            broadcasterUserId: 'b1',
            chatterUserId: '1',
            chatterUserLogin: 'viewer32',
            chatterUserName: 'Viewer32',
            messageId: '1',
            message: const ChatMessageText(
              text: 'thanks',
              fragments: [
                ChatMessageFragment(type: 'text', text: 'thanks'),
              ],
            ),
            reply: const ChatMessageReply(
              parentMessageId: 'p1',
              parentMessageBody: 'hello there',
              parentUserId: 'u2',
              parentUserName: 'Bob',
              parentUserLogin: 'bob',
              threadMessageId: 'p1',
              threadUserId: 'u2',
              threadUserName: 'Bob',
              threadUserLogin: 'bob',
            ),
          ),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onMentionTap: (id) => tappedId = id,
        )),
      );

      await tester.tap(find.text('@Bob'));
      expect(tappedId, 'u2');
    });

    testWidgets('long-press fires mod callback; short body tap does not',
        (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onMessageLongPress: () => longPressed = true,
        )),
      );

      await tester.longPress(find.textContaining('Hi chat'));
      expect(longPressed, isTrue);

      longPressed = false;
      await tester.tap(find.textContaining('Hi chat'));
      expect(longPressed, isFalse);
    });

    testWidgets('highlighted row paints the hold wash without extra padding',
        (tester) async {
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          highlighted: true,
        )),
      );

      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(TwitchChatMessageRow),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        box.color,
        TwitchChatMessageRow.holdHighlightColor(
          tester.element(find.byType(TwitchChatMessageRow)),
        ),
      );
      /// Wash wraps existing padding only — no nested highlight inset.
      expect(box.child, isA<Padding>());
    });

    testWidgets('hold wash starts after a short delay, cancels on lift',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onMessageLongPress: () => pressed = true,
        )),
      );

      Color? washColor() {
        final boxes = tester.widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(TwitchChatMessageRow),
            matching: find.byType(ColoredBox),
          ),
        );
        for (final box in boxes) {
          if (box.color != Colors.transparent) return box.color;
        }
        return null;
      }

      final gesture = await tester.startGesture(
        tester.getCenter(find.textContaining('Hi chat')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(washColor(), isNull);
      expect(pressed, isFalse);

      await tester.pump(const Duration(milliseconds: 120));
      expect(
        washColor(),
        TwitchChatMessageRow.holdHighlightColor(
          tester.element(find.byType(TwitchChatMessageRow)),
        ),
      );
      expect(pressed, isFalse);

      await gesture.up();
      await tester.pump();
      expect(washColor(), isNull);
      expect(pressed, isFalse);
    });

    testWidgets('author tap still works when mod long-press is wired',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onAuthorTap: () => tapped = true,
          onMessageLongPress: () {},
        )),
      );

      await tester.tap(find.text('Viewer32'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
        'slow author press still opens the card when mod long-press is wired',
        (tester) async {
      var tapped = false;
      var longPressed = false;
      await tester.pumpWidget(
        wrap(TwitchChatMessageRow(
          event: textEvent('1', 'Viewer32', 'Hi chat'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onAuthorTap: () => tapped = true,
          onMessageLongPress: () => longPressed = true,
        )),
      );

      /// Real taps often outlast the hold-wash delay (~140ms). Parent
      /// setState used to dispose [Pressable] here; local wash must not.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Viewer32')),
      );
      await tester.pump(const Duration(milliseconds: 220));
      await gesture.up();
      await tester.pump();
      expect(tapped, isTrue);
      expect(longPressed, isFalse);
    });
  });

  group('TwitchChatNotificationRow', () {
    testWidgets('notice author tap fires the card callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(TwitchChatNotificationRow(
          event: noticeEvent(id: 'n1', author: 'Alice'),
          settingsBox: Hive.box(HiveKeys.Settings.name),
          onAuthorTap: () => tapped = true,
        )),
      );

      await tester.tap(find.text('Alice'));
      expect(tapped, isTrue);
    });

    testWidgets('applies the same vertical message spacing as chat rows',
        (tester) async {
      final settings = Hive.box(HiveKeys.Settings.name);
      await tester.runAsync(() async {
        await settings.put(SettingsKeys.TwitchChatMessageSpacing.name, 10.0);
      });

      await tester.pumpWidget(
        wrap(TwitchChatNotificationRow(
          event: noticeEvent(id: 'n1', author: 'Alice'),
          settingsBox: settings,
        )),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(TwitchChatNotificationRow),
          matching: find.byWidgetPredicate(
            (widget) => widget is Padding && widget.child is IntrinsicHeight,
          ),
        ),
      );
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 10.0));
    });

    testWidgets('announcement banner shows Announcement, not the author twice',
        (tester) async {
      await tester.pumpWidget(
        wrap(TwitchChatNotificationRow(
          event: ChatNotificationEvent(
            broadcasterUserId: 'b1',
            chatterUserId: 'c1',
            chatterUserLogin: 'alice',
            chatterUserName: 'Alice',
            messageId: 'a1',
            systemMessage: 'Alice: hello stream',
            noticeType: 'announcement',
            message: const ChatMessageText(
              text: 'hello stream',
              fragments: [
                ChatMessageFragment(type: 'text', text: 'hello stream'),
              ],
            ),
          ),
          settingsBox: Hive.box(HiveKeys.Settings.name),
        )),
      );

      expect(find.text('Announcement'), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('hello stream'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
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

      expect(find.text('Viewer32'), findsOneWidget);
      expect(find.textContaining('Hi chat'), findsOneWidget);
      expect(find.text('Emoter'), findsOneWidget);
      expect(find.textContaining('Hello Kappa'), findsOneWidget);
    });

    testWidgets('announce-only buffer leaves the waiting empty state',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatNotificationForTest(
        ChatNotificationEvent(
          broadcasterUserId: 'b1',
          chatterUserId: '1',
          chatterUserLogin: 'viewer32',
          chatterUserName: 'Viewer32',
          messageId: 'a1',
          systemMessage: '',
          noticeType: 'announcement',
          announcement: const ChatNotificationAnnouncement(color: 'orange'),
          message: const ChatMessageText(
            text: 'orange hello',
            fragments: [
              ChatMessageFragment(type: 'text', text: 'orange hello'),
            ],
          ),
        ),
      );

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      expect(find.text('Connected — waiting for messages…'), findsNothing);
      expect(find.text('Announcement'), findsOneWidget);
      expect(find.textContaining('orange hello'), findsOneWidget);
    });

    testWidgets('announce does not paint accent on the next PRIVMSG',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatNotificationForTest(
        ChatNotificationEvent(
          broadcasterUserId: 'b1',
          chatterUserId: '1',
          chatterUserLogin: 'viewer32',
          chatterUserName: 'Viewer32',
          messageId: 'a1',
          systemMessage: '',
          noticeType: 'announcement',
          announcement: const ChatNotificationAnnouncement(color: 'orange'),
          message: const ChatMessageText(
            text: 'announce body',
            fragments: [
              ChatMessageFragment(type: 'text', text: 'announce body'),
            ],
          ),
        ),
      );
      /// Same chatter as the announce, different message id (next PRIVMSG).
      store.messages.add(
        textEvent('1', 'Viewer32', 'plain follow-up').copyWith(
          messageId: 'm2',
          message: const ChatMessageText(
            text: 'plain follow-up',
            fragments: [
              ChatMessageFragment(type: 'text', text: 'plain follow-up'),
            ],
          ),
        ),
      );

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      final followUp = tester.widgetList<TwitchChatMessageRow>(
        find.byType(TwitchChatMessageRow),
      ).firstWhere((row) => !row.compact);
      expect(followUp.accentBarColor, isNull);
      expect(followUp.event.messageId, 'm2');
      expect(find.textContaining('plain follow-up'), findsOneWidget);
      /// Twin chat.message for the announce id is suppressed.
      expect(find.textContaining('announce body'), findsOneWidget);
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

    testWidgets('rows pick up third-party emotes when the catalog lands',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.messages.add(textEvent('1', 'Viewer', 'hi peepoHappy'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      RichText richText = tester
          .widgetList<RichText>(find.descendant(
            of: find.byType(TwitchChatMessageRow),
            matching: find.byType(RichText),
          ))
          .first;
      expect(richText.text.toPlainText(), '\u{FFFC}: hi peepoHappy');

      /// Catalog lands after the rows are already built — the view's
      /// Observer tracks catalogVersion, so rows rebuild once (pop-in).
      emoteStore.globalEmotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
      emoteStore.catalogVersion++;
      await tester.pump();

      richText = tester
          .widgetList<RichText>(find.descendant(
            of: find.byType(TwitchChatMessageRow),
            matching: find.byType(RichText),
          ))
          .first;
      expect(richText.text.toPlainText(), '\u{FFFC}: hi \u{FFFC}');
    });

    testWidgets('turning the toggle off re-renders rows as text',
        (tester) async {
      emoteStore.globalEmotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
      store.chatConnection = TwitchChatConnectionState.live;
      store.messages.add(textEvent('1', 'Viewer', 'hi peepoHappy'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      RichText richText = tester
          .widgetList<RichText>(find.descendant(
            of: find.byType(TwitchChatMessageRow),
            matching: find.byType(RichText),
          ))
          .first;
      expect(richText.text.toPlainText(), '\u{FFFC}: hi \u{FFFC}');

      /// Real file I/O never completes inside the test body's FakeAsync
      /// zone — runAsync escapes it (same pattern as the badge tests).
      await tester.runAsync(() async {
        await Hive.box(HiveKeys.Settings.name)
            .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
      });
      await tester.pump();

      richText = tester
          .widgetList<RichText>(find.descendant(
            of: find.byType(TwitchChatMessageRow),
            matching: find.byType(RichText),
          ))
          .first;
      expect(richText.text.toPlainText(), '\u{FFFC}: hi peepoHappy');
    });

    testWidgets('/clear tombstones the rows and banners between old and new',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));
      store.appendChatMessageForTest(textEvent('2', 'Emoter', 'Hello Kappa'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyChatClear();
      await tester.pump();

      expect(find.text('Chat was cleared by a moderator'), findsOneWidget);
      expect(find.textContaining('Hi chat —Deleted', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('Hello Kappa —Deleted', findRichText: true),
          findsOneWidget);

      /// The banner sorts after the cleared rows, before newer ones.
      store.appendChatMessageForTest(textEvent('3', 'Viewer32', 'fresh'));
      await tester.pump();
      final bannerY = tester
          .getTopLeft(find.text('Chat was cleared by a moderator'))
          .dy;
      final freshY = tester
          .getTopLeft(find.textContaining('fresh', findRichText: true))
          .dy;
      expect(bannerY, lessThan(freshY));
    });

    testWidgets('scrolling up shows the paused chip; tapping it resumes',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      for (var i = 0; i < 50; i++) {
        store.appendChatMessageForTest(textEvent('$i', 'V$i', 'message $i'));
      }

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();
      expect(find.text('Paused ↓'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pump();
      expect(find.text('Paused ↓'), findsOneWidget);
      expect(find.text('New messages ↓'), findsNothing);

      await tester.tap(find.text('Paused ↓'));
      await tester.pumpAndSettle();
      expect(find.text('Paused ↓'), findsNothing);
    });

    testWidgets('a new message while paused flips the chip to the unread pill',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      for (var i = 0; i < 50; i++) {
        store.appendChatMessageForTest(textEvent('$i', 'V$i', 'message $i'));
      }

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 200));
      await tester.pump();
      expect(find.text('Paused ↓'), findsOneWidget);

      store.appendChatMessageForTest(textEvent('50', 'Late', 'new one'));
      await tester.pump();
      await tester.pump();
      expect(find.text('New messages ↓'), findsOneWidget);
      expect(find.text('Paused ↓'), findsNothing);
    });

    testWidgets('tapping a deleted message reveals and collapses the actor',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: '1', targetUserId: '1', userName: 'Cool_Mod'));
      await tester.pump();

      expect(find.text("Cool_Mod deleted Viewer32's message"), findsNothing);

      await tester.tap(find.byType(TwitchChatMessageRow));
      await tester.pump();
      expect(
          find.text("Cool_Mod deleted Viewer32's message"), findsOneWidget);

      /// The expansion survives a lifecycle rebuild (new message arrives).
      store.appendChatMessageForTest(textEvent('2', 'Late', 'fresh'));
      await tester.pump();
      expect(
          find.text("Cool_Mod deleted Viewer32's message"), findsOneWidget);

      await tester.tap(find.byType(TwitchChatMessageRow).first);
      await tester.pump();
      expect(find.text("Cool_Mod deleted Viewer32's message"), findsNothing);
    });

    testWidgets('a purged message shows content but no tap reveal',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.appendChatMessageForTest(textEvent('1', 'Viewer32', 'Hi chat'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));
      await tester.pump();

      store.applyClearUserMessages('1');
      await tester.pump();

      expect(find.text('Viewer32'), findsOneWidget);
      expect(find.textContaining('Hi chat —Deleted', findRichText: true),
          findsOneWidget);

      await tester.tap(find.byType(TwitchChatMessageRow));
      await tester.pump();
      expect(find.textContaining('deleted Viewer32'), findsNothing);
    });
  });
}

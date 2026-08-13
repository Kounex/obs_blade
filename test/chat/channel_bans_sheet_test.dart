import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_bans_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;

  /// Pumps the real entry point behind a button so the sheet runs as a
  /// route. Bounded pumps, not pumpAndSettle — the sheet's load spinner
  /// never lets the frame scheduler settle (same idiom as
  /// channel_mod_sheet_test's settle()).
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showChannelBansSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    // Let refreshBanInbox finish and the Observer rebuild the sheet.
    await settle(tester);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('channel_bans_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    authService.tokenScopes = const [
      'user:read:chat',
      'user:write:chat',
      'moderator:manage:chat_messages',
      'moderator:manage:banned_users',
    ];
    eventSubService = FakeTwitchEventSubService();
    moderationService = FakeTwitchModerationService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________, _________, __________) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      moderationService: moderationService,
      channelService: FakeTwitchChannelService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    await store.startLogin();
    store.chatConnection = TwitchChatConnectionState.live;
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()));
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Grants extra scopes on the persisted token. No save(): the box serves
  /// this same in-memory instance on get(), and a Hive write (real I/O)
  /// would never complete inside testWidgets' fake async zone.
  void grantScopes(List<String> extra) {
    final authBox = Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);
    final auth = authBox.get(TwitchAuth.kBoxKey)!;
    auth.scopes = [...auth.scopes, ...extra];
  }

  testWidgets('renders the request and ban rows for the own channel',
      (tester) async {
    await openSheet(tester);

    expect(find.text('Unban requests'), findsOneWidget);
    expect(find.text('sorry, will behave'), findsOneWidget);
    expect(find.text('Banned users'), findsOneWidget);
    expect(find.text('Permanent ban'), findsOneWidget);
    expect(find.text('spam'), findsOneWidget);
    expect(find.text('Troll'), findsNWidgets(2));
    expect(moderationService.getBansCalls, 1);
    expect(moderationService.unbanRequestsCalls, 1);
  });

  testWidgets('Unban confirms, then drops the user from both sections',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Unban').first);
    await tester.pumpAndSettle();

    expect(find.text('Unban Troll?'), findsOneWidget);
    expect(moderationService.unbanCalls, 0);

    await tester.tap(find.text('Unban').last);
    await tester.pumpAndSettle();

    expect(moderationService.unbanCalls, 1);
    expect(moderationService.lastUnbanUserId, 'bad-1');
    expect(find.text('Troll'), findsNothing);
    expect(find.text('No pending unban requests'), findsOneWidget);
    expect(find.text('No banned users'), findsOneWidget);
  });

  testWidgets('a failed unban keeps the rows and shows a snackbar',
      (tester) async {
    moderationService.unbanThrows = Exception('boom');

    await openSheet(tester);
    await tester.tap(find.text('Unban').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unban').last);
    await tester.pumpAndSettle();

    expect(moderationService.unbanCalls, 1);
    expect(find.text('Troll'), findsNWidgets(2));
    expect(find.text('Could not unban Troll'), findsOneWidget);

    /// Drain the snackbar's dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a moderated channel hides the ban list with a note',
      (tester) async {
    store.moderatedChannelIds.add('chan-mod');
    /// selectChannel persists the selection to Hive — real I/O that never
    /// completes inside testWidgets' fake-async zone; runAsync escapes it.
    await tester.runAsync(() => store.selectChannel('chan-mod'));
    await settle(tester);

    await openSheet(tester);

    expect(find.text('Unban requests'), findsOneWidget);
    expect(find.text('Banned users'), findsNothing);
    expect(
      find.text('The full ban list is only available in your own channel.'),
      findsOneWidget,
    );
    expect(moderationService.getBansCalls, 0);
    expect(moderationService.unbanRequestsCalls, 1);
  });

  testWidgets('empty inbox shows the empty labels', (tester) async {
    moderationService.bannedUsersResult = const [];
    moderationService.unbanRequestsResult = const [];

    await openSheet(tester);

    expect(find.text('No pending unban requests'), findsOneWidget);
    expect(find.text('No banned users'), findsOneWidget);
  });

  testWidgets('without the manage scope a request row keeps the plain '
      'Unban pill', (tester) async {
    await openSheet(tester);

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Deny'), findsNothing);

    /// One Unban on the request row, one on the banned-user row.
    expect(find.text('Unban'), findsNWidgets(2));
  });

  testWidgets('Approve confirms, then resolves the request and lifts the '
      'ban', (tester) async {
    grantScopes(const ['moderator:manage:unban_requests']);
    await openSheet(tester);

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);

    /// The banned-user row keeps its Unban pill.
    expect(find.text('Unban'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text("Approve Troll's request?"), findsOneWidget);
    expect(moderationService.resolveUnbanRequestCalls, 0);

    await tester.tap(find.text('Approve').last);
    await tester.pumpAndSettle();

    expect(moderationService.resolveUnbanRequestCalls, 1);
    expect(moderationService.lastResolveUnbanRequestId, 'req-1');
    expect(moderationService.lastResolveUnbanApproved, isTrue);

    /// An approval drops the request AND the ban.
    expect(find.text('Troll'), findsNothing);
    expect(find.text('No pending unban requests'), findsOneWidget);
    expect(find.text('No banned users'), findsOneWidget);
  });

  testWidgets('Deny resolves the request but keeps the ban', (tester) async {
    grantScopes(const ['moderator:manage:unban_requests']);
    await openSheet(tester);

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(find.text("Deny Troll's request?"), findsOneWidget);

    await tester.tap(find.text('Deny').last);
    await tester.pumpAndSettle();

    expect(moderationService.resolveUnbanRequestCalls, 1);
    expect(moderationService.lastResolveUnbanApproved, isFalse);

    expect(find.text('sorry, will behave'), findsNothing);
    expect(find.text('No pending unban requests'), findsOneWidget);

    /// The ban stays in place.
    expect(find.text('Troll'), findsOneWidget);
    expect(find.text('Permanent ban'), findsOneWidget);
  });

  testWidgets('a failed resolve keeps the request and shows a snackbar',
      (tester) async {
    grantScopes(const ['moderator:manage:unban_requests']);
    moderationService.resolveUnbanRequestThrows = Exception('boom');

    await openSheet(tester);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve').last);
    await tester.pumpAndSettle();

    expect(moderationService.resolveUnbanRequestCalls, 1);
    expect(find.text('sorry, will behave'), findsOneWidget);
    expect(find.text('Could not update the request'), findsOneWidget);

    /// Drain the snackbar's dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

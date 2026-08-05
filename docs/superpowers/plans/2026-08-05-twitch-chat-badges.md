# Twitch Chat Badges + Role Toggles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render Twitch role badges (broadcaster/mod/VIP/subscriber/founder/bits + other) next to usernames in the native chat, with per-category visibility toggles in a "Native chat options" sheet.

**Architecture:** EventSub message DTO gains the already-delivered `badges` array; a session-scoped `TwitchBadgeStore` caches the Helix global + per-channel badge catalogs (fetched with the existing user token, no new scope); `TwitchChatMessageRow` resolves badges at render time via an `Observer`, filtered by Settings-box toggles; a generic options sheet (per-platform body) hosts the toggles — the seam for future native platforms.

**Tech Stack:** Flutter, MobX (`mobx_codegen`), GetIt, freezed 3.x, `package:http` (`MockClient` in tests), Hive CE (Settings box, plain bool keys — no new typeIds).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-05-twitch-chat-badges-design.md` — follow it; this plan is its task decomposition.
- Style: `this.` prefix for field/getter access inside classes; doc comments in the neighbors' tone; `AppSpacing`/`AppRadius`/`AppMotion` tokens (no raw numbers except sizes already conventional like icon/emote sizes); `Pressable` for tappables; ≥44pt touch targets (`kMinInteractiveDimensionCupertino`).
- **No new dependencies** — badge images use `Image.network` (no `cached_network_image`).
- **No `DashboardStore` changes.** No new Hive typeIds.
- Badge failures must never break chat: silent degrade + `GeneralHelper.advLog`.
- Public repo hygiene: no credentials, user ids, or LAN details in code, fixtures, or docs.
- Run everything through the repo wrapper: `./flutterw` (tests, analyze, codegen).
- **Commit per task, do NOT push** (push happens only at wrap-up/handoff).
- Baseline before starting: `./flutterw test` = 108/108 passing; `./flutterw analyze` = 0 errors + exactly 6 pre-existing warnings (`input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2). Every task must end at the same analyze state.
- Codegen (freezed/mobx): `./flutterw pub run build_runner build --delete-conflicting-outputs`. Generated `*.freezed.dart` / `*.g.dart` files are committed in this repo.

---

### Task 1: Model the badges array on ChatMessageEvent

**Files:**
- Modify: `lib/types/classes/twitch/eventsub/channel_chat_message.dart`
- Test: `test/chat/twitch_eventsub_dto_test.dart`

**Interfaces:**
- Consumes: nothing (existing fixture `test/chat/fixtures/twitch/channel_chat_message_text.json` already contains a `badges` array: `moderator/1` info `""`, `subscriber/12` info `"16"`).
- Produces: `ChatMessageBadge({required String setId, required String id, @Default('') String info})`; `ChatMessageEvent.badges` of type `List<ChatMessageBadge>` (defaults to `[]`). Used by Tasks 5–7.

- [ ] **Step 1: Write the failing tests**

Append to the `group('ChatMessageEvent', ...)` in `test/chat/twitch_eventsub_dto_test.dart`:

```dart
    test('parses badges (real docs payload)', () {
      final event = eventFromFixture('channel_chat_message_text.json');

      expect(event.badges, hasLength(2));
      expect(event.badges[0].setId, 'moderator');
      expect(event.badges[0].id, '1');
      expect(event.badges[0].info, '');
      expect(event.badges[1].setId, 'subscriber');
      expect(event.badges[1].id, '12');
      expect(event.badges[1].info, '16');
    });

    test('missing badges key parses as empty', () {
      final event = ChatMessageEvent.fromJson(
        json.decode('''
        {
          "broadcaster_user_id": "1",
          "broadcaster_user_login": "streamer",
          "broadcaster_user_name": "streamer",
          "chatter_user_id": "2",
          "chatter_user_login": "viewer",
          "chatter_user_name": "viewer",
          "message_id": "m1",
          "message": { "text": "hi", "fragments": [] }
        }
        ''') as Map<String, Object?>,
      );

      expect(event.badges, isEmpty);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./flutterw test test/chat/twitch_eventsub_dto_test.dart`
Expected: FAIL — compile error, `badges` getter / `ChatMessageBadge` undefined.

- [ ] **Step 3: Implement the DTO change**

In `lib/types/classes/twitch/eventsub/channel_chat_message.dart`:

1. Update the doc comment above `ChatMessageEvent` — old:

```dart
/// `channel.chat.message` event payload. Badges/cheer/reply are parsed by
/// Twitch's schema but intentionally not modeled in Phase 1.
```

new:

```dart
/// `channel.chat.message` event payload. Cheer/reply are parsed by
/// Twitch's schema but intentionally not modeled.
```

2. Add the `badges` field to the `ChatMessageEvent` factory, after `String? color,`:

```dart
    String? color,
    @Default(<ChatMessageBadge>[]) List<ChatMessageBadge> badges,
```

3. Append the new freezed class at the end of the file (same pattern as the neighbors):

```dart
/// One entry of the payload's `badges` array: the exact lookup key for
/// the badge catalogs is (`setId`, `id`); `info` is set-specific metadata
/// (e.g. subscriber tenure months) and often empty.
@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageBadge with _$ChatMessageBadge {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatMessageBadge({
    required String setId,
    required String id,
    @Default('') String info,
  }) = _ChatMessageBadge;

  factory ChatMessageBadge.fromJson(Map<String, Object?> json) =>
      _$ChatMessageBadgeFromJson(json);
}
```

- [ ] **Step 4: Run codegen**

Run: `./flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: success; `channel_chat_message.freezed.dart` / `.g.dart` regenerated.

- [ ] **Step 5: Run tests to verify they pass**

Run: `./flutterw test test/chat/twitch_eventsub_dto_test.dart`
Expected: PASS (all tests incl. the 2 new ones).

- [ ] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/eventsub/channel_chat_message.dart \
  lib/types/classes/twitch/eventsub/channel_chat_message.freezed.dart \
  lib/types/classes/twitch/eventsub/channel_chat_message.g.dart \
  test/chat/twitch_eventsub_dto_test.dart
git commit -m "feat(chat): model badges on the Twitch chat message DTO"
```

---

### Task 2: Badge catalog DTOs, settings keys, set_id → toggle mapping

**Files:**
- Create: `lib/types/classes/twitch/twitch_chat_badges.dart`
- Modify: `lib/types/enums/settings_keys.dart` (enum entries + `name` map)
- Test: `test/chat/twitch_badge_catalog_test.dart` (create)

**Interfaces:**
- Consumes: `SettingsKeys` enum/name-map pattern from `lib/types/enums/settings_keys.dart`.
- Produces:
  - `TwitchBadgeSet({required String setId, List<TwitchBadgeVersion> versions})` with `TwitchBadgeSet.fromJson`
  - `TwitchBadgeVersion({required String id, required String imageUrl1x, required String imageUrl2x, required String imageUrl4x, String? title})` with `.fromJson`
  - `settingsKeyForBadgeSetId(String setId) → SettingsKeys`
  - `SettingsKeys.TwitchChatBadge{Broadcaster,Moderator,Vip,Subscriber,Founder,Bits,Other}` — used by Tasks 3, 4, 6, 7.

- [ ] **Step 1: Write the failing test**

Create `test/chat/twitch_badge_catalog_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

void main() {
  group('TwitchBadgeSet', () {
    test('parses a badge set with versions (helix shape)', () {
      final set = TwitchBadgeSet.fromJson(
        json.decode('''
        {
          "set_id": "moderator",
          "versions": [
            {
              "id": "1",
              "image_url_1x": "https://static-cdn.jtvnw.net/badges/v1/mod/1",
              "image_url_2x": "https://static-cdn.jtvnw.net/badges/v1/mod/2",
              "image_url_4x": "https://static-cdn.jtvnw.net/badges/v1/mod/3",
              "title": "Moderator",
              "description": "Moderator"
            }
          ]
        }
        ''') as Map<String, Object?>,
      );

      expect(set.setId, 'moderator');
      expect(set.versions, hasLength(1));
      expect(set.versions.single.id, '1');
      expect(set.versions.single.imageUrl2x,
          'https://static-cdn.jtvnw.net/badges/v1/mod/2');
      expect(set.versions.single.title, 'Moderator');
    });

    test('missing versions key parses as empty', () {
      final set = TwitchBadgeSet.fromJson(const {'set_id': 'vip'});
      expect(set.versions, isEmpty);
    });
  });

  group('settingsKeyForBadgeSetId', () {
    test('maps the dedicated categories', () {
      expect(settingsKeyForBadgeSetId('broadcaster'),
          SettingsKeys.TwitchChatBadgeBroadcaster);
      expect(settingsKeyForBadgeSetId('moderator'),
          SettingsKeys.TwitchChatBadgeModerator);
      expect(
          settingsKeyForBadgeSetId('vip'), SettingsKeys.TwitchChatBadgeVip);
      expect(settingsKeyForBadgeSetId('subscriber'),
          SettingsKeys.TwitchChatBadgeSubscriber);
      expect(settingsKeyForBadgeSetId('founder'),
          SettingsKeys.TwitchChatBadgeFounder);
      expect(settingsKeyForBadgeSetId('bits'),
          SettingsKeys.TwitchChatBadgeBits);
    });

    test('unknown set ids fall under Other', () {
      for (final setId
          in ['sub-gifter', 'staff', 'partner', 'premium', 'moments']) {
        expect(settingsKeyForBadgeSetId(setId),
            SettingsKeys.TwitchChatBadgeOther);
      }
    });

    test('badge toggle keys have kebab-case names', () {
      expect(SettingsKeys.TwitchChatBadgeBroadcaster.name,
          'twitch-chat-badge-broadcaster');
      expect(SettingsKeys.TwitchChatBadgeModerator.name,
          'twitch-chat-badge-moderator');
      expect(SettingsKeys.TwitchChatBadgeVip.name, 'twitch-chat-badge-vip');
      expect(SettingsKeys.TwitchChatBadgeSubscriber.name,
          'twitch-chat-badge-subscriber');
      expect(SettingsKeys.TwitchChatBadgeFounder.name,
          'twitch-chat-badge-founder');
      expect(
          SettingsKeys.TwitchChatBadgeBits.name, 'twitch-chat-badge-bits');
      expect(SettingsKeys.TwitchChatBadgeOther.name,
          'twitch-chat-badge-other');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./flutterw test test/chat/twitch_badge_catalog_test.dart`
Expected: FAIL — target of URI doesn't exist (`twitch_chat_badges.dart`).

- [ ] **Step 3: Add the settings keys**

In `lib/types/enums/settings_keys.dart`, insert after the `SelectedOwncastUsername,` enum entry:

```dart
  /// [bool]: Show the broadcaster badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeBroadcaster,

  /// [bool]: Show the moderator badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeModerator,

  /// [bool]: Show the VIP badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeVip,

  /// [bool]: Show the subscriber badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeSubscriber,

  /// [bool]: Show the founder badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeFounder,

  /// [bool]: Show bits (cheer) badges in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeBits,

  /// [bool]: Show all badges not covered by the dedicated toggles
  /// (sub-gifter, staff, partner, premium, event badges, ...).
  /// Active by default
  TwitchChatBadgeOther,
```

and in the `name` map, after `SettingsKeys.SelectedOwncastUsername: 'selected-owncast-username',`:

```dart
        SettingsKeys.TwitchChatBadgeBroadcaster:
            'twitch-chat-badge-broadcaster',
        SettingsKeys.TwitchChatBadgeModerator: 'twitch-chat-badge-moderator',
        SettingsKeys.TwitchChatBadgeVip: 'twitch-chat-badge-vip',
        SettingsKeys.TwitchChatBadgeSubscriber: 'twitch-chat-badge-subscriber',
        SettingsKeys.TwitchChatBadgeFounder: 'twitch-chat-badge-founder',
        SettingsKeys.TwitchChatBadgeBits: 'twitch-chat-badge-bits',
        SettingsKeys.TwitchChatBadgeOther: 'twitch-chat-badge-other',
```

- [ ] **Step 4: Create the catalog DTO file**

Create `lib/types/classes/twitch/twitch_chat_badges.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/settings_keys.dart';

part 'twitch_chat_badges.freezed.dart';
part 'twitch_chat_badges.g.dart';

/// Maps a badge `set_id` to its visibility toggle. The dedicated toggles
/// cover the common roles; everything else (sub-gifter, staff, partner,
/// premium, event badges, ...) falls under [SettingsKeys.TwitchChatBadgeOther].
SettingsKeys settingsKeyForBadgeSetId(String setId) => switch (setId) {
      'broadcaster' => SettingsKeys.TwitchChatBadgeBroadcaster,
      'moderator' => SettingsKeys.TwitchChatBadgeModerator,
      'vip' => SettingsKeys.TwitchChatBadgeVip,
      'subscriber' => SettingsKeys.TwitchChatBadgeSubscriber,
      'founder' => SettingsKeys.TwitchChatBadgeFounder,
      'bits' => SettingsKeys.TwitchChatBadgeBits,
      _ => SettingsKeys.TwitchChatBadgeOther,
    };

/// One badge set of the helix `chat/badges` responses (`data[]`)
@Freezed(fromJson: true, toJson: false)
abstract class TwitchBadgeSet with _$TwitchBadgeSet {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchBadgeSet({
    required String setId,
    @Default(<TwitchBadgeVersion>[]) List<TwitchBadgeVersion> versions,
  }) = _TwitchBadgeSet;

  factory TwitchBadgeSet.fromJson(Map<String, Object?> json) =>
      _$TwitchBadgeSetFromJson(json);
}

/// One version of a badge set (subscriber tenure, bits tier, ...)
@Freezed(fromJson: true, toJson: false)
abstract class TwitchBadgeVersion with _$TwitchBadgeVersion {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchBadgeVersion({
    required String id,
    required String imageUrl1x,
    required String imageUrl2x,
    required String imageUrl4x,
    String? title,
  }) = _TwitchBadgeVersion;

  factory TwitchBadgeVersion.fromJson(Map<String, Object?> json) =>
      _$TwitchBadgeVersionFromJson(json);
}
```

- [ ] **Step 5: Run codegen, then tests**

Run: `./flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: success; `twitch_chat_badges.freezed.dart` / `.g.dart` generated.

Run: `./flutterw test test/chat/twitch_badge_catalog_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/twitch_chat_badges.dart \
  lib/types/classes/twitch/twitch_chat_badges.freezed.dart \
  lib/types/classes/twitch/twitch_chat_badges.g.dart \
  lib/types/enums/settings_keys.dart \
  test/chat/twitch_badge_catalog_test.dart
git commit -m "feat(chat): badge catalog DTOs + visibility toggle settings keys"
```

---

### Task 3: TwitchBadgeService (Helix chat/badges calls)

**Files:**
- Create: `lib/utils/twitch/twitch_badge_service.dart`
- Modify: `lib/utils/twitch/twitch_auth_service.dart` (lift `_kHelixBase` to public `kTwitchHelixBase`)
- Test: `test/chat/twitch_badge_service_test.dart` (create)

**Interfaces:**
- Consumes: `TwitchBadgeSet`/`TwitchBadgeVersion` (Task 2), `TwitchAuthService.helixHeaders`, `TwitchAuthException`, `kTwitchClientId` (`lib/utils/twitch/twitch_auth_service.dart`).
- Produces:
  - `const String kTwitchHelixBase = 'https://api.twitch.tv/helix';` (in `twitch_auth_service.dart`)
  - `TwitchBadgeService({http.Client? client})` with `Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken)` and `Future<List<TwitchBadgeSet>> fetchChannelBadges(String accessToken, String broadcasterId)` — used by Task 4.

- [ ] **Step 1: Write the failing test**

Create `test/chat/twitch_badge_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';

const _kBadgesBody = {
  'data': [
    {
      'set_id': 'subscriber',
      'versions': [
        {
          'id': '12',
          'image_url_1x': 'https://cdn/sub/1.png',
          'image_url_2x': 'https://cdn/sub/2.png',
          'image_url_4x': 'https://cdn/sub/3.png',
          'title': '1-Year Subscriber',
        },
      ],
    },
  ],
};

void main() {
  group('fetchGlobalBadges', () {
    test('calls the global endpoint with helix headers and parses sets',
        () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/chat/badges/global');
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(json.encode(_kBadgesBody), 200);
      });

      final sets = await TwitchBadgeService(client: client)
          .fetchGlobalBadges('token-1');

      expect(sets, hasLength(1));
      expect(sets.single.setId, 'subscriber');
      expect(sets.single.versions.single.imageUrl2x, 'https://cdn/sub/2.png');
    });
  });

  group('fetchChannelBadges', () {
    test('passes the broadcaster id as query param', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://api.twitch.tv/helix/chat/badges?broadcaster_id=user-1');
        return http.Response(json.encode(_kBadgesBody), 200);
      });

      final sets = await TwitchBadgeService(client: client)
          .fetchChannelBadges('token-1', 'user-1');

      expect(sets.single.setId, 'subscriber');
    });

    test('throws TwitchAuthException with status on non-200', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchBadgeService(client: client)
            .fetchChannelBadges('token-1', 'user-1'),
        throwsA(
          isA<TwitchAuthException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./flutterw test test/chat/twitch_badge_service_test.dart`
Expected: FAIL — target of URI doesn't exist (`twitch_badge_service.dart`).

- [ ] **Step 3: Lift the Helix base const**

In `lib/utils/twitch/twitch_auth_service.dart`, replace:

```dart
/// Base for Helix calls (token validation, chat)
const String _kHelixBase = 'https://api.twitch.tv/helix';
```

with:

```dart
/// Base for Helix calls (user info, chat badges)
const String kTwitchHelixBase = 'https://api.twitch.tv/helix';
```

and in `fetchOwnUser`, replace `Uri.parse('$_kHelixBase/users')` with
`Uri.parse('$kTwitchHelixBase/users')`.

- [ ] **Step 4: Create the service**

Create `lib/utils/twitch/twitch_badge_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/badges` endpoints — the global catalog and the per-channel
/// catalog (subscriber tenure / bits tier variants). Any user access token
/// works, no extra scope.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchBadgeService {
  final http.Client _client;

  TwitchBadgeService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken) =>
      this._fetch(
        Uri.parse('$kTwitchHelixBase/chat/badges/global'),
        accessToken,
      );

  Future<List<TwitchBadgeSet>> fetchChannelBadges(
    String accessToken,
    String broadcasterId,
  ) =>
      this._fetch(
        Uri.parse(
            '$kTwitchHelixBase/chat/badges?broadcaster_id=$broadcasterId'),
        accessToken,
      );

  Future<List<TwitchBadgeSet>> _fetch(Uri uri, String accessToken) async {
    final response = await this._client.get(
      uri,
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch chat badges failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List) {
      throw const TwitchAuthException(
          'Fetching Twitch chat badges returned no data');
    }
    return [
      for (final set in data)
        TwitchBadgeSet.fromJson(set as Map<String, Object?>),
    ];
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `./flutterw test test/chat/twitch_badge_service_test.dart test/chat/twitch_auth_service_test.dart`
Expected: PASS (badge service tests + unchanged auth service tests — they assert URLs as strings, the const rename is invisible to them).

- [ ] **Step 6: Commit**

```bash
git add lib/utils/twitch/twitch_badge_service.dart \
  lib/utils/twitch/twitch_auth_service.dart \
  test/chat/twitch_badge_service_test.dart
git commit -m "feat(chat): TwitchBadgeService for the helix badge catalogs"
```

---

### Task 4: TwitchBadgeStore (session catalog cache)

**Files:**
- Create: `lib/stores/views/twitch_badges.dart`
- Modify: `lib/main.dart` (register the store, next to `TwitchChatStore`)
- Modify: `test/chat/support/fake_twitch_services.dart` (add `FakeTwitchBadgeService`)
- Test: `test/chat/twitch_badge_store_test.dart` (create)

**Interfaces:**
- Consumes: `TwitchBadgeService` (Task 3), `TwitchBadgeSet`/`TwitchBadgeVersion` (Task 2), `GeneralHelper.advLog`.
- Produces:
  - `TwitchBadgeStore({TwitchBadgeService? service})`
  - `ObservableMap<String, Map<String, TwitchBadgeVersion>> globalBadges` / `channelBadges` (setId → versionId → version; publicly readable, used by tests and Task 6)
  - `TwitchBadgeVersion? badgeVersion(String setId, String id)` — channel catalog first, global fallback, `null` when unknown
  - `Future<void> fetch({required String accessToken, required String broadcasterId})`
  - `void clear()`
  - `@observable bool isLoading`
  - Used by Tasks 5, 6, 7.

- [ ] **Step 1: Extend the fakes**

Append to `test/chat/support/fake_twitch_services.dart` (add imports for
`package:obs_blade/types/classes/twitch/twitch_chat_badges.dart` and
`package:obs_blade/utils/twitch/twitch_badge_service.dart` at the top):

```dart
class FakeTwitchBadgeService extends TwitchBadgeService {
  List<TwitchBadgeSet> globalSets = const [];
  List<TwitchBadgeSet> channelSets = const [];

  /// When set, the matching fetch throws this error.
  Object? globalThrows;
  Object? channelThrows;

  /// When set, [fetchGlobalBadges] parks on this completer — lets a test
  /// resolve the fetch at a chosen moment (stale-fetch tests).
  Completer<List<TwitchBadgeSet>>? globalGate;

  String? lastAccessToken;
  String? lastBroadcasterId;
  int globalCalls = 0;
  int channelCalls = 0;

  static const moderatorSet = TwitchBadgeSet(
    setId: 'moderator',
    versions: [
      TwitchBadgeVersion(
        id: '1',
        imageUrl1x: 'https://badges.example/mod/1x.png',
        imageUrl2x: 'https://badges.example/mod/2x.png',
        imageUrl4x: 'https://badges.example/mod/4x.png',
        title: 'Moderator',
      ),
    ],
  );

  static const subscriberSet = TwitchBadgeSet(
    setId: 'subscriber',
    versions: [
      TwitchBadgeVersion(
        id: '12',
        imageUrl1x: 'https://badges.example/sub/1x.png',
        imageUrl2x: 'https://badges.example/sub/2x.png',
        imageUrl4x: 'https://badges.example/sub/4x.png',
        title: 'Subscriber',
      ),
    ],
  );

  /// Same set id as [moderatorSet], different image — used to prove the
  /// channel catalog wins over the global one.
  static const moderatorChannelOverrideSet = TwitchBadgeSet(
    setId: 'moderator',
    versions: [
      TwitchBadgeVersion(
        id: '1',
        imageUrl1x: 'https://badges.example/mod-override/1x.png',
        imageUrl2x: 'https://badges.example/mod-override/2x.png',
        imageUrl4x: 'https://badges.example/mod-override/4x.png',
        title: 'Moderator',
      ),
    ],
  );

  @override
  Future<List<TwitchBadgeSet>> fetchGlobalBadges(String accessToken) async {
    this.globalCalls++;
    this.lastAccessToken = accessToken;
    if (this.globalThrows != null) throw this.globalThrows!;
    if (this.globalGate != null) return this.globalGate!.future;
    return this.globalSets;
  }

  @override
  Future<List<TwitchBadgeSet>> fetchChannelBadges(
    String accessToken,
    String broadcasterId,
  ) async {
    this.channelCalls++;
    this.lastBroadcasterId = broadcasterId;
    if (this.channelThrows != null) throw this.channelThrows!;
    return this.channelSets;
  }
}
```

- [ ] **Step 2: Write the failing test**

Create `test/chat/twitch_badge_store_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeTwitchBadgeService service;
  late TwitchBadgeStore store;

  setUp(() {
    service = FakeTwitchBadgeService();
    store = TwitchBadgeStore(service: service);
  });

  test('fetch applies global and channel catalogs', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.subscriberSet];

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(service.lastAccessToken, 'token-1');
    expect(service.lastBroadcasterId, 'user-1');
    expect(store.badgeVersion('moderator', '1')?.imageUrl2x,
        'https://badges.example/mod/2x.png');
    expect(store.badgeVersion('subscriber', '12')?.imageUrl2x,
        'https://badges.example/sub/2x.png');
    expect(store.isLoading, isFalse);
  });

  test('channel catalog wins over global for the same set id', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.moderatorChannelOverrideSet];

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('moderator', '1')?.imageUrl2x,
        'https://badges.example/mod-override/2x.png');
  });

  test('unknown badges resolve to null', () async {
    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('vip', '1'), isNull);
    expect(store.badgeVersion('moderator', '99'), isNull);
  });

  test('a failing channel fetch keeps the global catalog', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelThrows =
        const TwitchAuthException('denied', statusCode: 401);

    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    expect(store.badgeVersion('moderator', '1'), isNotNull);
    expect(store.isLoading, isFalse);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<List<TwitchBadgeSet>>();
    service.globalGate = gate;
    final first = store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');

    service.globalGate = null;
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    await store.fetch(accessToken: 'token-2', broadcasterId: 'user-1');

    gate.complete([FakeTwitchBadgeService.subscriberSet]);
    await first;

    expect(store.badgeVersion('moderator', '1'), isNotNull);
    expect(store.badgeVersion('subscriber', '12'), isNull);
    expect(store.isLoading, isFalse);
  });

  test('clear drops both catalogs', () async {
    service.globalSets = [FakeTwitchBadgeService.moderatorSet];
    service.channelSets = [FakeTwitchBadgeService.subscriberSet];
    await store.fetch(accessToken: 'token-1', broadcasterId: 'user-1');
    expect(store.globalBadges, isNotEmpty);

    store.clear();

    expect(store.globalBadges, isEmpty);
    expect(store.channelBadges, isEmpty);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `./flutterw test test/chat/twitch_badge_store_test.dart`
Expected: FAIL — target of URI doesn't exist (`twitch_badges.dart`).

- [ ] **Step 4: Create the store**

Create `lib/stores/views/twitch_badges.dart`:

```dart
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_badge_service.dart';

part 'twitch_badges.g.dart';

class TwitchBadgeStore = _TwitchBadgeStore with _$TwitchBadgeStore;

/// Session-scoped cache of the Twitch chat badge catalogs (global +
/// per-channel). Refetched on every chat connect, in-memory only — badge
/// failures degrade to "no badges", never to a chat error.
abstract class _TwitchBadgeStore with Store {
  final TwitchBadgeService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _TwitchBadgeStore({TwitchBadgeService? service})
      : _service = service ?? TwitchBadgeService();

  /// Global catalog: setId -> (versionId -> version)
  final ObservableMap<String, Map<String, TwitchBadgeVersion>> globalBadges =
      ObservableMap();

  /// Per-channel catalog: setId -> (versionId -> version)
  final ObservableMap<String, Map<String, TwitchBadgeVersion>> channelBadges =
      ObservableMap();

  @observable
  bool isLoading = false;

  /// Exact (setId, id) lookup — the channel catalog wins over the global
  /// one; null when unknown (the message row skips those silently).
  TwitchBadgeVersion? badgeVersion(String setId, String id) =>
      this.channelBadges[setId]?[id] ?? this.globalBadges[setId]?[id];

  @action
  Future<void> fetch({
    required String accessToken,
    required String broadcasterId,
  }) async {
    final generation = ++this._fetchGeneration;
    this.isLoading = true;

    final results = await Future.wait([
      this._tryFetch(this._service.fetchGlobalBadges(accessToken), 'global'),
      this._tryFetch(
        this._service.fetchChannelBadges(accessToken, broadcasterId),
        'channel',
      ),
    ]);

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [isLoading]) now.
    if (generation != this._fetchGeneration) return;

    this.isLoading = false;
    final globalSets = results[0];
    final channelSets = results[1];
    if (globalSets != null) this._applySets(this.globalBadges, globalSets);
    if (channelSets != null) this._applySets(this.channelBadges, channelSets);
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.isLoading = false;
    this.globalBadges.clear();
    this.channelBadges.clear();
  }

  /// Badges are nice-to-have: a failed endpoint degrades to no badges for
  /// its scope instead of failing the whole fetch.
  Future<List<TwitchBadgeSet>?> _tryFetch(
    Future<List<TwitchBadgeSet>> future,
    String label,
  ) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Twitch badge fetch ($label) failed — $e');
      return null;
    }
  }

  static void _applySets(
    ObservableMap<String, Map<String, TwitchBadgeVersion>> target,
    List<TwitchBadgeSet> sets,
  ) {
    target
      ..clear()
      ..addEntries(
        sets.map(
          (set) => MapEntry(
            set.setId,
            {for (final version in set.versions) version.id: version},
          ),
        ),
      );
  }
}
```

- [ ] **Step 5: Register the store**

In `lib/main.dart` (`_initializeStores`), insert before the `TwitchChatStore`
registration (and add the import `package:obs_blade/stores/views/twitch_badges.dart`):

```dart
  GetIt.instance
      .registerLazySingleton<TwitchBadgeStore>(() => TwitchBadgeStore());
```

- [ ] **Step 6: Run codegen, then tests**

Run: `./flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: success; `lib/stores/views/twitch_badges.g.dart` generated.

Run: `./flutterw test test/chat/twitch_badge_store_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/stores/views/twitch_badges.dart \
  lib/stores/views/twitch_badges.g.dart \
  lib/main.dart \
  test/chat/support/fake_twitch_services.dart \
  test/chat/twitch_badge_store_test.dart
git commit -m "feat(chat): TwitchBadgeStore session catalog cache"
```

---

### Task 5: Trigger badge fetch/clear from TwitchChatStore

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart`
- Test: `test/chat/twitch_chat_store_test.dart`

**Interfaces:**
- Consumes: `TwitchBadgeStore` (Task 4), registered in GetIt (Task 4).
- Produces: new optional constructor param `TwitchBadgeStore Function()? badgeStoreResolver` on `TwitchChatStore` (defaults to `() => GetIt.instance<TwitchBadgeStore>()`); `connectChat()` kicks off a fire-and-forget badge fetch after a successful EventSub connect; `logout()` clears the catalog.

- [ ] **Step 1: Update the test setUp + write the failing tests**

In `test/chat/twitch_chat_store_test.dart`:

1. Add to the imports:

```dart
import 'package:obs_blade/stores/views/twitch_badges.dart';
```

2. Add fields next to the existing `late` declarations:

```dart
  late FakeTwitchBadgeService badgeService;
  late TwitchBadgeStore badgeStore;
```

3. In `setUp`, after `eventSubService = FakeTwitchEventSubService();`, create them and pass the resolver:

```dart
    badgeService = FakeTwitchBadgeService();
    badgeStore = TwitchBadgeStore(service: badgeService);
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___) => eventSubService,
      badgeStoreResolver: () => badgeStore,
    );
```

(replaces the existing `store = TwitchChatStore(...)` — this constructor param
does not exist yet, so every test in the file fails to compile: that is the
failing step.)

4. Append a new group at the end of `main()`:

```dart
  group('badge catalog wiring', () {
    Future<void> seedValidAuth() => authBox().put(
          TwitchAuth.kBoxKey,
          TwitchAuth(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAtMs:
                DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
            scopes: const ['user:read:chat'],
            userId: 'user-1',
          ),
        );

    test('connectChat fetches badges for the logged-in user', () async {
      await seedValidAuth();
      store.authState = TwitchAuthState.loggedIn;
      store.user = FakeTwitchAuthService.user;

      await store.connectChat();

      expect(badgeService.globalCalls, 1);
      expect(badgeService.channelCalls, 1);
      expect(badgeService.lastAccessToken, 'access-1');
      expect(badgeService.lastBroadcasterId, 'user-1');
    });

    test('a failing badge fetch does not affect the chat connection',
        () async {
      badgeService.globalThrows =
          const TwitchAuthException('down', statusCode: 500);
      badgeService.channelThrows =
          const TwitchAuthException('down', statusCode: 500);
      await seedValidAuth();
      store.authState = TwitchAuthState.loggedIn;
      store.user = FakeTwitchAuthService.user;

      await store.connectChat();

      expect(store.chatConnection,
          isNot(TwitchChatConnectionState.failed));
      expect(store.chatError, isNull);
    });

    test('logout clears the badge catalog', () async {
      badgeService.globalSets = [FakeTwitchBadgeService.moderatorSet];
      await badgeStore.fetch(accessToken: 'access-1', broadcasterId: 'user-1');
      expect(badgeStore.globalBadges, isNotEmpty);

      await store.logout();

      expect(badgeStore.globalBadges, isEmpty);
      expect(badgeStore.channelBadges, isEmpty);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile error, `badgeStoreResolver` param undefined.

- [ ] **Step 3: Wire the store**

In `lib/stores/views/twitch_chat.dart`:

1. Add imports:

```dart
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
```

2. Add the field next to `_eventSubFactory`:

```dart
  final TwitchBadgeStore Function() _badgeStoreResolver;
```

3. Extend the constructor — add the optional param and initializer:

```dart
  _TwitchChatStore({
    TwitchAuthService? authService,
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(TwitchEventSubState),
      void Function(String),
    )? eventSubFactory,
    TwitchBadgeStore Function()? badgeStoreResolver,
  })  : _authService = authService ?? TwitchAuthService(),
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                )),
        _badgeStoreResolver = badgeStoreResolver ??
            (() => GetIt.instance<TwitchBadgeStore>());
```

4. In `connectChat()`, directly after `await this._eventSub!.connect(accessToken: token, userId: this.user!.id);` (still inside the `try`), add:

```dart
      /// Badge catalogs are nice-to-have — a fetch problem must never
      /// affect chat, so this is fire-and-forget with logged failures.
      try {
        unawaited(
          this
              ._badgeStoreResolver()
              .fetch(accessToken: token, broadcasterId: this.user!.id)
              .catchError((Object e) {
            GeneralHelper.advLog('Twitch badge fetch failed — $e');
          }),
        );
      } catch (e) {
        GeneralHelper.advLog('Twitch badge fetch could not start — $e');
      }
```

5. In `logout()`, directly after `this.messages.clear();`, add:

```dart
    try {
      this._badgeStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Twitch badge catalog clear failed — $e');
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `./flutterw test test/chat/twitch_chat_store_test.dart`
Expected: PASS (all existing + 3 new tests).

- [ ] **Step 5: Commit**

```bash
git add lib/stores/views/twitch_chat.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): fetch badge catalogs on chat connect, clear on logout"
```

---

### Task 6: Render badges in the message row + view wiring

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart`

**Interfaces:**
- Consumes: `ChatMessageEvent.badges` (Task 1), `TwitchBadgeStore.badgeVersion` (Task 4), `settingsKeyForBadgeSetId` + the 7 `SettingsKeys` (Task 2), `HiveBuilder` (`lib/shared/general/hive_builder.dart`), `HiveKeys.Settings`.
- Produces: `TwitchChatMessageRow({super.key, required ChatMessageEvent event, required Box settingsBox})` — **breaking change** to the row's constructor; the view passes the box from a `HiveBuilder` whose `rebuildKeys` are the 7 badge keys.

- [ ] **Step 1: Update the test file (failing step)**

In `test/chat/native_twitch_chat_view_test.dart`:

1. Add imports:

```dart
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
```

2. Add a field + setUp lines — after `await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);` add:

```dart
    await Hive.openBox(HiveKeys.Settings.name);
```

and after the `TwitchChatStore` registration add:

```dart
    badgeStore = TwitchBadgeStore(service: FakeTwitchBadgeService());
    GetIt.instance.registerSingleton<TwitchBadgeStore>(badgeStore);
```

with the field declaration next to `late TwitchChatStore store;`:

```dart
  late TwitchBadgeStore badgeStore;
```

3. Update every `TwitchChatMessageRow(event: ...)` construction to pass
`settingsBox: Hive.box(HiveKeys.Settings.name)` (two spots in the existing
row tests).

4. Add a helper next to `textEvent`:

```dart
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
```

(`ChatMessageBadge` comes from `channel_chat_message.dart` — already imported.)

5. Append to `group('TwitchChatMessageRow', ...)`:

```dart
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
      expect(richText.text.toPlainText(), 'Modder: secured');
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — compile error, `settingsBox` param undefined.

- [ ] **Step 3: Rewrite the message row**

Replace the full content of
`lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';

/// One chat line: role badges + colored author name + message text with
/// inline emotes. Cheermote/mention fragments fall back to plain text.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  /// Settings box — the badge visibility toggles
  /// ([settingsKeyForBadgeSetId]), read with default-on.
  final Box settingsBox;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
  });

  static const double _emoteSize = 20.0;
  static const double _badgeSize = 18.0;

  Color _authorColor(BuildContext context) {
    final hex = this.event.color;
    if (hex != null && hex.length == 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  }

  /// Badges before the author name, in payload order. Unknown badges
  /// (catalog not loaded yet, new Twitch set) and toggled-off categories
  /// are skipped silently.
  List<InlineSpan> _badgeSpans() {
    if (this.event.badges.isEmpty) return const [];
    final badgeStore = GetIt.instance<TwitchBadgeStore>();
    return [
      for (final badge in this.event.badges)
        if (this.settingsBox.get(
          settingsKeyForBadgeSetId(badge.setId).name,
          defaultValue: true,
        ))
          if (badgeStore.badgeVersion(badge.setId, badge.id)
              case final version?)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
                child: Image.network(
                  version.imageUrl2x,
                  height: _badgeSize,
                  width: _badgeSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
    ];
  }

  List<InlineSpan> _messageSpans() {
    final fragments = this.event.message.fragments;
    if (fragments.isEmpty) {
      return [TextSpan(text: this.event.message.text)];
    }
    return [
      for (final fragment in fragments)
        if (fragment.type == 'emote' && fragment.emote != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              twitchEmoteUrl(fragment.emote!.id),
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(fragment.text),
            ),
          )
        else
          TextSpan(text: fragment.text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),

      /// Rebuilds when the badge catalog arrives/changes; toggle changes
      /// come from the HiveBuilder above the list.
      child: Observer(
        builder: (context) => Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              ...this._badgeSpans(),
              TextSpan(
                text: this.event.chatterUserName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: this._authorColor(context),
                ),
              ),
              const TextSpan(text: ': '),
              ...this._messageSpans(),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the view**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`:

1. Add imports:

```dart
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
```

2. Replace the final `return Stack(...)` (the message-list branch) with:

```dart
        /// Toggle changes re-filter badges in place; row-level Observers
        /// pick up badge catalog arrivals.
        return HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [
            SettingsKeys.TwitchChatBadgeBroadcaster,
            SettingsKeys.TwitchChatBadgeModerator,
            SettingsKeys.TwitchChatBadgeVip,
            SettingsKeys.TwitchChatBadgeSubscriber,
            SettingsKeys.TwitchChatBadgeFounder,
            SettingsKeys.TwitchChatBadgeBits,
            SettingsKeys.TwitchChatBadgeOther,
          ],
          builder: (context, settingsBox, child) => Stack(
            children: [
              ListView.builder(
                controller: this._scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                itemCount: messageCount,
                itemBuilder: (context, index) => TwitchChatMessageRow(
                  event: this._store.messages[index],
                  settingsBox: settingsBox,
                ),
              ),
              if (this._unreadWhileScrolledUp)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.sm,
                  child: Center(
                    child: Pressable(
                      haptic: true,
                      onTap: () {
                        setState(() {
                          this._pinnedToBottom = true;
                          this._unreadWhileScrolledUp = false;
                        });
                        this._scrollToBottom();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          'New messages ↓',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
```

(the `Stack` content is unchanged apart from `itemBuilder` passing
`settingsBox` — only the `HiveBuilder` wrapper and the two indentation
levels are new)

- [ ] **Step 5: Run tests to verify they pass**

Run: `./flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: PASS (all existing + 3 new tests).

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart \
  lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart \
  test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): render role badges in the native message rows"
```

---

### Task 7: Native chat options sheet + bar entry point

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart`
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart`
- Test: `test/chat/native_chat_options_sheet_test.dart` (create)

**Interfaces:**
- Consumes: the 7 `SettingsKeys` (Task 2), `ModalHandler.showBaseBottomSheet` (`lib/utils/modal_handler.dart`), `BaseAdaptiveSwitch` (`lib/shared/general/base/adaptive_switch.dart`), `HiveBuilder` (`lib/shared/general/hive_builder.dart`), `Pressable`/`AppSpacing`/`AppRadius` (`lib/shared/design/design.dart`), `StylingHelper.lightenDarkenColor`.
- Produces:
  - `NativeChatOptionsSheet({super.key, required ChatType chatType})` — the generic per-platform options sheet (Twitch section today)
  - `NativeChatOptionsButton({super.key, required ChatType chatType})` — the 44pt bar entry point
  - The sheet is the seam for future native platforms: add a section to its body `switch`, no new bar entry points.

- [ ] **Step 1: Write the failing test**

Create `test/chat/native_chat_options_sheet_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../persistence/support/hive_test_harness.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('chat_options_sheet_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('shows all badge toggles, on by default', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    expect(find.text('Native chat options'), findsOneWidget);
    for (final label in [
      'Broadcaster',
      'Moderator',
      'VIP',
      'Subscriber',
      'Founder',
      'Bits',
      'Other badges',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final switches = tester
        .widgetList<BaseAdaptiveSwitch>(find.byType(BaseAdaptiveSwitch))
        .toList();
    expect(switches, hasLength(7));
    expect(switches.every((s) => s.value), isTrue);
  });

  testWidgets('toggling a switch writes the settings box', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    final moderatorSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Moderator'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    await tester.tap(moderatorSwitch);
    await tester.pump();

    expect(
      settingsBox().get(SettingsKeys.TwitchChatBadgeModerator.name),
      isFalse,
    );
    expect(
      tester.widget<BaseAdaptiveSwitch>(moderatorSwitch).value,
      isFalse,
    );
  });

  testWidgets('the button opens the sheet', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsButton(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.byType(NativeChatOptionsButton));
    await tester.pumpAndSettle();

    expect(find.text('Native chat options'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./flutterw test test/chat/native_chat_options_sheet_test.dart`
Expected: FAIL — target of URI doesn't exist (`native_chat_options_sheet.dart`).

- [ ] **Step 3: Create the sheet + button**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/adaptive_switch.dart';
import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';

/// Entry point in the native-mode chat bar: opens [NativeChatOptionsSheet].
/// Styled like the bar's other control containers, 44pt touch target.
class NativeChatOptionsButton extends StatelessWidget {
  final ChatType chatType;

  const NativeChatOptionsButton({super.key, required this.chatType});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Native chat options',
      child: Pressable(
        haptic: true,
        onTap: () => ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          builder: (context) =>
              NativeChatOptionsSheet(chatType: this.chatType),
        ),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimensionCupertino,
            minHeight: kMinInteractiveDimensionCupertino,
          ),
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: const Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

/// Options for the native chat engines, one section per platform — today
/// only Twitch (badge visibility). Future native platforms add their
/// section to the body switch; the bar entry point stays this one.
class NativeChatOptionsSheet extends StatelessWidget {
  final ChatType chatType;

  const NativeChatOptionsSheet({super.key, required this.chatType});

  /// (label, settings key) pairs in display order
  static const List<(String, SettingsKeys)> _twitchBadgeRows = [
    ('Broadcaster', SettingsKeys.TwitchChatBadgeBroadcaster),
    ('Moderator', SettingsKeys.TwitchChatBadgeModerator),
    ('VIP', SettingsKeys.TwitchChatBadgeVip),
    ('Subscriber', SettingsKeys.TwitchChatBadgeSubscriber),
    ('Founder', SettingsKeys.TwitchChatBadgeFounder),
    ('Bits', SettingsKeys.TwitchChatBadgeBits),
    ('Other badges', SettingsKeys.TwitchChatBadgeOther),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Native chat options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          switch (this.chatType) {
            ChatType.Twitch => const _TwitchBadgeOptions(),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

/// Twitch section of [NativeChatOptionsSheet]: the badge visibility
/// toggles, default-on, persisted straight to the Settings box (the
/// message list re-filters live via its own HiveBuilder).
class _TwitchBadgeOptions extends StatelessWidget {
  const _TwitchBadgeOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twitch — badge visibility',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: NativeChatOptionsSheet._twitchBadgeRows
              .map((row) => row.$2)
              .toList(),
          builder: (context, settingsBox, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ListTile.divideTiles(
                context: context,
                tiles: NativeChatOptionsSheet._twitchBadgeRows.map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row.$1),
                    trailing: BaseAdaptiveSwitch(
                      value:
                          settingsBox.get(row.$2.name, defaultValue: true),
                      onChanged: (value) =>
                          settingsBox.put(row.$2.name, value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Add the button to the native-mode bar**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart`:

1. Add the import:

```dart
import '../native_chat_options_sheet.dart';
```

2. Replace the native-mode branch of the right column:

```dart
                    if (nativeMode)
                      const TwitchAccountControl()
                    else
```

with:

```dart
                    if (nativeMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NativeChatOptionsButton(chatType: chatType),
                          const SizedBox(width: AppSpacing.sm),
                          const TwitchAccountControl(),
                        ],
                      )
                    else
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `./flutterw test test/chat/`
Expected: PASS — the whole chat test dir, including the new sheet tests and
the unchanged `twitch_chat_integration_test.dart` (its
`find.byType(TwitchAccountControl)` expectations still hold: the control is
now nested in a `Row`, but still present exactly once in native mode).

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart \
  "lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart" \
  test/chat/native_chat_options_sheet_test.dart
git commit -m "feat(chat): native chat options sheet with badge visibility toggles"
```

---

### Task 8: Full gates + docs update

**Files:**
- Modify: `AGENTS.md` (chat paragraph)
- Modify: `docs/session-handoff.md`
- Modify: `docs/changelog-agent.md`

**Interfaces:**
- Consumes: everything above.
- Produces: green full-suite + analyze gates; docs reflecting badges shipped.

- [ ] **Step 1: Run the full test suite**

Run: `./flutterw test`
Expected: PASS — 108 baseline + the new tests (expect ~128 total: +2 Task 1,
+6 Task 2, +3 Task 3, +6 Task 4, +3 Task 5, +3 Task 6, +3 Task 7 — the exact
count is whatever the suite reports; it must be 0 failures).

- [ ] **Step 2: Run analyze**

Run: `./flutterw analyze`
Expected: 0 errors; only the 6 pre-existing warnings (`input.dart` ×2,
`translucent_sliver_app_bar.dart` ×2, `statistics.dart` ×2). Fix any new
issue in the feature code before continuing — do not commit with a dirtier
analyze than baseline.

- [ ] **Step 3: Update the docs**

1. `AGENTS.md` — in the **Chat:** paragraph, replace the "Next:" sentence:

old:

```
Native switch lives in the chat bar (`SelectedChatEngine`, default WebView; availability seam:
`nativeChatAvailableFor` in `lib/models/enums/chat_engine.dart`). Next:
availability gate, badges — see chat audit + handoff.
```

new:

```
Native switch lives in the chat bar (`SelectedChatEngine`, default WebView; availability seam:
`nativeChatAvailableFor` in `lib/models/enums/chat_engine.dart`). Role badges +
per-category toggles ship via `TwitchBadgeStore` + the native chat options
sheet (per-platform seam). Next: availability gate, container UI, send input —
see chat audit + handoff.
```

(adjust to the file's exact current wording if it drifted — keep it one
short paragraph)

2. `docs/changelog-agent.md` — prepend a dated entry (match the file's
existing entry format):

```markdown
## 2026-08-05 — Native Twitch chat: role badges + visibility toggles

- `ChatMessageEvent` now models the payload's `badges` array
  (`ChatMessageBadge`: setId/id/info).
- New `TwitchBadgeStore` (GetIt, session-scoped, in-memory) caches the Helix
  global + per-channel badge catalogs, fetched by the new
  `TwitchBadgeService` with the existing user token (no new scope);
  `TwitchChatStore.connectChat()` kicks the fetch off fire-and-forget,
  `logout()` clears it.
- `TwitchChatMessageRow` renders badge images before the username
  (render-time lookup, channel catalog > global), skipped silently when
  unknown.
- New "Native chat options" sheet (44pt button in the native bar) with
  per-platform sections — Twitch today: 7 badge visibility toggles
  (broadcaster, moderator, VIP, subscriber, founder, bits, other),
  default-on, persisted as plain Settings-box bool keys
  (`twitch-chat-badge-*`), live re-filtering.
```

3. `docs/session-handoff.md` — rewrite the current-state section (this doc
is reset at every handoff): Phase 2 badges + toggles shipped on `master`;
gates green; next candidates from the Phase 2 leftover list (revocation
toast, messageId dedup, refresh-400 mid-session, chat container UI, send
input, entitlement gate). Keep the doc's existing structure/length.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md docs/session-handoff.md docs/changelog-agent.md
git commit -m "docs: badges + toggles shipped — handoff, changelog, AGENTS"
```

---

## Self-Review Notes (plan author, already applied)

- **Spec coverage:** every spec section maps to a task — DTO badges (T1),
  catalog DTOs + settings keys + mapping (T2), service (T3), store (T4),
  trigger wiring (T5), rendering (T6), sheet + entry point (T7), error
  handling is woven into T4/T5/T6 (silent degrade, generation guard,
  unknown-badge skip), testing is per-task. Out-of-scope items stay out.
- **Type consistency:** `badgeVersion(setId, id)`, `fetch(accessToken:,
  broadcasterId:)`, `clear()`, `settingsKeyForBadgeSetId`,
  `NativeChatOptionsSheet/Button({required ChatType chatType})`,
  `TwitchChatMessageRow({required event, required settingsBox})` are spelled
  identically in every task that references them.
- **Sheet test note:** `BaseAdaptiveSwitch.value` is asserted on the
  rebuilt widget after `tester.pump()` — the sheet's HiveBuilder rebuilds
  from the box write, so the finder resolves to the new instance.

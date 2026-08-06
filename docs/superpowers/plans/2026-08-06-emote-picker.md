# Emote Picker (First-Party + 7TV/BTTV) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the native Twitch chat dock an emote picker — first-party emotes (Helix Get User Emotes) plus the already-loaded 7TV/BTTV catalogs — where tapping an emote inserts its code at the dock cursor.

**Architecture:** Mirrors the badge/emote waves end-to-end: a `TwitchEmoteService` (paginated Helix `chat/emotes/user`) feeds a session-scoped GetIt MobX `TwitchEmoteStore` (channel/global split by owner, generation guard, degrade-to-none), fetched fire-and-forget on chat connect behind the new `user:read:emotes` scope and cleared on logout. `NativeChatInput` gets generic seams (external `controller`/`focusNode`/`leading`) staying Twitch-free; the Twitch-aware `ChatEmotePickerButton` + `ChatEmotePickerSheet` (bottom sheet, search, sections) are composed in `stream_chat.dart`.

**Tech Stack:** Flutter (Dart 3), MobX + GetIt, freezed, `http` (no new deps), flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-06-emote-picker-design.md`

## Global Constraints

- Scope list: `kTwitchChatScopes` becomes exactly `['user:read:chat', 'user:write:chat', 'user:read:emotes']` — and the auth-service test expectation becomes `'user:read:chat user:write:chat user:read:emotes'`.
- `canReadEmotes` on `_TwitchChatStore` is a plain, deliberately non-reactive getter mirroring `canWriteChat` verbatim (persisted scopes change only at login/logout).
- Grouping rule: `ownerId == userId` → channel list, everything else → global. `emoteType`/`emoteSetId` are raw strings (no enum — unknown values must not crash parsing).
- Pagination: `after` cursor loop, hard cap `TwitchEmoteService.kMaxPages = 50`; the cursor is appended as `&after=${Uri.encodeComponent(after)}`; null OR empty cursor ends paging.
- **No new dependencies.** Images via `Image.network` (2x URLs). The picker grid is the app's first `GridView` — allowed by the spec.
- `NativeChatInput` stays Twitch-free: only the three optional generic params (`controller`, `focusNode`, `leading`). An external controller/focusNode is **never disposed** by the dock.
- Insert rule: `'$code '` replaces the selected range (cursor lands after it); append at end when `!selection.isValid`. The sheet pops with `true` on insert; a bare dismiss pops with nothing; the dock's focus node is refocused **only after an insert**.
- The picker button renders whenever the dock renders (logged in). When `!canReadEmotes` (pre-upgrade token), the sheet shows a re-login CTA instead of the first-party sections — the third-party section still shows.
- Third-party = **one combined section** `'Third-party (7TV/BTTV)'` from the merged `ThirdPartyEmoteStore.emotes` (provider attribution is lost in the merge by design — spec updated to match), alpha-sorted by name, gated on `SettingsKeys.TwitchChatThirdPartyEmotes` (default-on) via `HiveBuilder`.
- Codegen (MobX + freezed): `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`. Never hand-edit `*.g.dart` / `*.freezed.dart`; generated files are committed.
- Test/analyze runner: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test <paths>` / `... analyze`.
- Commit per task, small logically-scoped commits. Do NOT push.

---

### Task 1: `TwitchUserEmote` DTO + `TwitchEmoteService`

**Files:**
- Create: `lib/types/classes/twitch/twitch_user_emote.dart`
- Create: `lib/utils/twitch/twitch_emote_service.dart`
- Test: `test/chat/twitch_emote_service_test.dart`

**Interfaces:**
- Consumes: `TwitchAuthService.helixHeaders`, `kTwitchHelixBase`, `TwitchAuthException` (existing).
- Produces:
  - `class TwitchUserEmote { final String id; final String name; final String ownerId; final String emoteType; final String emoteSetId; }` (freezed, fromJson).
  - `class TwitchEmoteService { static const int kMaxPages = 50; TwitchEmoteService({http.Client? client}); Future<List<TwitchUserEmote>> fetchUserEmotes(String accessToken, {required String userId, required String broadcasterId}); }`

- [x] **Step 1: Write the failing test**

Create `test/chat/twitch_emote_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';

/// Mirrors the Helix `chat/emotes/user` `data[]` shape (we read id, name,
/// owner_id and keep emote_type/emote_set_id raw).
Map<String, Object?> emoteEntry(String id, String name, String ownerId) => {
      'id': id,
      'name': name,
      'tier': '1000',
      'emote_type': 'subscriptions',
      'emote_set_id': 'set-$id',
      'owner_id': ownerId,
      'format': ['static'],
      'scale_available': ['1', '2', '3'],
      'theme_mode': ['light', 'dark'],
    };

void main() {
  group('fetchUserEmotes', () {
    test('parses a single page and sends the helix headers', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.twitch.tv/helix/chat/emotes/user'
          '?user_id=user-1&broadcaster_id=user-1',
        );
        expect(request.headers['Authorization'], 'Bearer token-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              emoteEntry('25', 'Kappa', 'user-1'),
              emoteEntry('88', 'PogChamp', 'twitch'),
              {'name': 'broken-no-id', 'owner_id': 'user-1'},
            ],
          }),
          200,
        );
      });

      final emotes = await TwitchEmoteService(client: client)
          .fetchUserEmotes('token-1', userId: 'user-1', broadcasterId: 'user-1');

      expect(emotes, hasLength(2));
      expect(emotes[0].id, '25');
      expect(emotes[0].name, 'Kappa');
      expect(emotes[0].ownerId, 'user-1');
      expect(emotes[0].emoteType, 'subscriptions');
      expect(emotes[1].ownerId, 'twitch');
    });

    test('accumulates pages via the after cursor', () async {
      final urls = <String>[];
      final client = MockClient((request) async {
        urls.add(request.url.toString());
        if (urls.length == 1) {
          return http.Response(
            json.encode({
              'data': [emoteEntry('25', 'Kappa', 'user-1')],
              'pagination': {'cursor': 'next/page?'},
            }),
            200,
          );
        }
        return http.Response(
          json.encode({
            'data': [emoteEntry('88', 'PogChamp', 'twitch')],
            'pagination': {},
          }),
          200,
        );
      });

      final emotes = await TwitchEmoteService(client: client)
          .fetchUserEmotes('token-1', userId: 'user-1', broadcasterId: 'user-1');

      expect(emotes.map((e) => e.name), ['Kappa', 'PogChamp']);
      expect(urls, hasLength(2));
      expect(urls[1], contains('&after=next%2Fpage%3F'));
    });

    test('non-200 throws TwitchAuthException with status', () {
      final client = MockClient((request) async => http.Response('nope', 401));

      expect(
        TwitchEmoteService(client: client).fetchUserEmotes(
          'token-1',
          userId: 'user-1',
          broadcasterId: 'user-1',
        ),
        throwsA(isA<TwitchAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('a 200 without a data list throws TwitchAuthException', () {
      final client = MockClient((request) async =>
          http.Response(json.encode({'unexpected': true}), 200));

      expect(
        TwitchEmoteService(client: client).fetchUserEmotes(
          'token-1',
          userId: 'user-1',
          broadcasterId: 'user-1',
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_emote_service_test.dart`
Expected: FAIL — compile error, `twitch_emote_service.dart` does not exist.

- [x] **Step 3: Write minimal implementation**

Create `lib/types/classes/twitch/twitch_user_emote.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_user_emote.freezed.dart';
part 'twitch_user_emote.g.dart';

/// One first-party emote the logged-in user can use in their own channel's
/// chat (Helix `chat/emotes/user` `data[]`). [emoteType]/[emoteSetId] are
/// kept as raw strings — Twitch's enum is open-ended and the picker's
/// grouping uses [ownerId] only, so unknown values must not crash parsing.
@Freezed(fromJson: true, toJson: false)
abstract class TwitchUserEmote with _$TwitchUserEmote {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory TwitchUserEmote({
    required String id,
    required String name,
    required String ownerId,
    @Default('') String emoteType,
    @Default('') String emoteSetId,
  }) = _TwitchUserEmote;

  factory TwitchUserEmote.fromJson(Map<String, Object?> json) =>
      _$TwitchUserEmoteFromJson(json);
}
```

Create `lib/utils/twitch/twitch_emote_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

/// Helix `chat/emotes/user` endpoint — the emotes the authenticated user
/// can use in a channel's chat (globals + that channel's own). Requires the
/// `user:read:emotes` scope.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class TwitchEmoteService {
  /// Defensive cap on pagination rounds — a misbehaving cursor must not
  /// loop forever (realistic catalogs are 1-3 pages).
  static const int kMaxPages = 50;

  final http.Client _client;

  TwitchEmoteService({http.Client? client})
      : _client = client ?? http.Client();

  /// All emotes usable by [userId] in [broadcasterId]'s chat, accumulated
  /// across pages.
  Future<List<TwitchUserEmote>> fetchUserEmotes(
    String accessToken, {
    required String userId,
    required String broadcasterId,
  }) async {
    final emotes = <TwitchUserEmote>[];
    String? after;
    for (var page = 0; page < kMaxPages; page++) {
      final result = await this._fetchPage(
        accessToken,
        userId: userId,
        broadcasterId: broadcasterId,
        after: after,
      );
      emotes.addAll(result.$1);
      if (result.$2 == null) return emotes;
      after = result.$2;
    }
    return emotes;
  }

  /// One page: (emotes, next cursor). A null/empty cursor means last page.
  Future<(List<TwitchUserEmote>, String?)> _fetchPage(
    String accessToken, {
    required String userId,
    required String broadcasterId,
    String? after,
  }) async {
    final response = await this._client.get(
      Uri.parse(
        '$kTwitchHelixBase/chat/emotes/user?user_id=$userId'
        '&broadcaster_id=$broadcasterId'
        '${after != null ? '&after=${Uri.encodeComponent(after)}' : ''}',
      ),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching Twitch user emotes failed (${response.statusCode})',
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List) {
      throw const TwitchAuthException(
          'Fetching Twitch user emotes returned no data');
    }
    final pagination = body['pagination'];
    final cursor = pagination is Map<String, dynamic>
        ? pagination['cursor'] as String?
        : null;
    return (
      [
        for (final emote in data)
          if (emote is Map<String, Object?> &&
              emote['id'] is String &&
              emote['name'] is String)
            TwitchUserEmote.fromJson(emote),
      ],
      (cursor != null && cursor.isNotEmpty) ? cursor : null,
    );
  }
}
```

- [x] **Step 4: Run codegen + tests**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`
Then: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_emote_service_test.dart`
Expected: codegen succeeds (`twitch_user_emote.freezed.dart` + `twitch_user_emote.g.dart` generated, committed as-is); tests PASS (4 tests).

- [x] **Step 5: Commit**

```bash
git add lib/types/classes/twitch/twitch_user_emote.dart lib/types/classes/twitch/twitch_user_emote.freezed.dart lib/types/classes/twitch/twitch_user_emote.g.dart lib/utils/twitch/twitch_emote_service.dart test/chat/twitch_emote_service_test.dart
git commit -m "feat(chat): paginated Get User Emotes service + emote DTO"
```

---

### Task 2: `TwitchEmoteStore` + fake service

**Files:**
- Create: `lib/stores/views/twitch_emotes.dart` (+ generated `twitch_emotes.g.dart` via build_runner)
- Modify: `test/chat/support/fake_twitch_services.dart` (append `FakeTwitchEmoteService`)
- Test: `test/chat/twitch_emote_store_test.dart`

**Interfaces:**
- Consumes: `TwitchEmoteService`, `TwitchUserEmote` (Task 1).
- Produces:
  - `class TwitchEmoteStore` (MobX) — `ObservableList<TwitchUserEmote> channelEmotes` / `globalEmotes`, `@observable int catalogVersion`, `@observable bool isLoading`, `Future<void> fetch({required String accessToken, required String userId})`, `void clear()`, constructor `TwitchEmoteStore({TwitchEmoteService? service})`.
  - `class FakeTwitchEmoteService extends TwitchEmoteService` — settable `emotes`, error field `fetchThrows`, gate `fetchGate`, counters/records `calls`/`lastAccessToken`/`lastUserId`/`lastBroadcasterId`, static emotes `channelEmote`/`globalEmote`/`anotherChannelEmote` — used by Tasks 3/5.

- [x] **Step 1: Add the fake service**

Append to `test/chat/support/fake_twitch_services.dart` (add these imports at the top: `import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';` + `import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';`):

```dart
class FakeTwitchEmoteService extends TwitchEmoteService {
  List<TwitchUserEmote> emotes = const [];

  /// When set, the fetch throws this error.
  Object? fetchThrows;

  /// When set, the fetch parks on this completer — lets a test resolve the
  /// fetch at a chosen moment (stale-fetch tests).
  Completer<List<TwitchUserEmote>>? fetchGate;

  int calls = 0;
  String? lastAccessToken;
  String? lastUserId;
  String? lastBroadcasterId;

  static const channelEmote = TwitchUserEmote(
    id: '25',
    name: 'Kappa',
    ownerId: 'user-1',
    emoteType: 'subscriptions',
    emoteSetId: 'set-1',
  );

  static const globalEmote = TwitchUserEmote(
    id: '88',
    name: 'PogChamp',
    ownerId: 'twitch',
  );

  /// Sorts before [channelEmote] alphabetically — proves alpha ordering.
  static const anotherChannelEmote = TwitchUserEmote(
    id: '4',
    name: 'BabyRage',
    ownerId: 'user-1',
    emoteType: 'subscriptions',
    emoteSetId: 'set-1',
  );

  @override
  Future<List<TwitchUserEmote>> fetchUserEmotes(
    String accessToken, {
    required String userId,
    required String broadcasterId,
  }) async {
    this.calls++;
    this.lastAccessToken = accessToken;
    this.lastUserId = userId;
    this.lastBroadcasterId = broadcasterId;
    if (this.fetchThrows != null) throw this.fetchThrows!;
    if (this.fetchGate != null) return this.fetchGate!.future;
    return this.emotes;
  }
}
```

- [x] **Step 2: Write the failing store tests**

Create `test/chat/twitch_emote_store_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeTwitchEmoteService service;
  late TwitchEmoteStore store;

  setUp(() {
    service = FakeTwitchEmoteService();
    store = TwitchEmoteStore(service: service);
  });

  test('fetch splits channel vs global by owner, alpha-sorted', () async {
    service.emotes = [
      FakeTwitchEmoteService.channelEmote,
      FakeTwitchEmoteService.globalEmote,
      FakeTwitchEmoteService.anotherChannelEmote,
    ];

    await store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(service.lastAccessToken, 'token-1');
    expect(service.lastUserId, 'user-1');
    expect(service.lastBroadcasterId, 'user-1');
    expect(store.channelEmotes.map((e) => e.name), ['BabyRage', 'Kappa']);
    expect(store.globalEmotes.map((e) => e.name), ['PogChamp']);
    expect(store.catalogVersion, 1);
    expect(store.isLoading, isFalse);
  });

  test('isLoading is true while the fetch is parked', () async {
    service.fetchGate = Completer<List<TwitchUserEmote>>();
    final pending = store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(store.isLoading, isTrue);

    service.fetchGate!.complete(const []);
    await pending;
    expect(store.isLoading, isFalse);
  });

  test('a failing fetch degrades to empty and still bumps the version',
      () async {
    service.fetchThrows = Exception('boom');

    await store.fetch(accessToken: 'token-1', userId: 'user-1');

    expect(store.channelEmotes, isEmpty);
    expect(store.globalEmotes, isEmpty);
    expect(store.catalogVersion, 1);
    expect(store.isLoading, isFalse);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<List<TwitchUserEmote>>();
    service.fetchGate = gate;
    final first = store.fetch(accessToken: 'token-1', userId: 'user-1');

    service.fetchGate = null;

    /// The newer fetch belongs to a different account (user-2) — its
    /// emote must be owned by user-2 to land in the channel section
    /// (grouping rule: ownerId == fetch userId).
    service.emotes = const [
      TwitchUserEmote(id: '25', name: 'Kappa', ownerId: 'user-2'),
    ];
    await store.fetch(accessToken: 'token-2', userId: 'user-2');

    gate.complete([FakeTwitchEmoteService.globalEmote]);
    await first;

    expect(store.channelEmotes.map((e) => e.name), ['Kappa']);
    expect(store.globalEmotes, isEmpty);

    /// The superseded fetch returned before applying — only the newer
    /// fetch bumped the version.
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalog and bumps the version', () async {
    service.emotes = [FakeTwitchEmoteService.channelEmote];
    await store.fetch(accessToken: 'token-1', userId: 'user-1');
    expect(store.channelEmotes, isNotEmpty);

    store.clear();

    expect(store.channelEmotes, isEmpty);
    expect(store.globalEmotes, isEmpty);
    expect(store.catalogVersion, 2);
  });
}
```

- [x] **Step 3: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_emote_store_test.dart`
Expected: FAIL — compile error, `twitch_emotes.dart` does not exist.

- [x] **Step 4: Write the store implementation**

Create `lib/stores/views/twitch_emotes.dart`:

```dart
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_emote_service.dart';

part 'twitch_emotes.g.dart';

class TwitchEmoteStore = _TwitchEmoteStore with _$TwitchEmoteStore;

/// Session-scoped catalog of the first-party emotes the logged-in user can
/// use in their own channel's chat (Helix `chat/emotes/user`), split for
/// the picker into channel vs global sections. Refetched on every chat
/// connect, in-memory only — failures degrade to "no first-party emotes",
/// never to a chat error.
abstract class _TwitchEmoteStore with Store {
  final TwitchEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _TwitchEmoteStore({TwitchEmoteService? service})
      : _service = service ?? TwitchEmoteService();

  /// Emotes owned by the logged-in channel, alpha-sorted by name.
  final ObservableList<TwitchUserEmote> channelEmotes = ObservableList();

  /// Everything else (Twitch globals), alpha-sorted by name.
  final ObservableList<TwitchUserEmote> globalEmotes = ObservableList();

  /// Bumped once per applied fetch (and on [clear]) — the picker sheet's
  /// Observer reads this so the grid rebuilds once when the catalog lands.
  @observable
  int catalogVersion = 0;

  /// True while a fetch is in flight — the sheet shows a spinner when the
  /// catalog is still empty.
  @observable
  bool isLoading = false;

  @action
  Future<void> fetch({
    required String accessToken,
    required String userId,
  }) async {
    final generation = ++this._fetchGeneration;
    this.isLoading = true;

    /// The chat engine only ever connects to the user's own channel, so
    /// userId doubles as broadcasterId.
    final emotes = await this._tryFetch(
      this._service.fetchUserEmotes(
        accessToken,
        userId: userId,
        broadcasterId: userId,
      ),
    );

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [catalogVersion]/[isLoading]) now.
    if (generation != this._fetchGeneration) return;

    final channel = <TwitchUserEmote>[];
    final global = <TwitchUserEmote>[];
    for (final emote in emotes ?? const <TwitchUserEmote>[]) {
      (emote.ownerId == userId ? channel : global).add(emote);
    }
    int byName(TwitchUserEmote a, TwitchUserEmote b) =>
        a.name.compareTo(b.name);
    channel.sort(byName);
    global.sort(byName);

    this.channelEmotes
      ..clear()
      ..addAll(channel);
    this.globalEmotes
      ..clear()
      ..addAll(global);
    this.isLoading = false;
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.channelEmotes.clear();
    this.globalEmotes.clear();
    this.isLoading = false;
    this.catalogVersion++;
  }

  /// First-party emotes are nice-to-have: a failed fetch degrades to no
  /// emotes instead of failing chat connect.
  Future<List<TwitchUserEmote>?> _tryFetch(
      Future<List<TwitchUserEmote>> future) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Twitch user emote fetch failed — $e');
      return null;
    }
  }
}
```

- [x] **Step 5: Run codegen + tests**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`
Then: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_emote_store_test.dart`
Expected: codegen succeeds (`twitch_emotes.g.dart` generated, committed as-is); tests PASS (5 tests).

- [x] **Step 6: Commit**

```bash
git add lib/stores/views/twitch_emotes.dart lib/stores/views/twitch_emotes.g.dart test/chat/support/fake_twitch_services.dart test/chat/twitch_emote_store_test.dart
git commit -m "feat(chat): session-scoped TwitchEmoteStore with channel/global split + generation guard"
```

---

### Task 3: Scope + `canReadEmotes` + `TwitchChatStore` wiring + GetIt registration

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart:13-18` (scopes + comment)
- Modify: `lib/stores/views/twitch_chat.dart` (imports :7-8, field ~:54, constructor ~:65-87, `canWriteChat` ~:138, logout ~:263-267, connectChat ~:312-333)
- Modify: `lib/main.dart` (registration after `ThirdPartyEmoteStore` :91-92 + import)
- Modify: `test/chat/twitch_auth_service_test.dart:26` (scope-string expectation)
- Test: `test/chat/twitch_chat_store_test.dart` (new group)

**Interfaces:**
- Consumes: `TwitchEmoteStore` (Task 2).
- Produces:
  - `kTwitchChatScopes` = `['user:read:chat', 'user:write:chat', 'user:read:emotes']`.
  - `bool get canReadEmotes` on `_TwitchChatStore` — used by Tasks 5-6.
  - `TwitchChatStore({..., TwitchEmoteStore Function()? userEmoteStoreResolver})` — same injection style as `badgeStoreResolver`.

- [x] **Step 1: Update the scopes + the auth-service test expectation**

In `lib/utils/twitch/twitch_auth_service.dart` replace the scopes block (lines 13-18) with:

```dart
/// Chat scopes requested in the device flow — read incoming chat, send
/// messages as the authenticated user, and list the emotes they can use
/// (emote picker).
const List<String> kTwitchChatScopes = <String>[
  'user:read:chat',
  'user:write:chat',
  'user:read:emotes',
];
```

In `test/chat/twitch_auth_service_test.dart:26` replace the expectation with:

```dart
        expect(request.bodyFields['scopes'],
            'user:read:chat user:write:chat user:read:emotes');
```

- [x] **Step 2: Write the failing wiring tests**

In `test/chat/twitch_chat_store_test.dart`, add the import at the top:

```dart
import 'package:obs_blade/stores/views/twitch_emotes.dart';
```

Append this group inside `main()`, after the `third-party emote wiring` group (the outer `setUp` provides `authService`, `eventSubService`, `badgeStore`; the group's own `logIn` rebuilds the store with the user-emote resolver — the call counter increments synchronously when `connectChat` kicks the fire-and-forget fetch):

```dart
  group('first-party emote wiring', () {
    late FakeTwitchEmoteService userEmoteService;
    late TwitchEmoteStore userEmoteStore;

    setUp(() {
      userEmoteService = FakeTwitchEmoteService();
      userEmoteStore = TwitchEmoteStore(service: userEmoteService);
    });

    Future<void> logIn({List<String>? scopes}) async {
      authService.tokenScopes = scopes ??
          const ['user:read:chat', 'user:write:chat', 'user:read:emotes'];
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___) => eventSubService,
        badgeStoreResolver: () => badgeStore,
        userEmoteStoreResolver: () => userEmoteStore,
      );
      await store.startLogin();
    }

    test('connect fetches the user emote catalog when scoped', () async {
      await logIn();

      expect(store.canReadEmotes, isTrue);
      expect(userEmoteService.calls, 1);
      expect(userEmoteService.lastUserId, FakeTwitchAuthService.user.id);
      expect(
          userEmoteService.lastBroadcasterId, FakeTwitchAuthService.user.id);
      expect(userEmoteService.lastAccessToken,
          FakeTwitchAuthService.token.accessToken);
    });

    test('a pre-upgrade token skips the fetch', () async {
      await logIn(scopes: const ['user:read:chat', 'user:write:chat']);

      expect(store.canReadEmotes, isFalse);
      expect(userEmoteService.calls, 0);
    });

    test('logout clears the catalog', () async {
      await logIn();
      userEmoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);

      await store.logout();

      expect(userEmoteStore.channelEmotes, isEmpty);
      expect(userEmoteStore.globalEmotes, isEmpty);
    });
  }
```

- [x] **Step 3: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile error, `userEmoteStoreResolver` is not a parameter of `TwitchChatStore`.

- [x] **Step 4: Wire the store**

In `lib/stores/views/twitch_chat.dart`:

a) Add the import (after the `twitch_badges.dart` import, line 8):

```dart
import 'package:obs_blade/stores/views/twitch_emotes.dart';
```

b) Next to `_emoteStoreResolver` (~line 54), add the field:

```dart
  final TwitchEmoteStore Function() _userEmoteStoreResolver;
```

c) In the constructor parameter list (after `emoteStoreResolver`, ~line 73):

```dart
    TwitchEmoteStore Function()? userEmoteStoreResolver,
```

and in the initializer list (after `_emoteStoreResolver = ...`, ~line 86):

```dart
        _userEmoteStoreResolver = userEmoteStoreResolver ??
            (() => GetIt.instance<TwitchEmoteStore>()),
```

d) After the `canWriteChat` getter (~line 142), add:

```dart
  /// Whether the persisted token carries the read-emotes scope (emote
  /// picker). Same deliberately plain (non-reactive) pattern as
  /// [canWriteChat].
  bool get canReadEmotes =>
      this._authBox.get(TwitchAuth.kBoxKey)?.scopes.contains(
            'user:read:emotes',
          ) ??
      false;
```

e) In `logout()` (~line 263-267), right after the third-party emote `clear()` try/catch block:

```dart
    try {
      this._userEmoteStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Twitch user emote catalog clear failed — $e');
    }
```

f) In `connectChat()` (~line 333, after the third-party emote block's closing catch), add:

```dart
      /// First-party emote catalog (picker) — same nice-to-have,
      /// fire-and-forget policy as badges. Skipped entirely when the
      /// persisted token predates the read-emotes scope (pre-upgrade
      /// session — the picker shows a re-login CTA instead).
      try {
        if (this.canReadEmotes) {
          unawaited(
            this
                ._userEmoteStoreResolver()
                .fetch(accessToken: token, userId: this.user!.id)
                .catchError((Object e) {
              GeneralHelper.advLog('Twitch user emote fetch failed — $e');
            }),
          );
        }
      } catch (e) {
        GeneralHelper.advLog('Twitch user emote fetch could not start — $e');
      }
```

No codegen needed: no new observables/actions (resolver is a plain final field, getter is non-reactive).

g) In `lib/main.dart`, register the singleton right after the `ThirdPartyEmoteStore` registration (:91-92), adding `import 'package:obs_blade/stores/views/twitch_emotes.dart';` next to the third-party store import:

```dart
  GetIt.instance
      .registerLazySingleton<TwitchEmoteStore>(() => TwitchEmoteStore());
```

- [x] **Step 5: Run tests to verify they pass**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart test/chat/twitch_auth_service_test.dart`
Expected: PASS (both whole files, incl. the 3 new wiring tests and the updated scope assertion).

- [x] **Step 6: Commit**

```bash
git add lib/utils/twitch/twitch_auth_service.dart lib/stores/views/twitch_chat.dart lib/main.dart test/chat/twitch_auth_service_test.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): user:read:emotes scope + fetch/clear first-party emote catalog on connect/logout"
```

---

### Task 4: Dock seam — `NativeChatInput` external controller/focusNode/leading

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`
- Test: `test/chat/native_chat_input_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `NativeChatInput({..., TextEditingController? controller, FocusNode? focusNode, Widget? leading})` — Task 6 composes the picker into `leading` and passes the shared controller/focusNode. Contract: external controller/focusNode are owned by the caller and **never disposed** by the dock; `leading` renders left of the text field (send-button row only, not the read-only strip).

- [x] **Step 1: Write the failing tests**

In `test/chat/native_chat_input_test.dart`, extend the `buildInput` helper with optional params:

```dart
NativeChatInput buildInput({
  bool canSend = true,
  bool inFlight = false,
  String? errorText,
  TextEditingController? controller,
  FocusNode? focusNode,
  Widget? leading,
  Future<bool> Function(String)? onSend,
  VoidCallback? onRelogin,
}) =>
    NativeChatInput(
      controller: controller,
      focusNode: focusNode,
      leading: leading,
      canSend: canSend,
      inFlight: inFlight,
      errorText: errorText,
      accentColor: Colors.purple,
      onSend: onSend ?? (_) async => true,
      onRelogin: onRelogin ?? () {},
    );
```

Append these tests inside `main()`:

```dart
  testWidgets('uses an external controller and never disposes it',
      (tester) async {
    final controller = TextEditingController(text: 'hello');
    await tester.pumpWidget(wrap(buildInput(controller: controller)));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller,
      same(controller),
    );

    /// Unmount the dock — an external controller must survive (an
    /// internal one is disposed with the state).
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(() => controller.text = 'still alive', returnsNormally);
  });

  testWidgets('clear-on-success works with an external controller',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(buildInput(controller: controller)));

    await tester.enterText(find.byType(TextField), 'picker inserted');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(controller.text, isEmpty);
  });

  testWidgets('renders the leading slot left of the field', (tester) async {
    await tester.pumpWidget(wrap(buildInput(leading: const Text('PICK'))));

    expect(find.text('PICK'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('uses an external focus node', (tester) async {
    final node = FocusNode();
    await tester.pumpWidget(wrap(buildInput(focusNode: node)));

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode,
      same(node),
    );
  });
```

- [x] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_input_test.dart`
Expected: FAIL — compile error, `controller`/`focusNode`/`leading` are not parameters of `NativeChatInput`.

- [x] **Step 3: Add the seams**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`:

a) Update the class doc comment (lines 7-10) to:

```dart
/// Chat input dock of the native chat window: pill text field + circular
/// send button when the account may write ([canSend]), or a read-only hint
/// strip when the token predates the write scope. Generic by params — no
/// Twitch types — so a future native engine reuses it as-is. Optional
/// [controller]/[focusNode]/[leading] seams let the caller compose extras
/// (e.g. an emote picker) without the dock knowing about them.
```

b) Add the fields + constructor params (after `errorText` in the field block, and into the constructor):

```dart
  /// External controller for outside text insertion (e.g. an emote
  /// picker). Ownership stays with the caller — never disposed here.
  final TextEditingController? controller;

  /// External focus node — lets the caller refocus the field (e.g. after
  /// a picker sheet closes). Ownership stays with the caller.
  final FocusNode? focusNode;

  /// Optional widget rendered left of the text field (e.g. a picker
  /// toggle). Only shown in the send-ready state, not on the lock strip.
  final Widget? leading;
```

Constructor: add `this.controller, this.focusNode, this.leading,` to the optional params.

c) In `_NativeChatInputState`, replace the controller field and `dispose()`:

```dart
  late final TextEditingController _controller =
      this.widget.controller ?? TextEditingController();

  @override
  void dispose() {
    /// Only the internally created controller is ours to dispose.
    if (this.widget.controller == null) this._controller.dispose();
    super.dispose();
  }
```

d) In the `TextField` (line 141), add the focus node:

```dart
                child: TextField(
                  controller: this._controller,
                  focusNode: this.widget.focusNode,
                  enabled: !this.widget.inFlight,
```

e) In the dock `Row` (line 138-139), render the leading slot before the `Expanded`:

```dart
          Row(
            children: [
              if (this.widget.leading != null) ...[
                this.widget.leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
```

- [x] **Step 4: Run tests to verify they pass**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_input_test.dart`
Expected: PASS (whole file, incl. the 4 new tests).

- [x] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart test/chat/native_chat_input_test.dart
git commit -m "feat(chat): external controller/focusNode/leading seams in the native chat dock"
```

---

### Task 5: `ChatEmotePickerButton` + `ChatEmotePickerSheet`

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_emote_picker.dart`
- Test: `test/chat/chat_emote_picker_test.dart`

**Interfaces:**
- Consumes: `TwitchEmoteStore.channelEmotes`/`globalEmotes`/`catalogVersion`/`isLoading` (Task 2), `ThirdPartyEmoteStore.emotes`/`catalogVersion` (existing), `SettingsKeys.TwitchChatThirdPartyEmotes` (existing), `twitchEmoteUrl(String)` from `package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart` (existing).
- Produces:
  - `ChatEmotePickerButton({required TextEditingController controller, required FocusNode focusNode, required bool canReadEmotes, required Color accentColor, required VoidCallback onRelogin})` — Task 6 composes it into the dock's `leading` slot.
  - `ChatEmotePickerSheet({required TextEditingController controller, required bool canReadEmotes, required Color accentColor, required VoidCallback onRelogin})` — pops with `true` after an insert, pops with nothing on a bare dismiss or the re-login CTA.

- [x] **Step 1: Write the failing tests**

Create `test/chat/chat_emote_picker_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_emote_picker.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Network images never resolve in tests — the cells are still `Image`
/// widgets whose urls we can read.
List<String> cellUrls(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => (image.image as NetworkImage).url)
    .toList();

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchEmoteService userEmoteService;
  late TwitchEmoteStore emoteStore;
  late ThirdPartyEmoteStore thirdPartyStore;
  late TextEditingController controller;

  String kappaUrl = twitchEmoteUrl(FakeTwitchEmoteService.channelEmote.id);
  String pogUrl = twitchEmoteUrl(FakeTwitchEmoteService.globalEmote.id);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_emote_picker_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    userEmoteService = FakeTwitchEmoteService();
    emoteStore = TwitchEmoteStore(service: userEmoteService);
    thirdPartyStore =
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<TwitchEmoteStore>(emoteStore);
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(thirdPartyStore);
    controller = TextEditingController();
  });

  tearDown(() async {
    controller.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ChatEmotePickerSheet buildSheet({
    bool canReadEmotes = true,
    VoidCallback? onRelogin,
  }) =>
      ChatEmotePickerSheet(
        controller: controller,
        canReadEmotes: canReadEmotes,
        accentColor: Colors.purple,
        onRelogin: onRelogin ?? () {},
      );

  void seedCatalogs() {
    emoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);
    emoteStore.globalEmotes.add(FakeTwitchEmoteService.globalEmote);
    thirdPartyStore.emotes[FakeThirdPartyEmoteService.peepo.name] =
        FakeThirdPartyEmoteService.peepo;
  }

  testWidgets('sections render in order with headers and cells',
      (tester) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Third-party (7TV/BTTV)'), findsOneWidget);
    expect(
      cellUrls(tester),
      unorderedEquals([
        kappaUrl,
        pogUrl,
        FakeThirdPartyEmoteService.peepo.imageUrl,
      ]),
    );
  });

  testWidgets('search filters across sections, case-insensitive',
      (tester) async {
    seedCatalogs();
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.enterText(
        find.byType(TextField).first, 'kappa');
    await tester.pump();

    expect(cellUrls(tester), [kappaUrl]);
    expect(find.text('Channel'), findsOneWidget);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Third-party (7TV/BTTV)'), findsNothing);
  });

  testWidgets('tapping a cell inserts code + space at the cursor',
      (tester) async {
    seedCatalogs();
    controller
      ..text = 'hi there'
      ..selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.tap(find.byType(Image).first);
    await tester.pump();

    expect(controller.text, 'hiKappa  there');
    expect(controller.selection.baseOffset, 8);
  });

  testWidgets('appends at the end when the controller has no selection',
      (tester) async {
    seedCatalogs();
    controller.text = 'hi';
    await tester.pumpWidget(wrap(buildSheet()));

    await tester.tap(find.byType(Image).first);
    await tester.pump();

    expect(controller.text, 'hiKappa ');
  });

  testWidgets(
      'pre-upgrade token shows the re-login CTA; third-party stays visible',
      (tester) async {
    var relogin = false;
    seedCatalogs();
    await tester.pumpWidget(
      wrap(buildSheet(canReadEmotes: false, onRelogin: () => relogin = true)),
    );

    expect(
      find.text('Log in again to load your Twitch emotes'),
      findsOneWidget,
    );
    expect(find.text('Channel'), findsNothing);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Third-party (7TV/BTTV)'), findsOneWidget);

    await tester.tap(find.text('Re-login'));
    await tester.pump();
    expect(relogin, isTrue);
  });

  testWidgets('third-party section hides when the toggle is off',
      (tester) async {
    seedCatalogs();

    /// Real file I/O never completes inside the test body's FakeAsync
    /// zone — runAsync escapes it (same pattern as the badge tests).
    await tester.runAsync(() async {
      await Hive.box(HiveKeys.Settings.name)
          .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
    });

    await tester.pumpWidget(wrap(buildSheet()));

    expect(find.text('Third-party (7TV/BTTV)'), findsNothing);
    expect(find.text('Channel'), findsOneWidget);
  });

  testWidgets('catalog landing pops the grid in (catalogVersion)',
      (tester) async {
    await tester.pumpWidget(wrap(buildSheet()));
    expect(find.text('No emotes available'), findsOneWidget);

    emoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);
    emoteStore.catalogVersion++;
    await tester.pump();

    expect(find.text('No emotes available'), findsNothing);
    expect(cellUrls(tester), [kappaUrl]);
  });

  testWidgets('empty catalog with a fetch in flight shows a spinner',
      (tester) async {
    emoteStore.isLoading = true;
    await tester.pumpWidget(wrap(buildSheet()));

    /// Tests run on the android default platform → material spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No emotes available'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('button opens the sheet and refocuses after an insert',
      (tester) async {
    seedCatalogs();

    /// The focus node must be attached to the tree — requestFocus on a
    /// detached node only defers (hasFocus stays false). Real usage hands
    /// the dock's attached node; here a Focus wrapper attaches it.
    final focusNode = FocusNode();
    await tester.pumpWidget(
      wrap(Focus(
        focusNode: focusNode,
        child: ChatEmotePickerButton(
          controller: controller,
          focusNode: focusNode,
          canReadEmotes: true,
          accentColor: Colors.purple,
          onRelogin: () {},
        ),
      )),
    );

    await tester.tap(find.byType(ChatEmotePickerButton));
    await tester.pumpAndSettle();
    expect(find.text('Emotes'), findsOneWidget);

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(controller.text, 'Kappa ');
    expect(focusNode.hasFocus, isTrue);
  });
}
```

Note on the cursor test above (`'hiKappa  there'`): inserting `'Kappa '` at offset 2 of `'hi there'` yields `'hi' + 'Kappa ' + ' there'` — the original space after `hi` remains, so two spaces. Correct as written.

- [x] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/chat_emote_picker_test.dart`
Expected: FAIL — compile error, `chat_emote_picker.dart` does not exist.

- [x] **Step 3: Implement the picker**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_emote_picker.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';

/// Dock toggle for [ChatEmotePickerSheet] — styled like the chat bar's
/// control containers, 44pt touch target. Refocuses the dock's field when
/// the sheet closed after an insert (compose continuation), not on a bare
/// dismiss.
class ChatEmotePickerButton extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Whether the persisted token carries the read-emotes scope — the sheet
  /// shows a re-login CTA instead of first-party sections when false.
  final bool canReadEmotes;

  /// Brand accent (CTA text), same value the dock gets.
  final Color accentColor;

  /// Starts the re-login flow from the sheet's pre-upgrade CTA.
  final VoidCallback onRelogin;

  const ChatEmotePickerButton({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canReadEmotes,
    required this.accentColor,
    required this.onRelogin,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Emotes',
      child: Pressable(
        haptic: true,
        onTap: () async {
          /// Drop the dock's keyboard first — the sheet rides above an
          /// open keyboard (ModalHandler viewInsets padding), and on
          /// small phones sheet + keyboard would overflow vertically.
          /// After an insert the field is refocused below.
          this.focusNode.unfocus();
          final inserted = await ModalHandler.showBaseBottomSheet<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => ChatEmotePickerSheet(
              controller: this.controller,
              canReadEmotes: this.canReadEmotes,
              accentColor: this.accentColor,
              onRelogin: this.onRelogin,
            ),
          );
          if ((inserted ?? false) && this.focusNode.canRequestFocus) {
            this.focusNode.requestFocus();
          }
        },
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
            CupertinoIcons.smiley,
            size: 18.0,
          ),
        ),
      ),
    );
  }
}

/// Emote picker sheet: first-party sections (Channel / Global) from
/// [TwitchEmoteStore] plus the combined third-party section from
/// [ThirdPartyEmoteStore] (only when the third-party toggle is on).
/// Tapping an emote inserts `code + ' '` into [controller] at the cursor
/// and pops with `true` so the caller can refocus the dock.
class ChatEmotePickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final bool canReadEmotes;
  final Color accentColor;

  /// Starts the re-login flow — invoked after the sheet pops itself.
  final VoidCallback onRelogin;

  const ChatEmotePickerSheet({
    super.key,
    required this.controller,
    required this.canReadEmotes,
    required this.accentColor,
    required this.onRelogin,
  });

  @override
  State<ChatEmotePickerSheet> createState() => _ChatEmotePickerSheetState();
}

class _ChatEmotePickerSheetState extends State<ChatEmotePickerSheet> {
  String _query = '';

  /// (code, imageUrl) pairs of one section.
  List<(String, String)> _filtered(
    Iterable<(String, String)> entries,
    String query,
  ) =>
      [
        for (final entry in entries)
          if (query.isEmpty || entry.$1.toLowerCase().contains(query)) entry,
      ];

  void _insert(String code) {
    final controller = this.widget.controller;
    final insert = '$code ';
    final selection = controller.selection;
    if (selection.isValid) {
      controller
        ..text = controller.text.replaceRange(
          selection.start,
          selection.end,
          insert,
        )
        ..selection = TextSelection.collapsed(
          offset: selection.start + insert.length,
        );
    } else {
      controller
        ..text = controller.text + insert
        ..selection =
            TextSelection.collapsed(offset: controller.text.length);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.pill,
      borderSide: BorderSide(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        width: 0.0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emotes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            onChanged: (value) =>
                this.setState(() => this._query = value),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor),
              hintText: 'Search emotes…',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              prefixIcon: const Icon(CupertinoIcons.search, size: 16.0),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36.0,
                minHeight: 0.0,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: inputBorder,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 320.0,
            child: Observer(
              builder: (context) {
                final emoteStore = GetIt.instance<TwitchEmoteStore>();
                final thirdPartyStore =
                    GetIt.instance<ThirdPartyEmoteStore>();

                /// Tracked so catalogs landing while the sheet is open
                /// pop in once.
                // ignore: unused_local_variable
                final catalogVersions = emoteStore.catalogVersion +
                    thirdPartyStore.catalogVersion;

                return HiveBuilder<dynamic>(
                  hiveKey: HiveKeys.Settings,
                  rebuildKeys: const [
                    SettingsKeys.TwitchChatThirdPartyEmotes,
                  ],
                  builder: (context, settingsBox, child) {
                    final query = this._query.trim().toLowerCase();

                    final thirdPartyEntries = (settingsBox.get(
                      SettingsKeys.TwitchChatThirdPartyEmotes.name,
                      defaultValue: true,
                    ) as bool)
                        ? this._filtered(
                            [
                              for (final emote
                                  in thirdPartyStore.emotes.values)
                                (emote.name, emote.imageUrl),
                            ]..sort((a, b) => a.$1.compareTo(b.$1)),
                            query,
                          )
                        : const <(String, String)>[];

                    final sections = <(String, List<(String, String)>)>[
                      if (this.widget.canReadEmotes) ...[
                        (
                          'Channel',
                          this._filtered(
                            [
                              for (final emote
                                  in emoteStore.channelEmotes)
                                (emote.name, twitchEmoteUrl(emote.id)),
                            ],
                            query,
                          ),
                        ),
                        (
                          'Global',
                          this._filtered(
                            [
                              for (final emote
                                  in emoteStore.globalEmotes)
                                (emote.name, twitchEmoteUrl(emote.id)),
                            ],
                            query,
                          ),
                        ),
                      ],
                      ('Third-party (7TV/BTTV)', thirdPartyEntries),
                    ].where((section) => section.$2.isNotEmpty).toList();

                    return ListView(
                      children: [
                        if (!this.widget.canReadEmotes) ...[
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.lock_fill,
                                size: 14.0,
                                color: this.widget.accentColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Log in again to load your Twitch emotes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                              Pressable(
                                haptic: true,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  this.widget.onRelogin();
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight:
                                        kMinInteractiveDimensionCupertino,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Re-login',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: this.widget.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (this.widget.canReadEmotes &&
                            emoteStore.isLoading &&
                            emoteStore.channelEmotes.isEmpty &&
                            emoteStore.globalEmotes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: StylingHelper.isApple(context)
                                  ? const CupertinoActivityIndicator()
                                  : const SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                            ),
                          )
                        else if (sections.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Text(
                                'No emotes available',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                        else
                          for (final section in sections) ...[
                            Text(
                              section.$1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            GridView(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 56.0,
                                mainAxisSpacing: AppSpacing.xs,
                                crossAxisSpacing: AppSpacing.xs,
                              ),
                              children: [
                                for (final emote in section.$2)
                                  _EmoteCell(
                                    code: emote.$1,
                                    imageUrl: emote.$2,
                                    onTap: () => this._insert(emote.$1),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One selectable emote in [ChatEmotePickerSheet] — 2x image with the code
/// as tooltip and as fallback text when the image fails (same policy as
/// the message rows).
class _EmoteCell extends StatelessWidget {
  final String code;
  final String imageUrl;
  final VoidCallback onTap;

  const _EmoteCell({
    required this.code,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: this.code,
      child: Pressable(
        haptic: true,
        onTap: this.onTap,
        child: Center(
          child: Image.network(
            this.imageUrl,
            height: 32.0,
            width: 32.0,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              this.code,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
```

Known edge (accepted, documented here): programmatic insertion bypasses the field's 500-char `maxLength` (input-only enforcement) — a code can push the text past 500; the send path is unchanged (Twitch would drop over-limit messages). Matches the spec's "no paste-special-casing".

- [x] **Step 4: Run tests to verify they pass**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/chat_emote_picker_test.dart`
Expected: PASS (9 tests).

- [x] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_emote_picker.dart test/chat/chat_emote_picker_test.dart
git commit -m "feat(chat): emote picker button + sheet (search, sections, cursor insert, re-login CTA)"
```

---

### Task 6: Compose the picker into `stream_chat.dart`

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`

**Interfaces:**
- Consumes: `NativeChatInput`'s `controller`/`focusNode`/`leading` (Task 4), `ChatEmotePickerButton` (Task 5), `TwitchChatStore.canReadEmotes` (Task 3).
- Produces: the picker visible in the running app. No new APIs.

- [x] **Step 1: Wire the composition**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`:

a) Add the import (next to the `native_chat_input.dart` import, line 25):

```dart
import 'chat_emote_picker.dart';
```

b) In `_StreamChatState`, add the fields (next to `_webController`, ~line 67):

```dart
  /// Dock controller/focus for the native input — owned here so the emote
  /// picker (the dock's leading slot) can insert codes at the cursor and
  /// refocus after its sheet closes.
  final TextEditingController _chatInputController =
      TextEditingController();
  final FocusNode _chatInputFocusNode = FocusNode();
```

c) In `dispose()` (~line 149), dispose both:

```dart
  @override
  void dispose() {
    this._chatInputController.dispose();
    this._chatInputFocusNode.dispose();
    _loadingFallback?.cancel();
    super.dispose();
  }
```

d) In the native branch's `input:` (~line 292-302), pass the seams:

```dart
                      input: loggedIn
                          ? NativeChatInput(
                              controller: this._chatInputController,
                              focusNode: this._chatInputFocusNode,
                              leading: ChatEmotePickerButton(
                                controller: this._chatInputController,
                                focusNode: this._chatInputFocusNode,
                                canReadEmotes: twitchStore.canReadEmotes,
                                accentColor: chatType.brandColor ??
                                    Theme.of(context).colorScheme.secondary,
                                onRelogin: () => startTwitchLogin(context),
                              ),
                              canSend: twitchStore.canWriteChat,
                              inFlight: twitchStore.sendingChat,
                              errorText: twitchStore.sendChatError,
                              accentColor: chatType.brandColor ??
                                  Theme.of(context).colorScheme.secondary,
                              onSend: twitchStore.sendChatMessage,
                              onRelogin: () => startTwitchLogin(context),
                            )
                          : null,
```

No new tests for the composition itself: the dock/sheet widgets and the store wiring are covered by their own suites; this step is verified by the full chat suite staying green (the integration tests render the native branch) plus analyze.

- [x] **Step 2: Run the chat suite + analyze**

Run:

```bash
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze
```

Expected: all chat tests PASS (existing integration/view tests unaffected — the dock renders the same with the new slots); analyze 0 errors (6 pre-existing warnings tolerated, no new ones).

- [x] **Step 3: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart
git commit -m "feat(chat): compose the emote picker into the native chat dock"
```

---

### Task 7: Gates + docs wrap

**Files:**
- Modify: `docs/changelog-agent.md` (new entry on top, matching the dated `## 2026-08-06` heading style)
- Modify: `docs/session-handoff.md` (current-state bullets; keep the baton style)
- Modify: `AGENTS.md` (chat paragraph)
- Modify: `docs/superpowers/specs/2026-08-06-third-party-emotes-design.md` (out-of-scope line ~:208)

- [x] **Step 1: Run the full gates**

Run:

```bash
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/ test/websocket/ test/persistence/
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze
```

Expected: all tests PASS; analyze reports 0 errors (the 6 pre-existing warnings are tolerated — no new ones).

- [x] **Step 2: Changelog entry**

Add a dated entry to the top of `docs/changelog-agent.md` (match the existing heading style):

```markdown
## 2026-08-06 — Native chat: emote picker (first-party + 7TV/BTTV)

- `TwitchEmoteService`: Helix Get User Emotes (first paginated endpoint in
  the app — `after`-cursor loop, hard cap 50 pages); freezed
  `TwitchUserEmote` keeps `emoteType`/`emoteSetId` raw.
- `TwitchEmoteStore` (GetIt, session-scoped, MobX): channel/global split
  by owner, alpha-sorted, generation guard, `catalogVersion` pop-in +
  `isLoading` spinner signal; cleared on logout.
- New `user:read:emotes` scope (silent upgrade — pre-upgrade tokens skip
  the fetch and see a re-login CTA in the sheet, same philosophy as the
  write-scope lock strip). `canReadEmotes` mirrors `canWriteChat`.
- Dock seams: `NativeChatInput` takes an optional external
  controller/focusNode (never disposed by the dock) + a `leading` slot —
  still Twitch-free.
- Picker sheet: search + Channel/Global/Third-party sections (56pt cells,
  2x images, errorBuilder → code text), tap inserts `code + space` at the
  cursor and refocuses the dock; third-party section follows the existing
  7TV/BTTV toggle.
- Tests: service (4), store (5), wiring (3), dock (4 new), picker sheet +
  button (9). Gates: chat + websocket + persistence suites green, analyze
  0 errors (6 pre-existing warnings, none new).
```

- [x] **Step 3: Handoff update**

In `docs/session-handoff.md` (baton style — short bullets, no narrative):

- Add a new bullet: **Emote picker on `master`** (2026-08-06) — button in the native dock opens a bottom sheet (search; Channel/Global + combined third-party sections); tap inserts at the cursor. New scope `user:read:emotes` (silent upgrade; CTA for pre-upgrade sessions). Spec `docs/superpowers/specs/2026-08-06-emote-picker-design.md` + plan `docs/superpowers/plans/2026-08-06-emote-picker.md`. **Maintainer dogfood pending:**
  - Fresh login (to pick up the new scope) → picker shows Channel + Global sections; globals present (dogfood verifies Get User Emotes includes Twitch globals — if missing, the spec's Get Global Emotes fallback kicks in).
  - Insert mid-text and at the end; echo renders the emote inline (first-party + 7TV/BTTV).
  - Search filter; sheet open while catalogs land (pop-in); keyboard behavior after insert (field refocused).
  - Pre-upgrade token: CTA path (cancel re-login → session intact — existing upgrade guard).
  - Third-party toggle off → third-party section hidden in the picker.
  - Tablet mode + WebView engine unchanged.

- [x] **Step 4: AGENTS.md + spec sync**

- In `AGENTS.md`'s Chat paragraph: append the picker to the shipped description — e.g. "an emote picker (first-party Get User Emotes via `TwitchEmoteStore` + the third-party catalogs) docks in the native input (`user:read:emotes` silent upgrade)".
- In `docs/superpowers/specs/2026-08-06-third-party-emotes-design.md` (~line 208, out-of-scope): change "Emote autocomplete / picker in the send input (future send polish, alongside replies/announce)." to "Emote autocomplete in the send input (future send polish, alongside replies/announce; the picker shipped separately on 2026-08-06)."

- [x] **Step 5: Commit**

```bash
git add docs/changelog-agent.md docs/session-handoff.md AGENTS.md docs/superpowers/specs/2026-08-06-third-party-emotes-design.md
git commit -m "docs: emote picker shipped — changelog, handoff, AGENTS.md"
```

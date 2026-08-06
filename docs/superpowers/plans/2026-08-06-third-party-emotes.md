# Third-Party Emotes (7TV/BTTV) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render 7TV/BTTV emotes inline in the native Twitch chat — today they fall back to plain text.

**Architecture:** Mirror the badge wave end-to-end: a `ThirdPartyEmoteService` (4 public, unauthenticated fetches: 7TV/BTTV × global/channel) feeds a session-scoped GetIt MobX `ThirdPartyEmoteStore` (one merged map, generation guard, degrade-to-none). `TwitchChatMessageRow` tokenizes text fragments on spaces at build time and swaps known tokens for inline images (render-time lookup, no ingest-time mutation). Fetch/clear hook into `TwitchChatStore` beside the badge seams, gated on a default-on options-sheet toggle.

**Tech Stack:** Flutter (Dart 3), MobX + GetIt, Hive CE (Settings box), `http` (already a dependency — no new deps), flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-06-third-party-emotes-design.md`

## Global Constraints

- Providers: **7TV + BTTV only** (no FFZ). Both APIs are public, **no auth token**.
- Toggle: `SettingsKeys.TwitchChatThirdPartyEmotes` → `'twitch-chat-third-party-emotes'`, Settings box, **default-on**. Fetch only happens when the toggle is on.
- Precedence on name ties: **channel > global, 7TV > BTTV** (store merge order: bttv-global → 7tv-global → bttv-channel → 7tv-channel; later wins).
- **No new dependencies.** Images via `Image.network` (Flutter memory cache); API via `package:http`.
- HTTP status policy: **404 → empty map** (expected: channel without a provider presence; not an error). Any other non-200 → throw `ThirdPartyEmoteException`.
- Token matching: exact, case-sensitive, split on the single space character. Punctuation-glued tokens (`peepoHappy!`) do NOT match.
- Catalogs are session-scoped, in-memory only; failures degrade to plain text and never touch chat connection state.
- Codegen (MobX): `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`. Never hand-edit `*.g.dart` / `*.freezed.dart`; generated files are committed.
- Test/analyze runner: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test <paths>` / `... analyze`.
- Commit per task, small logically-scoped commits. Do NOT push.

---

### Task 1: `ThirdPartyEmote` shape + 7TV endpoints

**Files:**
- Create: `lib/types/classes/twitch/third_party_emote.dart`
- Create: `lib/utils/twitch/third_party_emote_service.dart`
- Test: `test/chat/third_party_emote_service_test.dart`

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - `class ThirdPartyEmote { final String name; final String imageUrl; const ThirdPartyEmote({required this.name, required this.imageUrl}); }`
  - `class ThirdPartyEmoteException implements Exception { final String message; final int? statusCode; const ThirdPartyEmoteException(this.message, {this.statusCode}); }`
  - `class ThirdPartyEmoteService { ThirdPartyEmoteService({http.Client? client}); Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal(); Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(String broadcasterId); }` (BTTV methods land in Task 2.)

- [ ] **Step 1: Write the failing test**

Create `test/chat/third_party_emote_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

/// Mirrors the verified 7TV v3 payload shape (see the design spec):
/// protocol-relative host URL; entries with a missing name/host are
/// skipped.
const _kSevenTvEmotesBody = {
  'emotes': [
    {
      'id': '01FCY771D800007PQ2DF3GDTN6',
      'name': 'RainTime',
      'data': {
        'host': {'url': '//cdn.7tv.app/emote/01FCY771D800007PQ2DF3GDTN6'},
        'animated': true,
      },
    },
    {
      'id': 'broken-no-host',
      'name': 'BrokenTime',
      'data': {},
    },
    {
      'id': 'broken-no-name',
      'data': {
        'host': {'url': '//cdn.7tv.app/emote/broken'},
      },
    },
  ],
};

void main() {
  group('fetchSevenTvGlobal', () {
    test('parses name + 2x webp url, skips malformed entries', () async {
      final client = MockClient((request) async {
        expect(
            request.url.toString(), 'https://7tv.io/v3/emote-sets/global');
        return http.Response(json.encode(_kSevenTvEmotesBody), 200);
      });

      final emotes =
          await ThirdPartyEmoteService(client: client).fetchSevenTvGlobal();

      expect(emotes, hasLength(1));
      expect(emotes['RainTime']?.imageUrl,
          'https://cdn.7tv.app/emote/01FCY771D800007PQ2DF3GDTN6/2x.webp');
    });
  });

  group('fetchSevenTvChannel', () {
    test('reads the active emote set', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'https://7tv.io/v3/users/twitch/user-1');
        return http.Response(
            json.encode({'emote_set': _kSevenTvEmotesBody}), 200);
      });

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes['RainTime'], isNotNull);
    });

    test('no active emote set returns an empty map', () async {
      final client = MockClient((request) async =>
          http.Response(json.encode({'id': 'user-1'}), 200));

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes, isEmpty);
    });

    test('404 returns an empty map (channel without 7TV presence)',
        () async {
      final client = MockClient((request) async => http.Response('', 404));

      final emotes = await ThirdPartyEmoteService(client: client)
          .fetchSevenTvChannel('user-1');

      expect(emotes, isEmpty);
    });

    test('other non-200 throws ThirdPartyEmoteException with status', () {
      final client =
          MockClient((request) async => http.Response('nope', 500));

      expect(
        ThirdPartyEmoteService(client: client).fetchSevenTvChannel('user-1'),
        throwsA(isA<ThirdPartyEmoteException>()
            .having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_service_test.dart`
Expected: FAIL — compile error, `third_party_emote_service.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/types/classes/twitch/third_party_emote.dart`:

```dart
/// One third-party chat emote (7TV / BTTV): the token chatters type and
/// the image to render in its place. Shared shape — each provider's
/// payload is parsed into this by [ThirdPartyEmoteService] and the rest
/// of the payload is dropped (plain class, no freezed: two fields, two
/// very different source shapes).
class ThirdPartyEmote {
  /// Emote code as typed in chat (matching is exact + case-sensitive).
  final String name;

  /// Mid-size image URL (animated where the provider has one).
  final String imageUrl;

  const ThirdPartyEmote({required this.name, required this.imageUrl});
}
```

Create `lib/utils/twitch/third_party_emote_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';

/// Failure of a third-party emote endpoint (non-200 other than 404 —
/// a 404 means "channel has no presence there" and degrades to empty).
class ThirdPartyEmoteException implements Exception {
  final String message;
  final int? statusCode;

  const ThirdPartyEmoteException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ThirdPartyEmoteException: ${this.message}'
      '${this.statusCode != null ? ' (status ${this.statusCode})' : ''}';
}

/// 7TV (v3) and BTTV (v3) emote catalogs — the global sets plus a
/// channel's set. Both APIs are public, no auth.
///
/// [client] is injectable for tests — no real HTTP in unit tests.
class ThirdPartyEmoteService {
  final http.Client _client;

  ThirdPartyEmoteService({http.Client? client})
      : _client = client ?? http.Client();

  /// 7TV global emote set.
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal() async {
    final body =
        await this._get(Uri.parse('https://7tv.io/v3/emote-sets/global'));
    if (body is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(body['emotes']);
  }

  /// 7TV emote set of the channel with [broadcasterId] (its active set).
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(
      String broadcasterId) async {
    final body = await this
        ._get(Uri.parse('https://7tv.io/v3/users/twitch/$broadcasterId'));
    if (body is! Map<String, Object?>) return const {};
    final emoteSet = body['emote_set'];
    if (emoteSet is! Map<String, Object?>) return const {};
    return this._parseSevenTvEmotes(emoteSet['emotes']);
  }

  /// 404 → null (channel without a presence — expected, not an error).
  /// Other non-200 → [ThirdPartyEmoteException].
  Future<Object?> _get(Uri uri) async {
    final response = await this._client.get(uri);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw ThirdPartyEmoteException(
        'GET $uri failed',
        statusCode: response.statusCode,
      );
    }
    return json.decode(response.body);
  }

  /// 7TV shape: `{ name, data: { host: { url } } }` — `host.url` is
  /// protocol-relative (`//cdn.7tv.app/emote/{id}`); `2x.webp` keeps the
  /// animation and Flutter decodes WebP (AVIF variants are skipped on
  /// purpose: no Flutter decoder).
  Map<String, ThirdPartyEmote> _parseSevenTvEmotes(Object? emotes) {
    if (emotes is! List) return const {};
    final parsed = <String, ThirdPartyEmote>{};
    for (final emote in emotes) {
      if (emote is! Map<String, Object?>) continue;
      final name = emote['name'];
      final data = emote['data'];
      if (name is! String ||
          name.isEmpty ||
          data is! Map<String, Object?>) {
        continue;
      }
      final host = data['host'];
      if (host is! Map<String, Object?>) continue;
      final url = host['url'];
      if (url is! String || url.isEmpty) continue;
      parsed[name] =
          ThirdPartyEmote(name: name, imageUrl: 'https:$url/2x.webp');
    }
    return parsed;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_service_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/types/classes/twitch/third_party_emote.dart lib/utils/twitch/third_party_emote_service.dart test/chat/third_party_emote_service_test.dart
git commit -m "feat(chat): 7TV emote service + shared third-party emote shape"
```

---

### Task 2: BTTV endpoints

**Files:**
- Modify: `lib/utils/twitch/third_party_emote_service.dart`
- Test: `test/chat/third_party_emote_service_test.dart`

**Interfaces:**
- Consumes: `ThirdPartyEmoteService`, `ThirdPartyEmote`, `ThirdPartyEmoteException` (Task 1).
- Produces (adds to `ThirdPartyEmoteService`):
  - `Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal()`
  - `Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(String broadcasterId)` (channel + shared emotes merged; shared wins ties)

- [ ] **Step 1: Write the failing tests**

Append to `test/chat/third_party_emote_service_test.dart` (inside `main()`, after the 7TV groups):

```dart
group('fetchBttvGlobal', () {
  test('parses the flat id/code array into cdn urls', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(),
          'https://api.betterttv.net/3/cached/emotes/global');
      return http.Response(
        json.encode([
          {
            'id': '54fa8f',
            'code': ':tf:',
            'imageType': 'png',
            'animated': false,
          },
          {
            'id': '55b6f4',
            'code': 'monkaS',
            'imageType': 'gif',
            'animated': true,
          },
          {'code': 'broken-no-id'},
        ]),
        200,
      );
    });

    final emotes =
        await ThirdPartyEmoteService(client: client).fetchBttvGlobal();

    expect(emotes, hasLength(2));
    expect(emotes['monkaS']?.imageUrl,
        'https://cdn.betterttv.net/emote/55b6f4/2x');
  });
});

group('fetchBttvChannel', () {
  test('merges channel + shared emotes, shared wins ties', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(),
          'https://api.betterttv.net/3/cached/users/twitch/user-1');
      return http.Response(
        json.encode({
          'channelEmotes': [
            {'id': 'chan1', 'code': 'xqcL', 'imageType': 'png'},
            {'id': 'tie-channel', 'code': 'TieEmote', 'imageType': 'png'},
          ],
          'sharedEmotes': [
            {'id': 'shared1', 'code': 'SourPls', 'imageType': 'gif'},
            {'id': 'tie-shared', 'code': 'TieEmote', 'imageType': 'gif'},
          ],
        }),
        200,
      );
    });

    final emotes = await ThirdPartyEmoteService(client: client)
        .fetchBttvChannel('user-1');

    expect(emotes, hasLength(3));
    expect(emotes['xqcL']?.imageUrl,
        'https://cdn.betterttv.net/emote/chan1/2x');
    expect(emotes['SourPls']?.imageUrl,
        'https://cdn.betterttv.net/emote/shared1/2x');
    expect(emotes['TieEmote']?.imageUrl,
        'https://cdn.betterttv.net/emote/tie-shared/2x');
  });

  test('404 returns an empty map (channel without BTTV presence)',
      () async {
    final client = MockClient((request) async => http.Response('', 404));

    final emotes = await ThirdPartyEmoteService(client: client)
        .fetchBttvChannel('user-1');

    expect(emotes, isEmpty);
  });

  test('other non-200 throws ThirdPartyEmoteException with status', () {
    final client = MockClient((request) async => http.Response('nope', 502));

    expect(
      ThirdPartyEmoteService(client: client).fetchBttvGlobal(),
      throwsA(isA<ThirdPartyEmoteException>()
          .having((e) => e.statusCode, 'statusCode', 502)),
    );
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_service_test.dart`
Expected: FAIL — compile error, `fetchBttvGlobal`/`fetchBttvChannel` are not defined.

- [ ] **Step 3: Write minimal implementation**

Add to `ThirdPartyEmoteService` in `lib/utils/twitch/third_party_emote_service.dart` (after `fetchSevenTvChannel`):

```dart
/// BTTV global emotes.
Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal() async {
  final body = await this._get(
      Uri.parse('https://api.betterttv.net/3/cached/emotes/global'));
  return this._parseBttvEmotes(body);
}

/// BTTV emotes of the channel with [broadcasterId] — its own channel
/// emotes plus the shared emotes enabled there (shared wins name ties).
Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(
    String broadcasterId) async {
  final body = await this._get(Uri.parse(
      'https://api.betterttv.net/3/cached/users/twitch/$broadcasterId'));
  if (body is! Map<String, Object?>) return const {};
  return {
    ...this._parseBttvEmotes(body['channelEmotes']),
    ...this._parseBttvEmotes(body['sharedEmotes']),
  };
}

/// BTTV shape: flat `{ id, code }` entries; the CDN serves the animated
/// variant when the emote has one.
Map<String, ThirdPartyEmote> _parseBttvEmotes(Object? emotes) {
  if (emotes is! List) return const {};
  final parsed = <String, ThirdPartyEmote>{};
  for (final emote in emotes) {
    if (emote is! Map<String, Object?>) continue;
    final id = emote['id'];
    final code = emote['code'];
    if (id is! String ||
        id.isEmpty ||
        code is! String ||
        code.isEmpty) {
      continue;
    }
    parsed[code] = ThirdPartyEmote(
      name: code,
      imageUrl: 'https://cdn.betterttv.net/emote/$id/2x',
    );
  }
  return parsed;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_service_test.dart`
Expected: PASS (10 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/utils/twitch/third_party_emote_service.dart test/chat/third_party_emote_service_test.dart
git commit -m "feat(chat): BTTV endpoints in the third-party emote service"
```

---

### Task 3: `ThirdPartyEmoteStore` + fake service

**Files:**
- Create: `lib/stores/views/third_party_emotes.dart` (+ generated `third_party_emotes.g.dart` via build_runner)
- Modify: `test/chat/support/fake_twitch_services.dart` (append `FakeThirdPartyEmoteService`)
- Test: `test/chat/third_party_emote_store_test.dart`

**Interfaces:**
- Consumes: `ThirdPartyEmoteService` (Tasks 1-2).
- Produces:
  - `class ThirdPartyEmoteStore` (MobX) — `ObservableMap<String, ThirdPartyEmote> emotes`, `@observable int catalogVersion`, `String? emoteImageUrl(String token)`, `Future<void> fetch({required String broadcasterId})`, `void clear()`, constructor `ThirdPartyEmoteStore({ThirdPartyEmoteService? service})`.
  - `class FakeThirdPartyEmoteService extends ThirdPartyEmoteService` with settable result maps `sevenTvGlobal`/`sevenTvChannel`/`bttvGlobal`/`bttvChannel`, error fields `sevenTvGlobalThrows`/`bttvChannelThrows`, gate `sevenTvGlobalGate`, counters `sevenTvGlobalCalls`/`sevenTvChannelCalls`/`bttvGlobalCalls`/`bttvChannelCalls`, `String? lastBroadcasterId`, and static emotes `peepo`/`peepoChannelOverride`/`monka`/`monkaSevenTv` — used by Tasks 4-6.

- [ ] **Step 1: Add the fake service**

Append to `test/chat/support/fake_twitch_services.dart` (and add these imports at the top: `import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';` + `import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';`):

```dart
class FakeThirdPartyEmoteService extends ThirdPartyEmoteService {
  Map<String, ThirdPartyEmote> sevenTvGlobal = const {};
  Map<String, ThirdPartyEmote> sevenTvChannel = const {};
  Map<String, ThirdPartyEmote> bttvGlobal = const {};
  Map<String, ThirdPartyEmote> bttvChannel = const {};

  /// When set, the matching fetch throws this error.
  Object? sevenTvGlobalThrows;
  Object? bttvChannelThrows;

  /// When set, [fetchSevenTvGlobal] parks on this completer — lets a test
  /// resolve the fetch at a chosen moment (stale-fetch tests).
  Completer<Map<String, ThirdPartyEmote>>? sevenTvGlobalGate;

  String? lastBroadcasterId;
  int sevenTvGlobalCalls = 0;
  int sevenTvChannelCalls = 0;
  int bttvGlobalCalls = 0;
  int bttvChannelCalls = 0;

  static const peepo = ThirdPartyEmote(
    name: 'peepoHappy',
    imageUrl: 'https://cdn.7tv.app/emote/peepo/2x.webp',
  );

  /// Same name as [peepo], different image — proves channel > global.
  static const peepoChannelOverride = ThirdPartyEmote(
    name: 'peepoHappy',
    imageUrl: 'https://cdn.7tv.app/emote/peepo-override/2x.webp',
  );

  static const monka = ThirdPartyEmote(
    name: 'monkaS',
    imageUrl: 'https://cdn.betterttv.net/emote/monka/2x',
  );

  /// Same name as [monka], 7TV image — proves 7TV > BTTV same-scope ties.
  static const monkaSevenTv = ThirdPartyEmote(
    name: 'monkaS',
    imageUrl: 'https://cdn.7tv.app/emote/monka-7tv/2x.webp',
  );

  @override
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvGlobal() async {
    this.sevenTvGlobalCalls++;
    if (this.sevenTvGlobalThrows != null) throw this.sevenTvGlobalThrows!;
    if (this.sevenTvGlobalGate != null) return this.sevenTvGlobalGate!.future;
    return this.sevenTvGlobal;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchSevenTvChannel(
      String broadcasterId) async {
    this.sevenTvChannelCalls++;
    this.lastBroadcasterId = broadcasterId;
    return this.sevenTvChannel;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchBttvGlobal() async {
    this.bttvGlobalCalls++;
    return this.bttvGlobal;
  }

  @override
  Future<Map<String, ThirdPartyEmote>> fetchBttvChannel(
      String broadcasterId) async {
    this.bttvChannelCalls++;
    this.lastBroadcasterId = broadcasterId;
    if (this.bttvChannelThrows != null) throw this.bttvChannelThrows!;
    return this.bttvChannel;
  }
}
```

- [ ] **Step 2: Write the failing store tests**

Create `test/chat/third_party_emote_store_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';

import 'support/fake_twitch_services.dart';

void main() {
  late FakeThirdPartyEmoteService service;
  late ThirdPartyEmoteStore store;

  setUp(() {
    service = FakeThirdPartyEmoteService();
    store = ThirdPartyEmoteStore(service: service);
  });

  test('fetch applies all four catalogs and bumps the version', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvGlobal = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(service.lastBroadcasterId, 'user-1');
    expect(store.emoteImageUrl('peepoHappy'),
        FakeThirdPartyEmoteService.peepo.imageUrl);
    expect(store.emoteImageUrl('monkaS'),
        FakeThirdPartyEmoteService.monka.imageUrl);
    expect(store.catalogVersion, 1);
  });

  test('channel catalog wins over global for the same name', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.sevenTvChannel = {
      FakeThirdPartyEmoteService.peepoChannelOverride.name:
          FakeThirdPartyEmoteService.peepoChannelOverride,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('peepoHappy'),
        FakeThirdPartyEmoteService.peepoChannelOverride.imageUrl);
  });

  test('7TV wins over BTTV within the same scope', () async {
    service.bttvGlobal = {
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    };
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.monkaSevenTv.name:
          FakeThirdPartyEmoteService.monkaSevenTv,
    };

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('monkaS'),
        FakeThirdPartyEmoteService.monkaSevenTv.imageUrl);
  });

  test('a failing endpoint keeps the other catalogs', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    service.bttvChannelThrows = Exception('boom');

    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('peepoHappy'), isNotNull);
    expect(store.catalogVersion, 1);
  });

  test('a superseded fetch cannot overwrite the newer catalog', () async {
    final gate = Completer<Map<String, ThirdPartyEmote>>();
    service.sevenTvGlobalGate = gate;
    final first = store.fetch(broadcasterId: 'user-1');

    service.sevenTvGlobalGate = null;
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-2');

    gate.complete({
      FakeThirdPartyEmoteService.monka.name: FakeThirdPartyEmoteService.monka,
    });
    await first;

    expect(store.emoteImageUrl('peepoHappy'), isNotNull);
    expect(store.emoteImageUrl('monkaS'), isNull);

    /// The superseded fetch returned before applying — only the newer
    /// fetch bumped the version.
    expect(store.catalogVersion, 1);
  });

  test('clear drops the catalog and bumps the version', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');
    expect(store.emotes, isNotEmpty);

    store.clear();

    expect(store.emotes, isEmpty);
    expect(store.catalogVersion, 2);
  });

  test('lookup is exact and case-sensitive', () async {
    service.sevenTvGlobal = {
      FakeThirdPartyEmoteService.peepo.name: FakeThirdPartyEmoteService.peepo,
    };
    await store.fetch(broadcasterId: 'user-1');

    expect(store.emoteImageUrl('PeepoHappy'), isNull);
    expect(store.emoteImageUrl('peepoHappyy'), isNull);
    expect(store.emoteImageUrl(''), isNull);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_store_test.dart`
Expected: FAIL — compile error, `third_party_emotes.dart` does not exist.

- [ ] **Step 4: Write the store implementation**

Create `lib/stores/views/third_party_emotes.dart`:

```dart
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/twitch/third_party_emote.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/third_party_emote_service.dart';

part 'third_party_emotes.g.dart';

class ThirdPartyEmoteStore = _ThirdPartyEmoteStore with _$ThirdPartyEmoteStore;

/// Session-scoped cache of the third-party emote catalogs (7TV + BTTV,
/// global + channel, merged into one map). Refetched on every chat
/// connect, in-memory only — catalog failures degrade to "no third-party
/// emotes", never to a chat error.
abstract class _ThirdPartyEmoteStore with Store {
  final ThirdPartyEmoteService _service;

  /// Identifies the active fetch — a superseded fetch's late results must
  /// not overwrite the newer catalog (rapid reconnect / account switch).
  int _fetchGeneration = 0;

  _ThirdPartyEmoteStore({ThirdPartyEmoteService? service})
      : _service = service ?? ThirdPartyEmoteService();

  /// Merged catalog (emote name -> emote).
  final ObservableMap<String, ThirdPartyEmote> emotes = ObservableMap();

  /// Bumped once per applied fetch (and on [clear]) — the chat view's
  /// outer Observer reads this so the visible rows rebuild once when
  /// catalogs land (pop-in) instead of every row observing the map.
  @observable
  int catalogVersion = 0;

  /// Exact, case-sensitive lookup by chat token; null when unknown (the
  /// message row renders the token as text then).
  String? emoteImageUrl(String token) => this.emotes[token]?.imageUrl;

  @action
  Future<void> fetch({required String broadcasterId}) async {
    final generation = ++this._fetchGeneration;

    /// Merge order decides precedence on name ties — later wins:
    /// global-BTTV -> global-7TV -> channel-BTTV -> channel-7TV
    /// (net: channel > global, 7TV > BTTV).
    final results = await Future.wait([
      this._tryFetch(this._service.fetchBttvGlobal(), 'bttv-global'),
      this._tryFetch(this._service.fetchSevenTvGlobal(), '7tv-global'),
      this._tryFetch(
          this._service.fetchBttvChannel(broadcasterId), 'bttv-channel'),
      this._tryFetch(
          this._service.fetchSevenTvChannel(broadcasterId), '7tv-channel'),
    ]);

    /// A newer fetch superseded this one — it owns the catalog (and
    /// [catalogVersion]) now.
    if (generation != this._fetchGeneration) return;

    this.emotes
      ..clear()
      ..addEntries([
        for (final result in results)
          if (result != null) ...result.entries,
      ]);
    this.catalogVersion++;
  }

  @action
  void clear() {
    this._fetchGeneration++;
    this.emotes.clear();
    this.catalogVersion++;
  }

  /// Third-party emotes are nice-to-have: a failed endpoint degrades to
  /// no emotes for its scope instead of failing the whole fetch.
  Future<Map<String, ThirdPartyEmote>?> _tryFetch(
    Future<Map<String, ThirdPartyEmote>> future,
    String label,
  ) async {
    try {
      return await future;
    } catch (e) {
      GeneralHelper.advLog('Third-party emote fetch ($label) failed — $e');
      return null;
    }
  }
}
```

- [ ] **Step 5: Run MobX codegen**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run build_runner build --delete-conflicting-outputs`
Expected: succeeds; `lib/stores/views/third_party_emotes.g.dart` generated. Commit the generated file as-is (never hand-edit).

- [ ] **Step 6: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_store_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/stores/views/third_party_emotes.dart lib/stores/views/third_party_emotes.g.dart test/chat/support/fake_twitch_services.dart test/chat/third_party_emote_store_test.dart
git commit -m "feat(chat): session-scoped ThirdPartyEmoteStore with merge precedence + generation guard"
```

---

### Task 4: Settings key + `TwitchChatStore` wiring + GetIt registration

**Files:**
- Modify: `lib/types/enums/settings_keys.dart` (enum value after `TwitchChatBadgeOther` ~:90, `name` map entry after :227)
- Modify: `lib/stores/views/twitch_chat.dart` (constructor seam ~:51/:69/:79, logout ~:252-256, connectChat ~:286-299)
- Modify: `lib/main.dart` (registration next to `TwitchBadgeStore` :89)
- Test: `test/chat/twitch_chat_store_test.dart` (new group)

**Interfaces:**
- Consumes: `ThirdPartyEmoteStore` (Task 3).
- Produces:
  - `SettingsKeys.TwitchChatThirdPartyEmotes` (`'twitch-chat-third-party-emotes'`) — used by Tasks 5-7.
  - `TwitchChatStore({..., ThirdPartyEmoteStore Function()? emoteStoreResolver})` — same injection style as `badgeStoreResolver`.

- [ ] **Step 1: Add the settings key**

In `lib/types/enums/settings_keys.dart`, after the `TwitchChatBadgeOther` enum value (~line 90):

```dart
  /// [bool]: Render 7TV/BTTV emotes inline in the native Twitch chat
  /// (fetches the public 7TV/BTTV catalogs on chat connect).
  /// Active by default
  TwitchChatThirdPartyEmotes,
```

And in the `name` getter map, after `SettingsKeys.TwitchChatBadgeOther: 'twitch-chat-badge-other',` (~line 227):

```dart
        SettingsKeys.TwitchChatThirdPartyEmotes:
            'twitch-chat-third-party-emotes',
```

- [ ] **Step 2: Write the failing wiring tests**

In `test/chat/twitch_chat_store_test.dart`, add imports at the top:

```dart
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
```

Append this group inside `main()` (the outer `setUp` provides `authService`, `eventSubService`, `badgeStore`; the group's own `logIn()` rebuilds the store with the emote resolver — call counters increment synchronously when `connectChat` kicks the fire-and-forget fetch, so they can be asserted right after `startLogin()`):

```dart
group('third-party emote wiring', () {
  late FakeThirdPartyEmoteService emoteService;
  late ThirdPartyEmoteStore emoteStore;

  setUp(() {
    emoteService = FakeThirdPartyEmoteService();
    emoteStore = ThirdPartyEmoteStore(service: emoteService);
  });

  Future<void> logIn() async {
    await Hive.openBox(HiveKeys.Settings.name);
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___) => eventSubService,
      badgeStoreResolver: () => badgeStore,
      emoteStoreResolver: () => emoteStore,
    );
    await store.startLogin();
  }

  test('connect fetches the emote catalogs for the logged-in user',
      () async {
    await logIn();

    expect(emoteService.sevenTvGlobalCalls, 1);
    expect(emoteService.sevenTvChannelCalls, 1);
    expect(emoteService.bttvGlobalCalls, 1);
    expect(emoteService.bttvChannelCalls, 1);
    expect(emoteService.lastBroadcasterId, FakeTwitchAuthService.user.id);
  });

  test('toggle off at connect skips the fetch', () async {
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.box(HiveKeys.Settings.name)
        .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);

    await logIn();

    expect(emoteService.sevenTvGlobalCalls, 0);
    expect(emoteService.sevenTvChannelCalls, 0);
    expect(emoteService.bttvGlobalCalls, 0);
    expect(emoteService.bttvChannelCalls, 0);
  });

  test('logout clears the catalog', () async {
    await logIn();
    emoteStore.emotes[FakeThirdPartyEmoteService.peepo.name] =
        FakeThirdPartyEmoteService.peepo;

    await store.logout();

    expect(emoteStore.emotes, isEmpty);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compile error, `emoteStoreResolver` is not a parameter of `TwitchChatStore`.

- [ ] **Step 4: Wire the store**

In `lib/stores/views/twitch_chat.dart`:

a) Add imports:

```dart
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
```

b) Next to `_badgeStoreResolver` (~line 51), add the field:

```dart
  final ThirdPartyEmoteStore Function() _emoteStoreResolver;
```

c) In the constructor parameter list (next to `badgeStoreResolver`, ~line 69):

```dart
    ThirdPartyEmoteStore Function()? emoteStoreResolver,
```

and in the initializer list (next to `_badgeStoreResolver = ...`, ~line 79-80):

```dart
        _emoteStoreResolver = emoteStoreResolver ??
            (() => GetIt.instance<ThirdPartyEmoteStore>()),
```

d) In `logout()` (~line 252-256), right after the badge `clear()` try/catch block:

```dart
    try {
      this._emoteStoreResolver().clear();
    } catch (e) {
      GeneralHelper.advLog('Third-party emote catalog clear failed — $e');
    }
```

e) In `connectChat()` (~line 296-299), right after the badge fetch try/catch block:

```dart
      /// Third-party emote catalogs (7TV/BTTV) — same nice-to-have,
      /// fire-and-forget policy as badges. Skipped entirely when the
      /// user disabled them (no third-party contact at all). The whole
      /// block is guarded: a missing Settings box or store lookup must
      /// never break the chat connect.
      try {
        if (Hive.box(HiveKeys.Settings.name).get(
          SettingsKeys.TwitchChatThirdPartyEmotes.name,
          defaultValue: true,
        )) {
          unawaited(
            this
                ._emoteStoreResolver()
                .fetch(broadcasterId: this.user!.id)
                .catchError((Object e) {
              GeneralHelper.advLog('Third-party emote fetch failed — $e');
            }),
          );
        }
      } catch (e) {
        GeneralHelper.advLog('Third-party emote fetch could not start — $e');
      }
```

The `try` deliberately wraps the toggle check itself: other `TwitchChatStore` test groups log in without opening the Settings box or registering the store, and any caller in that state must not see this throw — nice-to-have policy.

No codegen needed: no new observables/actions (the resolver is a plain final field, `connectChat`/`logout` bodies only).

f) In `lib/main.dart`, register the singleton right after the `TwitchBadgeStore` registration (~line 89), adding the matching import next to the badge store import:

```dart
  GetIt.instance.registerLazySingleton<ThirdPartyEmoteStore>(
      () => ThirdPartyEmoteStore());
```

- [ ] **Step 5: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/twitch_chat_store_test.dart`
Expected: PASS (whole file, incl. the 3 new wiring tests).

- [ ] **Step 6: Commit**

```bash
git add lib/types/enums/settings_keys.dart lib/stores/views/twitch_chat.dart lib/main.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(chat): fetch/clear third-party emotes on chat connect/logout, gated by a default-on setting"
```

---

### Task 5: Row rendering — token swap in `TwitchChatMessageRow`

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
- Modify: `test/chat/native_twitch_chat_view_test.dart` (setUp registers the emote store — rows now look it up)
- Modify: `test/chat/twitch_chat_integration_test.dart` (setUp registers the emote store :56-57 area)
- Test: `test/chat/third_party_emote_row_test.dart`

**Interfaces:**
- Consumes: `ThirdPartyEmoteStore.emoteImageUrl(String)` (Task 3), `SettingsKeys.TwitchChatThirdPartyEmotes` (Task 4).
- Produces: `_textSpans(String)` in the row — text fragments are tokenized; known tokens become 20px `WidgetSpan` images, everything else stays text. Task 6 relies on this being non-reactive (no per-row Observer).

- [ ] **Step 1: Register the emote store in existing harnesses**

Rows will call `GetIt.instance<ThirdPartyEmoteStore>()` for every text fragment (toggle default-on) — every test that renders a row must register it, exactly like the badge store.

a) `test/chat/native_twitch_chat_view_test.dart` — add field `late ThirdPartyEmoteStore emoteStore;` (next to `badgeStore`), import `package:obs_blade/stores/views/third_party_emotes.dart`, and in `setUp` after the badge registration:

```dart
    emoteStore = ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService());
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(emoteStore);
```

b) `test/chat/twitch_chat_integration_test.dart` — import `third_party_emotes.dart`, and in `setUp` after the `TwitchChatStore`/`DashboardStore` registrations (:56-57):

```dart
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
```

- [ ] **Step 2: Write the failing row tests**

Create `test/chat/third_party_emote_row_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// `Text.rich` wraps the passed span in an outer TextSpan carrying the
/// ambient style, so the row's spans sit one level down.
List<WidgetSpan> collectWidgetSpans(InlineSpan span) {
  final spans = <WidgetSpan>[];
  void visit(InlineSpan s) {
    if (s is WidgetSpan) spans.add(s);
    if (s is TextSpan) s.children?.forEach(visit);
  }

  visit(span);
  return spans;
}

ChatMessageEvent textEvent(String text) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

void main() {
  late ThirdPartyEmoteStore emoteStore;
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp
        .createTemp('third_party_emote_row_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
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

  Future<RichText> pumpRow(WidgetTester tester, String text) async {
    await tester.pumpWidget(
      wrap(TwitchChatMessageRow(
        event: textEvent(text),
        settingsBox: Hive.box(HiveKeys.Settings.name),
      )),
    );
    return tester.widget<RichText>(find.byType(RichText));
  }

  testWidgets('a known token becomes an inline image', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'hi peepoHappy');

    expect(richText.text.toPlainText(), 'Viewer: hi \u{FFFC}');
    final span = collectWidgetSpans(richText.text).single;
    final image = span.child as Image;
    expect((image.image as NetworkImage).url,
        FakeThirdPartyEmoteService.peepo.imageUrl);
  });

  testWidgets('multiple emote tokens in one message', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
    emoteStore.emotes['monkaS'] = FakeThirdPartyEmoteService.monka;

    final richText = await pumpRow(tester, 'peepoHappy and monkaS');

    expect(richText.text.toPlainText(), 'Viewer: \u{FFFC} and \u{FFFC}');
    expect(collectWidgetSpans(richText.text), hasLength(2));
  });

  testWidgets('unknown tokens and wrong case stay text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'PeepoHappy peepoHappyy');

    expect(richText.text.toPlainText(), 'Viewer: PeepoHappy peepoHappyy');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('punctuation-glued tokens stay text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'peepoHappy!');

    expect(richText.text.toPlainText(), 'Viewer: peepoHappy!');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('spacing is preserved exactly', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    final richText = await pumpRow(tester, 'a  peepoHappy  b');

    expect(richText.text.toPlainText(), 'Viewer: a  \u{FFFC}  b');
  });

  testWidgets('toggle off keeps everything text', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;

    /// Real file I/O never completes inside the test body's FakeAsync
    /// zone — runAsync escapes it (same pattern as the badge tests).
    await tester.runAsync(() async {
      await Hive.box(HiveKeys.Settings.name)
          .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
    });

    final richText = await pumpRow(tester, 'hi peepoHappy');

    expect(richText.text.toPlainText(), 'Viewer: hi peepoHappy');
    expect(collectWidgetSpans(richText.text), isEmpty);
  });

  testWidgets('first-party emote fragments are untouched', (tester) async {
    emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
    final event = ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: '1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: '1',
      message: ChatMessageText(
        text: 'Kappa peepoHappy',
        fragments: [
          ChatMessageFragment(
            type: 'emote',
            text: 'Kappa',
            emote: ChatFragmentEmote(id: '25'),
          ),
          ChatMessageFragment(type: 'text', text: ' peepoHappy'),
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
    final spans = collectWidgetSpans(richText.text);
    expect(spans, hasLength(2));
    expect(
      ((spans[0].child as Image).image as NetworkImage).url,
      'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0',
    );
    expect(
      ((spans[1].child as Image).image as NetworkImage).url,
      FakeThirdPartyEmoteService.peepo.imageUrl,
    );
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/third_party_emote_row_test.dart`
Expected: FAIL — no `WidgetSpan` images render yet (lookup is wired but `_messageSpans` never resolves tokens), so the image assertions fail.

- [ ] **Step 4: Implement tokenization in the row**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`:

a) Add imports:

```dart
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
```

b) Update the doc comment of the class (~line 10-11) to:

```dart
/// One chat line: role badges + colored author name + message text with
/// inline emotes (first-party fragments and third-party 7TV/BTTV tokens).
/// Cheermote/mention fragments fall back to plain text.
```

c) Replace `_messageSpans()` and add `_textSpans()`:

```dart
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
          ...this._textSpans(fragment.text),
    ];
  }

  /// Third-party emotes (7TV/BTTV) arrive as plain text — split on
  /// spaces and swap known tokens for inline images, preserving spacing
  /// exactly. Unknown tokens (and the toggle-off case) stay text.
  List<InlineSpan> _textSpans(String text) {
    if (!this.settingsBox.get(
      SettingsKeys.TwitchChatThirdPartyEmotes.name,
      defaultValue: true,
    )) {
      return [TextSpan(text: text)];
    }
    final emoteStore = GetIt.instance<ThirdPartyEmoteStore>();
    final tokens = text.split(' ');
    return [
      for (var i = 0; i < tokens.length; i++) ...[
        if (i > 0) const TextSpan(text: ' '),
        if (emoteStore.emoteImageUrl(tokens[i]) case final imageUrl?)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              imageUrl,
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(tokens[i]),
            ),
          )
        else
          TextSpan(text: tokens[i]),
      ],
    ];
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/`
Expected: PASS — the new row tests plus every existing chat test (the harness registrations from Step 1 keep the old row/view/integration tests green).

- [ ] **Step 6: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart test/chat/third_party_emote_row_test.dart test/chat/native_twitch_chat_view_test.dart test/chat/twitch_chat_integration_test.dart
git commit -m "feat(chat): render 7TV/BTTV tokens as inline images in native chat rows"
```

---

### Task 6: View rebuild wiring — pop-in + live toggle

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`
- Test: `test/chat/native_twitch_chat_view_test.dart` (extend the `NativeTwitchChatView` group)

**Interfaces:**
- Consumes: `ThirdPartyEmoteStore.catalogVersion` + `emotes` (Task 3), `SettingsKeys.TwitchChatThirdPartyEmotes` (Task 4), non-reactive row lookup (Task 5).
- Produces: the view's outer `Observer` tracks `catalogVersion` (one rebuild wave on catalog arrival); `HiveBuilder.rebuildKeys` includes the emote toggle key (live re-render).

- [ ] **Step 1: Write the failing view tests**

Append to the `NativeTwitchChatView` group in `test/chat/native_twitch_chat_view_test.dart`:

```dart
    testWidgets('rows pick up third-party emotes when the catalog lands',
        (tester) async {
      store.chatConnection = TwitchChatConnectionState.live;
      store.messages.add(textEvent('1', 'Viewer', 'hi peepoHappy'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      RichText richText = tester.widget<RichText>(find.descendant(
        of: find.byType(TwitchChatMessageRow),
        matching: find.byType(RichText),
      ));
      expect(richText.text.toPlainText(), 'Viewer: hi peepoHappy');

      /// Catalog lands after the rows are already built — the view's
      /// Observer tracks catalogVersion, so rows rebuild once (pop-in).
      emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
      emoteStore.catalogVersion++;
      await tester.pump();

      richText = tester.widget<RichText>(find.descendant(
        of: find.byType(TwitchChatMessageRow),
        matching: find.byType(RichText),
      ));
      expect(richText.text.toPlainText(), 'Viewer: hi \u{FFFC}');
    });

    testWidgets('turning the toggle off re-renders rows as text',
        (tester) async {
      emoteStore.emotes['peepoHappy'] = FakeThirdPartyEmoteService.peepo;
      store.chatConnection = TwitchChatConnectionState.live;
      store.messages.add(textEvent('1', 'Viewer', 'hi peepoHappy'));

      await tester.pumpWidget(wrap(const NativeTwitchChatView()));

      RichText richText = tester.widget<RichText>(find.descendant(
        of: find.byType(TwitchChatMessageRow),
        matching: find.byType(RichText),
      ));
      expect(richText.text.toPlainText(), 'Viewer: hi \u{FFFC}');

      /// Real file I/O never completes inside the test body's FakeAsync
      /// zone — runAsync escapes it (same pattern as the badge tests).
      await tester.runAsync(() async {
        await Hive.box(HiveKeys.Settings.name)
            .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);
      });
      await tester.pump();

      richText = tester.widget<RichText>(find.descendant(
        of: find.byType(TwitchChatMessageRow),
        matching: find.byType(RichText),
      ));
      expect(richText.text.toPlainText(), 'Viewer: hi peepoHappy');
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — the pop-in test still shows plain text after `catalogVersion++` (nothing tracks it), and the toggle test still shows the image after the box write (the key isn't in `rebuildKeys`).

- [ ] **Step 3: Wire the view**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`:

a) Add the import:

```dart
import 'package:obs_blade/stores/views/third_party_emotes.dart';
```

b) In the outer `Observer` builder, right after `final messageCount = this._store.messages.length;` (~line 74):

```dart
        /// Tracked so the visible list rebuilds once when third-party
        /// emote catalogs land (pop-in) — rows resolve tokens
        /// non-reactively at build time, so this read is the only
        /// rebuild trigger.
        // ignore: unused_local_variable
        final emoteCatalogVersion =
            GetIt.instance<ThirdPartyEmoteStore>().catalogVersion;
```

c) In the `HiveBuilder`'s `rebuildKeys` list (~line 174-182), add:

```dart
            SettingsKeys.TwitchChatThirdPartyEmotes,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_twitch_chat_view_test.dart`
Expected: PASS (whole file, incl. the 2 new tests).

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(chat): pop-in rebuild on emote catalog arrival + live third-party toggle"
```

---

### Task 7: Options sheet toggle

**Files:**
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart`
- Test: `test/chat/native_chat_options_sheet_test.dart`

**Interfaces:**
- Consumes: `SettingsKeys.TwitchChatThirdPartyEmotes` (Task 4).
- Produces: "Third-party emotes (7TV/BTTV)" switch in the Twitch section, default-on, persisted to the Settings box.

- [ ] **Step 1: Update + write the failing tests**

In `test/chat/native_chat_options_sheet_test.dart`, replace the existing `'shows all badge toggles, on by default'` test with:

```dart
  testWidgets('shows the emote + badge toggles, on by default',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    expect(find.text('Native chat options'), findsOneWidget);
    for (final label in [
      'Third-party emotes (7TV/BTTV)',
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
    expect(switches, hasLength(8));
    expect(switches.every((s) => s.value), isTrue);
  });
```

And add a new test after `'toggling a switch writes the settings box'`:

```dart
  testWidgets('toggling the emote switch writes the settings box',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    final emoteSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Third-party emotes (7TV/BTTV)'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isNull,
    );

    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isFalse,
    );

    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isTrue,
    );

    /// Same FakeAsync-zone dance as 'toggling a switch writes the
    /// settings box': the taps ran their Hive writes in the test's
    /// FakeAsync zone — close Hive from inside the zone so tearDown's
    /// harness.close() doesn't await a zone-parked Completer forever.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_options_sheet_test.dart`
Expected: FAIL — label not found / 7 switches instead of 8.

- [ ] **Step 3: Add the toggle to the sheet**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart`:

a) Update the `NativeChatOptionsSheet` doc comment (~line 56-58):

```dart
/// Options for the native chat engines, one section per platform — today
/// only Twitch (third-party emotes + badge visibility). Future native
/// platforms add their section to the body switch; the bar entry point
/// stays this one.
```

b) In the body switch (~line 89), rename the section widget:

```dart
            ChatType.Twitch => const _TwitchOptions(),
```

c) Replace the whole `_TwitchBadgeOptions` class with:

```dart
/// Twitch section of [NativeChatOptionsSheet]: third-party emote and
/// badge visibility toggles, default-on, persisted straight to the
/// Settings box (the message list re-renders live via its own
/// HiveBuilder).
class _TwitchOptions extends StatelessWidget {
  const _TwitchOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Twitch — emotes',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        HiveBuilder<dynamic>(
          hiveKey: HiveKeys.Settings,
          rebuildKeys: const [SettingsKeys.TwitchChatThirdPartyEmotes],
          builder: (context, settingsBox, child) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Third-party emotes (7TV/BTTV)'),
            trailing: BaseAdaptiveSwitch(
              value: settingsBox.get(
                SettingsKeys.TwitchChatThirdPartyEmotes.name,
                defaultValue: true,
              ),
              onChanged: (value) => settingsBox.put(
                SettingsKeys.TwitchChatThirdPartyEmotes.name,
                value,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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

- [ ] **Step 4: Run test to verify it passes**

Run: `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/native_chat_options_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart test/chat/native_chat_options_sheet_test.dart
git commit -m "feat(chat): third-party emotes toggle in the native chat options sheet"
```

---

### Task 8: Gates + docs wrap

**Files:**
- Modify: `docs/changelog-agent.md` (new entry, match the existing dated-entry format)
- Modify: `docs/session-handoff.md` (current-state bullets; keep the baton style)
- Modify: `AGENTS.md` (chat paragraph)

- [ ] **Step 1: Run the full gates**

Run:

```bash
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw test test/chat/ test/websocket/ test/persistence/
FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw analyze
```

Expected: all tests PASS; analyze reports 0 errors (the 6 pre-existing warnings are tolerated — no new ones).

- [ ] **Step 2: Changelog entry**

Add a dated entry to `docs/changelog-agent.md` (match the heading style of the existing 2026-08-05 entries):

```markdown
### 2026-08-06 — Native chat: third-party emotes (7TV/BTTV)

- `ThirdPartyEmoteService` (7TV v3 + BTTV v3 — public, no auth): global +
  channel catalogs; 404 → empty map (no provider presence), other
  non-200 → `ThirdPartyEmoteException`; malformed entries skipped.
- `ThirdPartyEmoteStore` (GetIt, session-scoped, MobX): one merged
  catalog, precedence channel > global / 7TV > BTTV on ties, generation
  guard against superseded fetches, `catalogVersion` as the pop-in
  rebuild signal; cleared on logout.
- `TwitchChatStore`: fire-and-forget fetch on connect, gated by the new
  default-on `twitch-chat-third-party-emotes` Settings key (off → no
  third-party contact at all); clear on logout.
- Rows tokenize text fragments (exact, case-sensitive, space-split) and
  swap known tokens for 20px inline images (`Image.network`, animated
  WebP/GIF; errorBuilder → text). Toggle in the native chat options
  sheet ("Twitch — emotes" section).
- Tests: service parsing (10), store (7), wiring (3), row (7), view
  pop-in/toggle (2), sheet (2). Gates: chat + websocket + persistence
  suites green, analyze clean.
```

- [ ] **Step 3: Handoff update**

In `docs/session-handoff.md` (baton style — short bullets, no narrative):

- In the send-input bullet's "Next chat items" line, drop "7TV/BTTV rendering" (it's done now).
- Update dogfood note (c) ("7TV/BTTV/FFZ emotes render as plain text today ... a product decision") to: shipped on `master` (2026-08-06) — product decision made: 7TV + BTTV, master toggle default-on.
- Add a new bullet: **Third-party emotes (7TV/BTTV) on `master`** (2026-08-06) — service/store/row/toggle per spec `docs/superpowers/specs/2026-08-06-third-party-emotes-design.md` + plan `docs/superpowers/plans/2026-08-06-third-party-emotes.md`. **Maintainer dogfood pending:**
  - 7TV/BTTV-heavy channel: emotes render inline, animated; pop-in a beat after messages (intended).
  - Options toggle off → plain text; back on → images (live re-render).
  - Channel without 7TV/BTTV presence: text only, no errors in logs.
  - Send a 7TV code from the native input → the EventSub echo renders it as the emote.
  - Tablet mode + WebView engine unchanged.

- [ ] **Step 4: AGENTS.md refresh**

In `AGENTS.md`'s Chat paragraph: move 7TV/BTTV from "Next:" to shipped — e.g. append "third-party (7TV/BTTV) emotes render inline via `ThirdPartyEmoteStore` (toggle in the native chat options sheet)" to the shipped description and shorten "Next:" to "availability/entitlement gate, replies/announce — see chat audit + handoff".

- [ ] **Step 5: Commit**

```bash
git add docs/changelog-agent.md docs/session-handoff.md AGENTS.md
git commit -m "docs: third-party emotes shipped — changelog, handoff, AGENTS.md"
```

# Native Twitch Chat — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add native, read-only Twitch chat to OBS Blade: device-code OAuth login + EventSub WebSocket reader rendered in the existing dashboard chat slot, with the current WebView chat as fallback.

**Architecture:** New self-contained feature — `TwitchAuthService` (device code grant, refresh, validate, revoke), `TwitchEventSubService` (dedicated EventSub WebSocket + Helix subscription), freezed DTOs under `lib/types/classes/twitch/`, one MobX `TwitchChatStore` (GetIt), and UI inside `lib/views/dashboard/widgets/obs_widgets/stream_chat/`. No changes to `DashboardStore`. Spec: `docs/superpowers/specs/2026-08-04-twitch-native-chat-phase1-design.md`.

**Tech Stack:** Flutter (workstation SDK `flutter`), MobX + mobx_codegen, GetIt, Hive CE, freezed, `web_socket_channel` (existing), `http` (new, only added dependency), `url_launcher` (existing). Tests: `flutter_test`, `package:http/testing.dart` MockClient, hand-written fakes (no mocking library in this repo — keep it that way).

## Global Constraints

- Twitch Client ID **`t3muhu36do5wemeeilzl57v48gwcmh`** — public value, hardcoded exactly once, in `lib/utils/twitch/twitch_auth_service.dart`.
- Scope requested: **`user:read:chat` only** (Phase 2 adds `user:write:chat` later via re-consent).
- **Only new dependency: `http`** (spec assumed it was present; it is not — deliberate minimal addition. Do not add anything else: no mockito/mocktail, no cached_network_image, no flutter_secure_storage).
- **No changes to `DashboardStore`.** Logged-out Twitch / YouTube / Owncast chat paths keep behaving exactly as today (WebView).
- Auth uses the **device code grant (DCF)** — the registered redirect URI (`http://localhost:14777/twitch-auth-callback`) is intentionally **unused**; do not build any redirect/loopback/deep-link handling.
- Hive: `TwitchAuth` gets **typeId 13** (highest used is 12 — never renumber existing IDs). Register the adapter manually in `main.dart`'s `_initializeHive`; do **not** switch to the generated `HiveRegistrar.registerAdapters()`.
- Single Twitch account; one box record under key `TwitchAuth.kBoxKey = 'current'` in box `HiveKeys.TwitchAuth`.
- Codegen after adding/changing annotated classes: `dart run build_runner build --delete-conflicting-outputs`.
- Commit after each task (repo policy: commit per verified unit). Do not push.
- Conventions to match: doc comments in the surrounding file's style/density, `this.` prefix in widget methods (project style), `AppSpacing`/`AppRadius` design tokens, `Pressable` for tap targets, `GeneralHelper.advLog` for logging.

---

### Task 1: `http` dependency + `TwitchAuth` Hive model

**Files:**
- Modify: `pubspec.yaml` (add `http` under `# Network stuff`)
- Modify: `lib/models/type_ids.dart` (add typeId 13)
- Modify: `lib/types/enums/hive_keys.dart` (add `TwitchAuth`)
- Create: `lib/models/twitch_auth.dart`
- Modify: `lib/main.dart` (adapter + box)
- Modify: `test/persistence/support/hive_test_harness.dart` (adapter + box)
- Modify: `lib/views/settings/data_management/data_management.dart` (wipe)
- Test: `test/persistence/twitch_auth_persistence_test.dart`

**Interfaces:**
- Consumes: existing `HiveTestHarness` (`test/persistence/support/hive_test_harness.dart`: constructor `HiveTestHarness(Directory rootDir)`, `init()`, `close()`).
- Produces: `TwitchAuth` model with `accessToken`, `refreshToken`, `expiresAtMs`, `scopes`, `userId`, `userLogin`, `userDisplayName`; `TwitchAuth.kBoxKey = 'current'`; `isExpired`; `expiresWithin(Duration)`. Used by Tasks 3, 6, 8.

- [ ] **Step 1: Add the `http` dependency**

In `pubspec.yaml`, in the `# Network stuff` block, add:

```yaml
  http: ^1.3.0
```

Run: `flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 2: Write the failing persistence test**

Create `test/persistence/twitch_auth_persistence_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import 'support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_auth_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TwitchAuth persistence', () {
    test('round-trips through its box under the current key', () async {
      final box = await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      final auth = TwitchAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
        scopes: const ['user:read:chat'],
        userId: '1234',
        userLogin: 'kounex',
        userDisplayName: 'Kounex',
      );

      await box.put(TwitchAuth.kBoxKey, auth);
      final read = box.get(TwitchAuth.kBoxKey);

      expect(read?.accessToken, 'access-1');
      expect(read?.refreshToken, 'refresh-1');
      expect(read?.scopes, ['user:read:chat']);
      expect(read?.userLogin, 'kounex');
      expect(read?.userDisplayName, 'Kounex');
    });

    test('expiresWithin / isExpired honor the window', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final soon = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 60 * 1000,
        scopes: const [],
      );
      final later = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now + 3600 * 1000,
        scopes: const [],
      );
      final past = TwitchAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: now - 1000,
        scopes: const [],
      );

      expect(soon.expiresWithin(const Duration(minutes: 5)), isTrue);
      expect(later.expiresWithin(const Duration(minutes: 5)), isFalse);
      expect(soon.isExpired, isFalse);
      expect(past.isExpired, isTrue);
    });
  });
}
```

- [ ] **Step 3: Run the test — verify it fails**

Run: `flutter test test/persistence/twitch_auth_persistence_test.dart`
Expected: FAIL — compilation error, `lib/models/twitch_auth.dart` does not exist.

- [ ] **Step 4: Create the model + registry entries**

In `lib/models/type_ids.dart`, append to the class (keep existing IDs unchanged):

```dart
  static const int TwitchAuth = 13;
```

In `lib/types/enums/hive_keys.dart`, append as last enum member:

```dart
  /// Returns the single [TwitchAuth] record (key: TwitchAuth.kBoxKey)
  TwitchAuth,
```

Create `lib/models/twitch_auth.dart`:

```dart
import 'package:hive_ce/hive.dart';

import 'type_ids.dart';

part 'twitch_auth.g.dart';

@HiveType(typeId: TypeIDs.TwitchAuth)
class TwitchAuth extends HiveObject {
  @HiveField(0)
  String accessToken;

  @HiveField(1)
  String refreshToken;

  /// Milliseconds since epoch when [accessToken] expires
  @HiveField(2)
  int expiresAtMs;

  @HiveField(3)
  List<String> scopes;

  @HiveField(4)
  String? userId;

  @HiveField(5)
  String? userLogin;

  @HiveField(6)
  String? userDisplayName;

  TwitchAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
    required this.scopes,
    this.userId,
    this.userLogin,
    this.userDisplayName,
  });

  /// Key of the single record inside the TwitchAuth box
  static const String kBoxKey = 'current';

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= this.expiresAtMs;

  /// True when the token expires within [window] (or already expired)
  bool expiresWithin(Duration window) =>
      DateTime.now().millisecondsSinceEpoch >=
      this.expiresAtMs - window.inMilliseconds;
}
```

- [ ] **Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — generates `lib/models/twitch_auth.g.dart` and updates `lib/hive_registrar.g.dart` (leave the registrar file as-is; it is generated but unused).

- [ ] **Step 6: Register adapter + box in production and test harness**

In `lib/main.dart` `_initializeHive()`, add the import next to the other model imports (`import 'models/twitch_auth.dart';` — match the neighboring import style), then directly after `Hive.registerAdapter(HotkeyAdapter());` add:

```dart
  Hive.registerAdapter(TwitchAuthAdapter());
```

In the same function, after the `Hotkey` box opening (same `openBox` pattern as the others):

```dart
  await Hive.openBox<TwitchAuth>(
    HiveKeys.TwitchAuth.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
```

In `test/persistence/support/hive_test_harness.dart`: add
`import 'package:obs_blade/models/twitch_auth.dart';`, append to `registerAllAdapters()`:

```dart
    if (!Hive.isAdapterRegistered(TypeIDs.TwitchAuth)) {
      Hive.registerAdapter<TwitchAuth>(TwitchAuthAdapter());
    }
```

and append to `openAllBoxes()`:

```dart
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
```

In `lib/views/settings/data_management/data_management.dart`, in the Twitch `onClear` block, directly after the two `.delete(...)` lines for `SelectedTwitchUsername` / `TwitchUsernames`, add (plus the `TwitchAuth` model import):

```dart
                  Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).clear();
```

- [ ] **Step 7: Run the test — verify it passes**

Run: `flutter test test/persistence/twitch_auth_persistence_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 8: Analyze**

Run: `flutter analyze`
Expected: no new errors/warnings beyond the 6 pre-existing ones (`input.dart`, `translucent_sliver_app_bar.dart`, `statistics.dart`).

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/models/type_ids.dart lib/models/twitch_auth.dart lib/models/twitch_auth.g.dart lib/types/enums/hive_keys.dart lib/main.dart lib/hive_registrar.g.dart test/persistence/support/hive_test_harness.dart test/persistence/twitch_auth_persistence_test.dart lib/views/settings/data_management/data_management.dart
git commit -m "feat(twitch): TwitchAuth Hive model (typeId 13) + http dependency"
```

---

### Task 2: Device-code DTOs + auth service (request + polling)

**Files:**
- Create: `lib/types/classes/twitch/twitch_device_code.dart`
- Create: `lib/types/classes/twitch/twitch_token.dart`
- Create: `lib/utils/twitch/twitch_auth_service.dart`
- Test: `test/chat/twitch_auth_service_test.dart`

**Interfaces:**
- Consumes: `http` (Task 1).
- Produces: `kTwitchClientId`, `kTwitchChatScopes`, `TwitchAuthException(message, [cause])`, `TwitchDeviceCode(deviceCode, userCode, verificationUri, expiresIn, interval)`, `TwitchToken(accessToken, refreshToken?, expiresIn, scope, tokenType?)`, `TwitchAuthService({http.Client? client, Future<void> Function(Duration)? sleep})` with `requestDeviceCode()` and `pollForToken(deviceCode, {onPending, isCancelled})`. Task 3 extends the same service; Task 6 consumes it.

- [ ] **Step 1: Write the failing test**

Create `test/chat/twitch_auth_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

const kTestDeviceCode = TwitchDeviceCode(
  deviceCode: 'dev-code-123',
  userCode: 'ABCD-EFGH',
  verificationUri: 'https://www.twitch.tv/activate',
  expiresIn: 1800,
  interval: 5,
);

void main() {
  TwitchAuthService serviceWith(MockClient client) =>
      TwitchAuthService(client: client, sleep: (_) async {});

  group('requestDeviceCode', () {
    test('parses the device code response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/device');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['scopes'], 'user:read:chat');
        return http.Response(
          json.encode({
            'device_code': 'dev-code-123',
            'user_code': 'ABCD-EFGH',
            'verification_uri': 'https://www.twitch.tv/activate',
            'expires_in': 1800,
            'interval': 5,
          }),
          200,
        );
      });

      final code = await serviceWith(client).requestDeviceCode();

      expect(code.deviceCode, 'dev-code-123');
      expect(code.userCode, 'ABCD-EFGH');
      expect(code.interval, 5);
      expect(code.expiresIn, 1800);
    });

    test('throws on non-200', () {
      final client =
          MockClient((request) async => http.Response('nope', 400));

      expect(
        serviceWith(client).requestDeviceCode(),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('pollForToken', () {
    test('returns the token after pending responses', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/token');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['device_code'], 'dev-code-123');
        expect(request.bodyFields['grant_type'],
            'urn:ietf:params:oauth:grant-type:device_code');
        if (tokenCalls < 3) {
          return http.Response(
            json.encode({'message': 'authorization_pending'}),
            400,
          );
        }
        return http.Response(
          json.encode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
            'token_type': 'bearer',
          }),
          200,
        );
      });

      final token = await serviceWith(client).pollForToken(
        kTestDeviceCode,
        onPending: () {},
        isCancelled: () => false,
      );

      expect(token.accessToken, 'access-1');
      expect(token.refreshToken, 'refresh-1');
      expect(tokenCalls, 3);
    });

    test('slow_down keeps polling instead of failing', () async {
      var tokenCalls = 0;
      final client = MockClient((request) async {
        tokenCalls++;
        if (tokenCalls == 1) {
          return http.Response(json.encode({'message': 'slow_down'}), 400);
        }
        return http.Response(
          json.encode({
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
          }),
          200,
        );
      });

      final token = await serviceWith(client).pollForToken(
        kTestDeviceCode,
        onPending: () {},
        isCancelled: () => false,
      );

      expect(token.accessToken, 'access-2');
      expect(tokenCalls, 2);
    });

    test('access_denied throws', () {
      final client = MockClient((request) async =>
          http.Response(json.encode({'message': 'access_denied'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });

    test('expired_token throws', () {
      final client = MockClient((request) async =>
          http.Response(json.encode({'message': 'expired_token'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => false,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });

    test('cancellation aborts polling', () {
      final client = MockClient((request) async => http.Response(
          json.encode({'message': 'authorization_pending'}), 400));

      expect(
        serviceWith(client).pollForToken(
          kTestDeviceCode,
          onPending: () {},
          isCancelled: () => true,
        ),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test — verify it fails**

Run: `flutter test test/chat/twitch_auth_service_test.dart`
Expected: FAIL — compilation error, files do not exist.

- [ ] **Step 3: Create the DTOs**

Create `lib/types/classes/twitch/twitch_device_code.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_device_code.freezed.dart';
part 'twitch_device_code.g.dart';

/// RFC 8628 device authorization response from `id.twitch.tv/oauth2/device`
@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class TwitchDeviceCode with _$TwitchDeviceCode {
  const factory TwitchDeviceCode({
    required String deviceCode,
    required String userCode,
    required String verificationUri,
    required int expiresIn,
    required int interval,
  }) = _TwitchDeviceCode;

  factory TwitchDeviceCode.fromJson(Map<String, Object?> json) =>
      _$TwitchDeviceCodeFromJson(json);
}
```

Create `lib/types/classes/twitch/twitch_token.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_token.freezed.dart';
part 'twitch_token.g.dart';

/// User access token response from `id.twitch.tv/oauth2/token`
@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class TwitchToken with _$TwitchToken {
  const factory TwitchToken({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
    @Default(<String>[]) List<String> scope,
    String? tokenType,
  }) = _TwitchToken;

  factory TwitchToken.fromJson(Map<String, Object?> json) =>
      _$TwitchTokenFromJson(json);
}
```

- [ ] **Step 4: Create the auth service**

Create `lib/utils/twitch/twitch_auth_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';

/// Public client id of the "OBS Blade Chat" Twitch developer application
/// (not a secret — Twitch treats client ids as embeddable).
const String kTwitchClientId = 't3muhu36do5wemeeilzl57v48gwcmh';

/// Phase 1 is read-only — `user:write:chat` gets added in Phase 2.
const List<String> kTwitchChatScopes = <String>['user:read:chat'];

const String _kIdBase = 'https://id.twitch.tv/oauth2';
const String _kHelixBase = 'https://api.twitch.tv/helix';

/// Terminal auth-flow failure the UI can surface via [message].
class TwitchAuthException implements Exception {
  final String message;
  final Object? cause;

  const TwitchAuthException(this.message, [this.cause]);

  @override
  String toString() =>
      'TwitchAuthException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// Device code grant (RFC 8628) + token lifecycle against Twitch.
///
/// [client] and [sleep] are injectable for tests — no real HTTP or real
/// polling delays in unit tests.
class TwitchAuthService {
  final http.Client _client;
  final Future<void> Function(Duration) _sleep;

  TwitchAuthService({
    http.Client? client,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _sleep = sleep ?? Future.delayed;

  static Map<String, String> helixHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Client-Id': kTwitchClientId,
      };

  /// Kick off the device flow: the user authorizes [TwitchDeviceCode.userCode]
  /// at [TwitchDeviceCode.verificationUri].
  Future<TwitchDeviceCode> requestDeviceCode() async {
    final response = await this._client.post(
      Uri.parse('$_kIdBase/device'),
      body: {
        'client_id': kTwitchClientId,
        'scopes': kTwitchChatScopes.join(' '),
      },
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Device code request failed (${response.statusCode})',
        response.body,
      );
    }
    return TwitchDeviceCode.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Poll the token endpoint until authorized, expired, denied or cancelled.
  /// Respects the server-provided interval and backs off on `slow_down`.
  Future<TwitchToken> pollForToken(
    TwitchDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    int interval = deviceCode.interval;
    final deadline =
        DateTime.now().add(Duration(seconds: deviceCode.expiresIn));

    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled()) {
        throw const TwitchAuthException('Login cancelled');
      }
      await this._sleep(Duration(seconds: interval));
      await onPending();

      final response = await this._client.post(
        Uri.parse('$_kIdBase/token'),
        body: {
          'client_id': kTwitchClientId,
          'device_code': deviceCode.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      if (response.statusCode == 200) {
        return TwitchToken.fromJson(
          json.decode(response.body) as Map<String, Object?>,
        );
      }

      switch (TwitchAuthService._errorCode(response.body)) {
        case 'authorization_pending':
          break;
        case 'slow_down':
          interval += 5;
          break;
        case 'access_denied':
          throw const TwitchAuthException('Authorization denied on Twitch');
        case 'expired_token':
          throw const TwitchAuthException('Device code expired');
        default:
          throw TwitchAuthException(
            'Token polling failed (${response.statusCode})',
            response.body,
          );
      }
    }
    throw const TwitchAuthException('Device code expired');
  }

  /// RFC 8628 puts the code in `error`; Twitch historically uses `message`.
  static String? _errorCode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['error'] ?? decoded['message']) as String?;
      }
    } catch (_) {
      // non-JSON body
    }
    return null;
  }
}
```

- [ ] **Step 5: Codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — `.freezed.dart` / `.g.dart` for both DTOs.

- [ ] **Step 6: Run the test — verify it passes**

Run: `flutter test test/chat/twitch_auth_service_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/types/classes/twitch/ lib/utils/twitch/ test/chat/twitch_auth_service_test.dart
git commit -m "feat(twitch): device-code auth service (request + token polling)"
```

---

### Task 3: Auth service — refresh, validate, user fetch, revoke

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart`
- Create: `lib/types/classes/twitch/twitch_user.dart`
- Test: `test/chat/twitch_auth_service_test.dart` (extend — new groups)

**Interfaces:**
- Consumes: `TwitchAuthService` base from Task 2.
- Produces: `TwitchAuthService.refreshToken(String)`, `validate(String) → bool`, `fetchOwnUser(String) → TwitchUser`, `revoke(String)` (best effort), `TwitchAuthService.helixHeaders(String)`, `TwitchUser(id, login, displayName?, profileImageUrl?)`. Consumed by Tasks 5 and 6.

- [ ] **Step 1: Write the failing tests**

Append to `test/chat/twitch_auth_service_test.dart` (inside `main()`, plus the `TwitchUser` import is not needed — only service symbols):

```dart
  group('refreshToken', () {
    test('parses the refreshed token pair without a client secret', () async {
      final client = MockClient((request) async {
        expect(request.bodyFields['grant_type'], 'refresh_token');
        expect(request.bodyFields['refresh_token'], 'old-refresh');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields.containsKey('client_secret'), isFalse);
        return http.Response(
          json.encode({
            'access_token': 'access-new',
            'refresh_token': 'refresh-new',
            'expires_in': 14400,
            'scope': ['user:read:chat'],
          }),
          200,
        );
      });

      final token = await serviceWith(client).refreshToken('old-refresh');

      expect(token.accessToken, 'access-new');
      expect(token.refreshToken, 'refresh-new');
    });

    test('throws on 400 (revoked/expired refresh token)', () {
      final client = MockClient((request) async => http.Response(
          json.encode({'message': 'Invalid refresh token'}), 400));

      expect(
        serviceWith(client).refreshToken('old-refresh'),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('validate', () {
    test('true on 200, sends the OAuth (not Bearer) prefix', () async {
      String? seenAuth;
      final client = MockClient((request) async {
        seenAuth = request.headers['Authorization'];
        return http.Response(json.encode({'login': 'kounex'}), 200);
      });

      final valid = await serviceWith(client).validate('access-1');

      expect(valid, isTrue);
      expect(seenAuth, 'OAuth access-1');
    });

    test('false on 401', () async {
      final client =
          MockClient((request) async => http.Response('{}', 401));

      expect(await serviceWith(client).validate('access-1'), isFalse);
    });
  });

  group('fetchOwnUser', () {
    test('parses data[0] of the helix users response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://api.twitch.tv/helix/users');
        expect(request.headers['Authorization'], 'Bearer access-1');
        expect(request.headers['Client-Id'], kTwitchClientId);
        return http.Response(
          json.encode({
            'data': [
              {
                'id': '1234',
                'login': 'kounex',
                'display_name': 'Kounex',
                'profile_image_url': 'https://example.com/p.png',
              }
            ],
          }),
          200,
        );
      });

      final user = await serviceWith(client).fetchOwnUser('access-1');

      expect(user.id, '1234');
      expect(user.login, 'kounex');
      expect(user.displayName, 'Kounex');
    });

    test('throws when data is empty', () {
      final client = MockClient(
          (request) async => http.Response(json.encode({'data': []}), 200));

      expect(
        serviceWith(client).fetchOwnUser('access-1'),
        throwsA(isA<TwitchAuthException>()),
      );
    });
  });

  group('revoke', () {
    test('posts client id + token and never throws', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://id.twitch.tv/oauth2/revoke');
        expect(request.bodyFields['client_id'], kTwitchClientId);
        expect(request.bodyFields['token'], 'access-1');
        return http.Response('', 200);
      });

      await serviceWith(client).revoke('access-1');
    });

    test('swallows network errors (best effort)', () async {
      final client = MockClient((request) async => throw Exception('down'));

      await serviceWith(client).revoke('access-1');
    });
  });
```

- [ ] **Step 2: Run — verify the new tests fail**

Run: `flutter test test/chat/twitch_auth_service_test.dart`
Expected: FAIL — `refreshToken`, `validate`, `fetchOwnUser`, `revoke` undefined.

- [ ] **Step 3: Create the user DTO + extend the service**

Create `lib/types/classes/twitch/twitch_user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'twitch_user.freezed.dart';
part 'twitch_user.g.dart';

/// Entry of the helix `/users` response (`data[0]`)
@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class TwitchUser with _$TwitchUser {
  const factory TwitchUser({
    required String id,
    required String login,
    String? displayName,
    String? profileImageUrl,
  }) = _TwitchUser;

  factory TwitchUser.fromJson(Map<String, Object?> json) =>
      _$TwitchUserFromJson(json);
}
```

Append to `TwitchAuthService` in `lib/utils/twitch/twitch_auth_service.dart` (add the `twitch_user.dart` import):

```dart
  /// Exchange a refresh token for a new token pair. DCF-issued refresh
  /// tokens do not require a client secret.
  Future<TwitchToken> refreshToken(String refreshToken) async {
    final response = await this._client.post(
      Uri.parse('$_kIdBase/token'),
      body: {
        'client_id': kTwitchClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Token refresh failed (${response.statusCode})',
        response.body,
      );
    }
    return TwitchToken.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// Twitch's validate endpoint — note the required `OAuth` prefix
  /// (not `Bearer`, unlike every other endpoint).
  Future<bool> validate(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$_kIdBase/validate'),
      headers: {'Authorization': 'OAuth $accessToken'},
    );
    return response.statusCode == 200;
  }

  /// `GET /helix/users` without a filter returns the token's own user.
  Future<TwitchUser> fetchOwnUser(String accessToken) async {
    final response = await this._client.get(
      Uri.parse('$_kHelixBase/users'),
      headers: TwitchAuthService.helixHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw TwitchAuthException(
        'Fetching the Twitch user failed (${response.statusCode})',
        response.body,
      );
    }
    final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
    if (data is! List || data.isEmpty) {
      throw const TwitchAuthException(
          'Fetching the Twitch user returned no data');
    }
    return TwitchUser.fromJson(data.first as Map<String, Object?>);
  }

  /// Revoke a token (logout hygiene). Best effort — must never block a
  /// local logout because the network is down.
  Future<void> revoke(String accessToken) async {
    try {
      await this._client.post(
        Uri.parse('$_kIdBase/revoke'),
        body: {'client_id': kTwitchClientId, 'token': accessToken},
      );
    } catch (_) {
      // best effort
    }
  }
```

- [ ] **Step 4: Codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded`.

- [ ] **Step 5: Run — verify all tests pass**

Run: `flutter test test/chat/twitch_auth_service_test.dart`
Expected: PASS (15 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/twitch_user.dart lib/types/classes/twitch/twitch_user.freezed.dart lib/types/classes/twitch/twitch_user.g.dart lib/utils/twitch/twitch_auth_service.dart test/chat/twitch_auth_service_test.dart
git commit -m "feat(twitch): token refresh/validate/revoke + own-user fetch"
```

---

### Task 4: EventSub DTOs + parsing

**Files:**
- Create: `lib/types/classes/twitch/eventsub/eventsub_envelope.dart`
- Create: `lib/types/classes/twitch/eventsub/channel_chat_message.dart`
- Create: `test/chat/fixtures/twitch/channel_chat_message_text.json`
- Create: `test/chat/fixtures/twitch/channel_chat_message_emote.json`
- Create: `test/chat/fixtures/twitch/channel_chat_message_cheermote.json`
- Test: `test/chat/twitch_eventsub_dto_test.dart`

**Interfaces:**
- Consumes: freezed (existing).
- Produces: `EventSubEnvelope(metadata, payload)` with `EventSubMetadata(messageId, messageType, subscriptionType?)`; `ChatMessageEvent(broadcasterUserId, chatterUserId, chatterUserLogin, chatterUserName, messageId, message, color?)`; `ChatMessageText(text, fragments)`; `ChatMessageFragment(type, text, emote?)`; `ChatFragmentEmote(id)`; `twitchEmoteUrl(String id)`. Consumed by Tasks 5, 6, 7.

- [ ] **Step 1: Write the fixtures + failing test**

Create `test/chat/fixtures/twitch/channel_chat_message_text.json` (real payload shape from Twitch's docs):

```json
{
  "broadcaster_user_id": "1971641",
  "broadcaster_user_login": "streamer",
  "broadcaster_user_name": "streamer",
  "chatter_user_id": "4145994",
  "chatter_user_login": "viewer32",
  "chatter_user_name": "viewer32",
  "message_id": "cc106a89-1814-919d-454c-f4f2f970aae7",
  "message": {
    "text": "Hi chat",
    "fragments": [
      {
        "type": "text",
        "text": "Hi chat",
        "cheermote": null,
        "emote": null,
        "mention": null
      }
    ]
  },
  "color": "#00FF7F",
  "badges": [
    { "set_id": "moderator", "id": "1", "info": "" },
    { "set_id": "subscriber", "id": "12", "info": "16" }
  ],
  "message_type": "text",
  "cheer": null,
  "reply": null,
  "channel_points_custom_reward_id": null,
  "source_broadcaster_user_id": null,
  "source_broadcaster_user_login": null,
  "source_broadcaster_user_name": null,
  "source_message_id": null,
  "source_badges": null
}
```

Create `test/chat/fixtures/twitch/channel_chat_message_emote.json`:

```json
{
  "broadcaster_user_id": "1971641",
  "broadcaster_user_login": "streamer",
  "broadcaster_user_name": "streamer",
  "chatter_user_id": "555",
  "chatter_user_login": "emoter",
  "chatter_user_name": "emoter",
  "message_id": "11111111-2222-3333-4444-555555555555",
  "message": {
    "text": "Hello Kappa world",
    "fragments": [
      { "type": "text", "text": "Hello ", "cheermote": null, "emote": null, "mention": null },
      { "type": "emote", "text": "Kappa", "cheermote": null, "mention": null,
        "emote": { "id": "25", "emote_set_id": "0", "owner_id": "0", "format": ["static"] } },
      { "type": "text", "text": " world", "cheermote": null, "emote": null, "mention": null }
    ]
  },
  "color": null,
  "badges": [],
  "message_type": "text",
  "cheer": null,
  "reply": null,
  "channel_points_custom_reward_id": null
}
```

Create `test/chat/fixtures/twitch/channel_chat_message_cheermote.json`:

```json
{
  "broadcaster_user_id": "1971641",
  "broadcaster_user_login": "streamer",
  "broadcaster_user_name": "streamer",
  "chatter_user_id": "777",
  "chatter_user_login": "cheerer",
  "chatter_user_name": "cheerer",
  "message_id": "66666666-7777-8888-9999-000000000000",
  "message": {
    "text": "This is a bad message… pogchamp",
    "fragments": [
      { "type": "text", "text": "This is a bad message… ", "cheermote": null, "emote": null, "mention": null },
      { "type": "cheermote", "text": "pogchamp", "emote": null, "mention": null,
        "cheermote": { "prefix": "pogchamp", "bits": 1000, "tier": 1 } }
    ]
  },
  "color": "#FF0000",
  "badges": [],
  "message_type": "text",
  "cheer": { "bits": 1000 },
  "reply": null,
  "channel_points_custom_reward_id": null
}
```

Create `test/chat/twitch_eventsub_dto_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';

ChatMessageEvent eventFromFixture(String name) {
  final file = File('test/chat/fixtures/twitch/$name');
  return ChatMessageEvent.fromJson(
    json.decode(file.readAsStringSync()) as Map<String, Object?>,
  );
}

void main() {
  group('EventSubEnvelope', () {
    test('parses session_welcome metadata', () {
      final envelope = EventSubEnvelope.fromJson(
        json.decode('''
        {
          "metadata": {
            "message_id": "96a3f3b5-5e2d-4e6f-9a1b-2c3d4e5f6a7b",
            "message_type": "session_welcome",
            "message_timestamp": "2026-08-04T10:00:00.000Z"
          },
          "payload": {
            "session": {
              "id": "session-1",
              "status": "connected",
              "keepalive_timeout_seconds": 30,
              "reconnect_url": null
            }
          }
        }
        ''') as Map<String, Object?>,
      );

      expect(envelope.metadata.messageType, 'session_welcome');
      expect(envelope.metadata.subscriptionType, isNull);
      expect((envelope.payload['session'] as Map)['id'], 'session-1');
    });

    test('parses notification metadata with subscription type', () {
      final envelope = EventSubEnvelope.fromJson(
        json.decode('''
        {
          "metadata": {
            "message_id": "1111",
            "message_type": "notification",
            "message_timestamp": "2026-08-04T10:00:00.000Z",
            "subscription_type": "channel.chat.message",
            "subscription_version": "1"
          },
          "payload": { "subscription": {}, "event": {} }
        }
        ''') as Map<String, Object?>,
      );

      expect(envelope.metadata.messageType, 'notification');
      expect(envelope.metadata.subscriptionType, 'channel.chat.message');
    });
  });

  group('ChatMessageEvent', () {
    test('parses a plain text message (real docs payload)', () {
      final event = eventFromFixture('channel_chat_message_text.json');

      expect(event.chatterUserName, 'viewer32');
      expect(event.messageId, 'cc106a89-1814-919d-454c-f4f2f970aae7');
      expect(event.color, '#00FF7F');
      expect(event.message.text, 'Hi chat');
      expect(event.message.fragments, hasLength(1));
      expect(event.message.fragments.first.type, 'text');
      expect(event.message.fragments.first.emote, isNull);
    });

    test('parses emote fragments', () {
      final event = eventFromFixture('channel_chat_message_emote.json');

      expect(event.color, isNull);
      expect(event.message.fragments, hasLength(3));
      final emoteFragment = event.message.fragments[1];
      expect(emoteFragment.type, 'emote');
      expect(emoteFragment.text, 'Kappa');
      expect(emoteFragment.emote?.id, '25');
      expect(twitchEmoteUrl(emoteFragment.emote!.id),
          'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0');
    });

    test('keeps cheermote fragments as plain text', () {
      final event = eventFromFixture('channel_chat_message_cheermote.json');

      expect(event.message.fragments, hasLength(2));
      expect(event.message.fragments[1].type, 'cheermote');
      expect(event.message.fragments[1].text, 'pogchamp');
      expect(event.message.fragments[1].emote, isNull);
    });
  });
}
```

- [ ] **Step 2: Run — verify it fails**

Run: `flutter test test/chat/twitch_eventsub_dto_test.dart`
Expected: FAIL — compilation error, DTO files do not exist.

- [ ] **Step 3: Create the DTOs**

Create `lib/types/classes/twitch/eventsub/eventsub_envelope.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'eventsub_envelope.freezed.dart';
part 'eventsub_envelope.g.dart';

/// Envelope of every EventSub WebSocket message. Only the fields the app
/// needs are modeled — `payload` stays raw and is interpreted by the
/// caller based on [EventSubMetadata.messageType] / `subscriptionType`.
@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class EventSubEnvelope with _$EventSubEnvelope {
  const factory EventSubEnvelope({
    required EventSubMetadata metadata,
    required Map<String, Object?> payload,
  }) = _EventSubEnvelope;

  factory EventSubEnvelope.fromJson(Map<String, Object?> json) =>
      _$EventSubEnvelopeFromJson(json);
}

@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class EventSubMetadata with _$EventSubMetadata {
  const factory EventSubMetadata({
    required String messageId,
    required String messageType,
    String? subscriptionType,
  }) = _EventSubMetadata;

  factory EventSubMetadata.fromJson(Map<String, Object?> json) =>
      _$EventSubMetadataFromJson(json);
}
```

Create `lib/types/classes/twitch/eventsub/channel_chat_message.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_chat_message.freezed.dart';
part 'channel_chat_message.g.dart';

/// CDN URL for a chat emote (dark theme, mid size) — no API call needed.
String twitchEmoteUrl(String emoteId) =>
    'https://static-cdn.jtvnw.net/emoticons/v2/$emoteId/default/dark/2.0';

/// `channel.chat.message` event payload. Badges/cheer/reply are parsed by
/// Twitch's schema but intentionally not modeled in Phase 1.
@Freezed(fromJson: true, toJson: false, fieldRename: FieldRename.snake)
abstract class ChatMessageEvent with _$ChatMessageEvent {
  const factory ChatMessageEvent({
    required String broadcasterUserId,
    required String chatterUserId,
    required String chatterUserLogin,
    required String chatterUserName,
    required String messageId,
    required ChatMessageText message,
    String? color,
  }) = _ChatMessageEvent;

  factory ChatMessageEvent.fromJson(Map<String, Object?> json) =>
      _$ChatMessageEventFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageText with _$ChatMessageText {
  const factory ChatMessageText({
    required String text,
    @Default(<ChatMessageFragment>[]) List<ChatMessageFragment> fragments,
  }) = _ChatMessageText;

  factory ChatMessageText.fromJson(Map<String, Object?> json) =>
      _$ChatMessageTextFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatMessageFragment with _$ChatMessageFragment {
  const factory ChatMessageFragment({
    required String type,
    required String text,
    ChatFragmentEmote? emote,
  }) = _ChatMessageFragment;

  factory ChatMessageFragment.fromJson(Map<String, Object?> json) =>
      _$ChatMessageFragmentFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatFragmentEmote with _$ChatFragmentEmote {
  const factory ChatFragmentEmote({
    required String id,
  }) = _ChatFragmentEmote;

  factory ChatFragmentEmote.fromJson(Map<String, Object?> json) =>
      _$ChatFragmentEmoteFromJson(json);
}
```

- [ ] **Step 4: Codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded`.

- [ ] **Step 5: Run — verify it passes**

Run: `flutter test test/chat/twitch_eventsub_dto_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/types/classes/twitch/eventsub/ test/chat/fixtures/twitch/ test/chat/twitch_eventsub_dto_test.dart
git commit -m "feat(twitch): EventSub envelope + chat message DTOs with fixtures"
```

---

### Task 5: EventSub WebSocket service

**Files:**
- Create: `lib/utils/twitch/twitch_eventsub_service.dart`
- Test: `test/chat/twitch_eventsub_service_test.dart`

**Interfaces:**
- Consumes: `EventSubEnvelope`, `ChatMessageEvent` (Task 4), `TwitchAuthService.helixHeaders` (Task 3).
- Produces: `enum TwitchEventSubState { disconnected, connecting, connected, reconnecting }`; `TwitchEventSubService({required onChatMessage, required onStateChanged, required onRevoked, http.Client? client, WebSocketChannel Function(Uri)? channelFactory, Future<void> Function(Duration)? sleep})` with `connect({required String accessToken, required String userId})` and `dispose()`. Consumed by Task 6; faked in Task 6/7 tests.

- [ ] **Step 1: Write the failing test**

Create `test/chat/twitch_eventsub_service_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeWebSocketChannel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>();
  final List<dynamic> sent = <dynamic>[];
  bool closeCalled = false;

  @override
  Stream<dynamic> get stream => this.incoming.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(this);
}

class _FakeWebSocketSink extends Fake implements WebSocketSink {
  final FakeWebSocketChannel channel;

  _FakeWebSocketSink(this.channel);

  @override
  void add(dynamic data) => this.channel.sent.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    this.channel.closeCalled = true;
    await this.channel.incoming.close();
  }
}

void main() {
  late List<FakeWebSocketChannel> channels;
  late List<TwitchEventSubState> states;
  late List<ChatMessageEvent> messages;
  late List<String> revocations;

  String welcome(String sessionId) => json.encode({
        'metadata': {
          'message_id': 'w1',
          'message_type': 'session_welcome',
          'message_timestamp': '2026-08-04T10:00:00.000Z',
        },
        'payload': {
          'session': {
            'id': sessionId,
            'status': 'connected',
            'keepalive_timeout_seconds': 30,
            'reconnect_url': null,
          },
        },
      });

  String notification() {
    final event = json.decode(File(
            'test/chat/fixtures/twitch/channel_chat_message_text.json')
        .readAsStringSync());
    return json.encode({
      'metadata': {
        'message_id': 'n1',
        'message_type': 'notification',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
        'subscription_type': 'channel.chat.message',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {'type': 'channel.chat.message'},
        'event': event,
      },
    });
  }

  TwitchEventSubService serviceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onStateChanged: states.add,
        onRevoked: revocations.add,
        client: client,
        channelFactory: (uri) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      );

  setUp(() {
    channels = [];
    states = [];
    messages = [];
    revocations = [];
  });

  test('welcome triggers a subscription with the session id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
      final body = json.decode(request.body) as Map<String, dynamic>;
      expect(body['type'], 'channel.chat.message');
      expect(body['version'], '1');
      expect(body['condition'], {
        'broadcaster_user_id': 'user-1',
        'user_id': 'user-1',
      });
      expect(body['transport'], {
        'method': 'websocket',
        'session_id': 'session-1',
      });
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-1'}
          ],
        }),
        202,
      );
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(states, contains(TwitchEventSubState.connected));
  });

  test('notification parses into a chat message event', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(notification());
    await pumpEventQueue();

    expect(messages, hasLength(1));
    expect(messages.single.chatterUserName, 'viewer32');
    expect(messages.single.message.text, 'Hi chat');
  });

  test('session_reconnect opens a new socket at the reconnect url without resubscribing', () async {
    var subscriptionPosts = 0;
    final client = MockClient((request) async {
      subscriptionPosts++;
      return http.Response(
          json.encode({'data': [{'id': 'sub-1'}]}), 202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    expect(subscriptionPosts, 1);

    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'r1',
        'message_type': 'session_reconnect',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
      },
      'payload': {
        'session': {
          'id': 'session-1',
          'status': 'reconnecting',
          'reconnect_url': 'wss://eventsub.wss.twitch.tv/ws?resume=abc',
        },
      },
    }));
    await pumpEventQueue();
    expect(channels, hasLength(2));

    /// Resumed session: same session id → no new subscription
    channels[1].incoming.add(welcome('session-1'));
    await pumpEventQueue();
    expect(subscriptionPosts, 1);
  });

  test('socket close triggers a reconnect via the injected sleep', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await channels.single.incoming.close();
    await pumpEventQueue();

    expect(channels, hasLength(2));
    expect(states, contains(TwitchEventSubState.reconnecting));
  });

  test('revocation is forwarded with its status', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'v1',
        'message_type': 'revocation',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
        'subscription_type': 'channel.chat.message',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {'status': 'authorization_revoked'},
      },
    }));
    await pumpEventQueue();

    expect(revocations, ['authorization_revoked']);
  });

  test('dispose deletes the subscription best-effort', () async {
    String? deletedUrl;
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        deletedUrl = request.url.toString();
        return http.Response('', 204);
      }
      return http.Response(
          json.encode({'data': [{'id': 'sub-1'}]}), 202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await service.dispose();
    expect(deletedUrl,
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-1');
  });
}
```

- [ ] **Step 2: Run — verify it fails**

Run: `flutter test test/chat/twitch_eventsub_service_test.dart`
Expected: FAIL — compilation error, service does not exist.

- [ ] **Step 3: Create the service**

Create `lib/utils/twitch/twitch_eventsub_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum TwitchEventSubState { disconnected, connecting, connected, reconnecting }

/// Dedicated EventSub WebSocket session for `channel.chat.message`.
/// Completely separate from the OBS WebSocket — owns its socket, keepalive
/// watchdog and reconnect backoff. [channelFactory] and [sleep] are
/// injectable for tests.
class TwitchEventSubService {
  static const String _wsUrl =
      'wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30';
  static const String _subscriptionsUrl =
      'https://api.twitch.tv/helix/eventsub/subscriptions';

  /// No message (not even a keepalive) for this long → treat as dead
  static const Duration _watchdogWindow = Duration(seconds: 75);
  static const Duration _maxBackoff = Duration(seconds: 30);

  final http.Client _client;
  final WebSocketChannel Function(Uri) _channelFactory;
  final Future<void> Function(Duration) _sleep;

  final void Function(ChatMessageEvent event) onChatMessage;
  final void Function(TwitchEventSubState state) onStateChanged;

  /// Subscription revoked by Twitch (e.g. `authorization_revoked`) or
  /// creation failed (`subscription_failed:<status>`)
  final void Function(String reason) onRevoked;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _watchdog;

  String? _accessToken;
  String? _userId;
  String? _sessionId;
  String? _subscriptionId;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  TwitchEventSubService({
    required this.onChatMessage,
    required this.onStateChanged,
    required this.onRevoked,
    http.Client? client,
    WebSocketChannel Function(Uri)? channelFactory,
    Future<void> Function(Duration)? sleep,
  })  : _client = client ?? http.Client(),
        _channelFactory = channelFactory ?? WebSocketChannel.connect,
        _sleep = sleep ?? Future.delayed;

  Future<void> connect({
    required String accessToken,
    required String userId,
  }) async {
    this._accessToken = accessToken;
    this._userId = userId;
    this._disposed = false;
    this._reconnectAttempts = 0;
    this._openSocket(Uri.parse(_wsUrl));
  }

  void _openSocket(Uri uri) {
    if (this._disposed) return;
    this.onStateChanged(
      this._reconnectAttempts == 0
          ? TwitchEventSubState.connecting
          : TwitchEventSubState.reconnecting,
    );
    this._channel = this._channelFactory(uri);
    this._socketSub = this._channel!.stream.listen(
      this._handleRawMessage,
      onDone: this._handleDisconnect,
      onError: (_) => this._handleDisconnect(),
      cancelOnError: true,
    );
    this._resetWatchdog();
  }

  void _handleRawMessage(dynamic raw) {
    this._resetWatchdog();

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: undecodable message — $e');
      return;
    }

    final envelope = EventSubEnvelope.fromJson(decoded);
    switch (envelope.metadata.messageType) {
      case 'session_welcome':
        this._handleWelcome(envelope.payload);
        break;
      case 'session_keepalive':
        break; // watchdog already reset
      case 'notification':
        this._handleNotification(envelope);
        break;
      case 'session_reconnect':
        this._handleReconnectRequest(envelope.payload);
        break;
      case 'revocation':
        this._handleRevocation(envelope.payload);
        break;
      default:
        GeneralHelper.advLog(
          'Twitch EventSub: unknown message_type '
          '${envelope.metadata.messageType}',
        );
    }
  }

  Future<void> _handleWelcome(Map<String, Object?> payload) async {
    final session = payload['session'] as Map<String, dynamic>;
    final sessionId = session['id'] as String;
    final resumed = sessionId == this._sessionId && this._subscriptionId != null;
    this._sessionId = sessionId;
    this._reconnectAttempts = 0;
    this.onStateChanged(TwitchEventSubState.connected);

    /// A socket opened from `session_reconnect`'s reconnect_url resumes the
    /// session with subscriptions intact — only subscribe on fresh sessions.
    if (!resumed) {
      await this._createSubscription();
    }
  }

  void _handleNotification(EventSubEnvelope envelope) {
    if (envelope.metadata.subscriptionType != 'channel.chat.message') return;
    try {
      this.onChatMessage(
        ChatMessageEvent.fromJson(
          envelope.payload['event'] as Map<String, Object?>,
        ),
      );
    } catch (e) {
      GeneralHelper.advLog('Twitch EventSub: could not parse chat event — $e');
    }
  }

  void _handleReconnectRequest(Map<String, Object?> payload) {
    final session = payload['session'] as Map<String, dynamic>;
    final reconnectUrl = session['reconnect_url'] as String?;
    if (reconnectUrl == null) {
      this._handleDisconnect();
      return;
    }
    this._closeSocket();
    this._openSocket(Uri.parse(reconnectUrl));
  }

  void _handleRevocation(Map<String, Object?> payload) {
    final subscription = payload['subscription'] as Map<String, dynamic>;
    this.onRevoked(subscription['status'] as String? ?? 'revoked');
  }

  Future<void> _createSubscription() async {
    final token = this._accessToken;
    final userId = this._userId;
    final sessionId = this._sessionId;
    if (token == null || userId == null || sessionId == null) return;

    final response = await this._client.post(
      Uri.parse(_subscriptionsUrl),
      headers: {
        ...TwitchAuthService.helixHeaders(token),
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': 'channel.chat.message',
        'version': '1',
        'condition': {'broadcaster_user_id': userId, 'user_id': userId},
        'transport': {'method': 'websocket', 'session_id': sessionId},
      }),
    );

    if (response.statusCode == 202) {
      final data = (json.decode(response.body) as Map<String, dynamic>)['data'];
      this._subscriptionId = (data as List).first['id'] as String?;
    } else {
      this.onRevoked('subscription_failed:${response.statusCode}');
    }
  }

  void _handleDisconnect() {
    if (this._disposed) return;
    this._closeSocket();
    this._reconnectAttempts++;
    this.onStateChanged(TwitchEventSubState.reconnecting);
    final backoff = Duration(
      seconds: (this._reconnectAttempts * 2).clamp(2, _maxBackoff.inSeconds),
    );
    this._sleep(backoff).then((_) {
      if (!this._disposed) this._openSocket(Uri.parse(_wsUrl));
    });
  }

  void _resetWatchdog() {
    this._watchdog?.cancel();
    this._watchdog = Timer(_watchdogWindow, this._handleDisconnect);
  }

  void _closeSocket() {
    this._watchdog?.cancel();
    this._socketSub?.cancel();
    this._socketSub = null;
    this._channel?.sink.close();
    this._channel = null;
  }

  /// Tear down the session. Deleting the subscription is best effort —
  /// Twitch drops it anyway once the session times out.
  Future<void> dispose() async {
    this._disposed = true;
    this._closeSocket();

    final subscriptionId = this._subscriptionId;
    final token = this._accessToken;
    this._subscriptionId = null;
    if (subscriptionId != null && token != null) {
      try {
        await this._client.delete(
          Uri.parse('$_subscriptionsUrl?id=$subscriptionId'),
          headers: TwitchAuthService.helixHeaders(token),
        );
      } catch (_) {
        // best effort
      }
    }
  }
}
```

- [ ] **Step 4: Run — verify it passes**

Run: `flutter test test/chat/twitch_eventsub_service_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/utils/twitch/twitch_eventsub_service.dart test/chat/twitch_eventsub_service_test.dart
git commit -m "feat(twitch): EventSub WebSocket service with reconnect + watchdog"
```

---

### Task 6: `TwitchChatStore` + GetIt registration

**Files:**
- Create: `lib/stores/views/twitch_chat.dart`
- Modify: `lib/main.dart` (register the store)
- Test: `test/chat/twitch_chat_store_test.dart`

**Interfaces:**
- Consumes: `TwitchAuthService` (Tasks 2/3), `TwitchEventSubService` + `TwitchEventSubState` (Task 5), `TwitchAuth` + `HiveKeys.TwitchAuth` (Task 1), `ChatMessageEvent` (Task 4), `TwitchUser` (Task 3).
- Produces: `enum TwitchAuthState { loggedOut, requestingCode, awaitingAuthorization, loggingIn, loggedIn, error }`; `enum TwitchChatConnectionState { disconnected, connecting, live, reconnecting, failed }`; `TwitchChatStore` with observables `authState`, `authError`, `pendingUserCode`, `pendingVerificationUri`, `user`, `chatConnection`, `chatError`, `ObservableList<ChatMessageEvent> messages`, computed `isLoggedIn`; actions `init()`, `startLogin()`, `cancelLogin()`, `logout()`, `connectChat()`, `dispose()`. Consumed by Tasks 7 and 8.

- [ ] **Step 1: Write the failing test**

Create `test/chat/twitch_chat_store_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/twitch_device_code.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';

import '../persistence/support/hive_test_harness.dart';

class FakeTwitchAuthService extends TwitchAuthService {
  bool validateResult = true;
  TwitchAuthException? failPollWith;
  String? revokedToken;

  static const token = TwitchToken(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresIn: 14400,
    scope: ['user:read:chat'],
  );

  static const user = TwitchUser(
    id: 'user-1',
    login: 'kounex',
    displayName: 'Kounex',
  );

  @override
  Future<TwitchDeviceCode> requestDeviceCode() async =>
      const TwitchDeviceCode(
        deviceCode: 'dev',
        userCode: 'ABCD',
        verificationUri: 'https://www.twitch.tv/activate',
        expiresIn: 1800,
        interval: 0,
      );

  @override
  Future<TwitchToken> pollForToken(
    TwitchDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    if (isCancelled()) throw const TwitchAuthException('Login cancelled');
    if (this.failPollWith != null) throw this.failPollWith!;
    return token;
  }

  @override
  Future<TwitchUser> fetchOwnUser(String accessToken) async => user;

  @override
  Future<bool> validate(String accessToken) async => this.validateResult;

  @override
  Future<TwitchToken> refreshToken(String refreshToken) async => token;

  @override
  Future<void> revoke(String accessToken) async {
    this.revokedToken = accessToken;
  }
}

class FakeTwitchEventSubService extends TwitchEventSubService {
  bool connectCalled = false;
  String? lastAccessToken;
  bool disposeCalled = false;

  FakeTwitchEventSubService()
      : super(
          onChatMessage: (_) {},
          onStateChanged: (_) {},
          onRevoked: (_) {},
        );

  @override
  Future<void> connect({
    required String accessToken,
    required String userId,
  }) async {
    this.connectCalled = true;
    this.lastAccessToken = accessToken;
  }

  @override
  Future<void> dispose() async {
    this.disposeCalled = true;
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late TwitchChatStore store;

  Box<TwitchAuth> authBox() => Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___) => eventSubService,
    );
  });

  tearDown(() async {
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('init', () {
    test('logged out without a stored record', () async {
      await store.init();
      expect(store.authState, TwitchAuthState.loggedOut);
    });

    test('valid stored token → logged in with the stored user', () async {
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
          userId: 'user-1',
          userLogin: 'kounex',
          userDisplayName: 'Kounex',
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.isLoggedIn, isTrue);
      expect(store.user?.login, 'kounex');
    });

    test('invalid stored token → wiped + logged out', () async {
      authService.validateResult = false;
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'stale',
          refreshToken: 'stale',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
    });
  });

  group('startLogin', () {
    test('success persists the auth, sets the user and connects chat', () async {
      await store.startLogin();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');
      final stored = authBox().get(TwitchAuth.kBoxKey);
      expect(stored?.accessToken, 'access-1');
      expect(stored?.userId, 'user-1');
      expect(eventSubService.connectCalled, isTrue);
      expect(eventSubService.lastAccessToken, 'access-1');
    });

    test('poll failure lands in error state without a stored record', () async {
      authService.failPollWith =
          const TwitchAuthException('Authorization denied on Twitch');

      await store.startLogin();

      expect(store.authState, TwitchAuthState.error);
      expect(store.authError, 'Authorization denied on Twitch');
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(eventSubService.connectCalled, isFalse);
    });

    test('cancelLogin returns to logged out without an error', () async {
      final login = store.startLogin();
      store.cancelLogin();
      await login;

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.authError, isNull);
    });
  });

  group('logout', () {
    test('wipes the box, revokes and disconnects chat', () async {
      await store.startLogin();
      expect(store.isLoggedIn, isTrue);

      await store.logout();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.user, isNull);
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(authService.revokedToken, 'access-1');
      expect(eventSubService.disposeCalled, isTrue);
    });
  });

  group('external wipe (data management)', () {
    test('deleting the box record resets to logged out', () async {
      await store.startLogin();
      expect(store.isLoggedIn, isTrue);

      await authBox().delete(TwitchAuth.kBoxKey);
      await pumpEventQueue();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.user, isNull);
    });
  });

  group('message buffer', () {
    ChatMessageEvent event(String id) => ChatMessageEvent(
          broadcasterUserId: 'user-1',
          chatterUserId: id,
          chatterUserLogin: 'u$id',
          chatterUserName: 'User$id',
          messageId: id,
          message: ChatMessageText(
            text: 'msg $id',
            fragments: [
              ChatMessageFragment(type: 'text', text: 'msg $id'),
            ],
          ),
        );

    test('appends via the exposed action and trims at 500', () {
      for (var i = 0; i < 505; i++) {
        store.appendChatMessageForTest(event('$i'));
      }

      expect(store.messages, hasLength(500));
      expect(store.messages.first.messageId, '5');
      expect(store.messages.last.messageId, '504');
    });
  });
}
```

- [ ] **Step 2: Run — verify it fails**

Run: `flutter test test/chat/twitch_chat_store_test.dart`
Expected: FAIL — compilation error, `lib/stores/views/twitch_chat.dart` does not exist.

- [ ] **Step 3: Create the store**

Create `lib/stores/views/twitch_chat.dart`:

```dart
import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';

part 'twitch_chat.g.dart';

enum TwitchAuthState {
  loggedOut,
  requestingCode,
  awaitingAuthorization,
  loggingIn,
  loggedIn,
  error,
}

enum TwitchChatConnectionState {
  disconnected,
  connecting,
  live,
  reconnecting,
  failed,
}

class TwitchChatStore = _TwitchChatStore with _$TwitchChatStore;

/// Owns the native Twitch chat: device-flow login state, the persisted
/// [TwitchAuth] record and the EventSub-backed message buffer.
abstract class _TwitchChatStore with Store {
  static const int kMaxMessages = 500;
  static const Duration kRefreshWindow = Duration(minutes: 5);

  final TwitchAuthService _authService;
  final TwitchEventSubService Function(
    void Function(ChatMessageEvent) onChatMessage,
    void Function(TwitchEventSubState) onStateChanged,
    void Function(String) onRevoked,
  ) _eventSubFactory;

  TwitchEventSubService? _eventSub;
  StreamSubscription<BoxEvent>? _authBoxSub;
  bool _loginCancelled = false;

  _TwitchChatStore({
    TwitchAuthService? authService,
    TwitchEventSubService Function(
      void Function(ChatMessageEvent),
      void Function(TwitchEventSubState),
      void Function(String),
    )? eventSubFactory,
  })  : _authService = authService ?? TwitchAuthService(),
        _eventSubFactory = eventSubFactory ??
            ((onChatMessage, onStateChanged, onRevoked) =>
                TwitchEventSubService(
                  onChatMessage: onChatMessage,
                  onStateChanged: onStateChanged,
                  onRevoked: onRevoked,
                ));

  Box<TwitchAuth> get _authBox =>
      Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  @observable
  TwitchAuthState authState = TwitchAuthState.loggedOut;

  @observable
  String? authError;

  @observable
  String? pendingUserCode;

  @observable
  String? pendingVerificationUri;

  @observable
  TwitchUser? user;

  @observable
  TwitchChatConnectionState chatConnection =
      TwitchChatConnectionState.disconnected;

  @observable
  String? chatError;

  final ObservableList<ChatMessageEvent> messages =
      ObservableList<ChatMessageEvent>();

  @computed
  bool get isLoggedIn => this.authState == TwitchAuthState.loggedIn;

  /// Registers the box watcher (idempotent) so external wipes — e.g.
  /// data management clearing the Twitch box — reset the feature even
  /// when [init] never ran for this instance (fresh login path).
  void _ensureAuthBoxWatcher() {
    this._authBoxSub ??= this
        ._authBox
        .watch(key: TwitchAuth.kBoxKey)
        .listen((event) {
      if (event.deleted && this.authState != TwitchAuthState.loggedOut) {
        this._resetToLoggedOut();
      }
    });
  }

  /// Cold start: validate a stored token (Twitch requires periodic
  /// validation); when still valid, log straight in and connect chat.
  @action
  Future<void> init() async {
    this._ensureAuthBoxWatcher();

    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    if (auth == null) return;

    final valid = await this._authService.validate(auth.accessToken);
    if (!valid) {
      await this._handleInvalidAuth('Twitch session expired — please log in again');
      return;
    }
    this.user = TwitchUser(
      id: auth.userId ?? '',
      login: auth.userLogin ?? '',
      displayName: auth.userDisplayName,
    );
    this.authState = TwitchAuthState.loggedIn;
    await this.connectChat();
  }

  @action
  Future<void> startLogin() async {
    this._loginCancelled = false;
    this._ensureAuthBoxWatcher();
    this.authError = null;
    this.pendingUserCode = null;
    this.pendingVerificationUri = null;
    this.authState = TwitchAuthState.requestingCode;

    try {
      final deviceCode = await this._authService.requestDeviceCode();
      this.pendingUserCode = deviceCode.userCode;
      this.pendingVerificationUri = deviceCode.verificationUri;
      this.authState = TwitchAuthState.awaitingAuthorization;

      final token = await this._authService.pollForToken(
        deviceCode,
        onPending: () {},
        isCancelled: () => this._loginCancelled,
      );

      this.authState = TwitchAuthState.loggingIn;
      final user = await this._authService.fetchOwnUser(token.accessToken);
      await this._persistAuth(token, user);
      this.user = user;
      this.pendingUserCode = null;
      this.pendingVerificationUri = null;
      this.authState = TwitchAuthState.loggedIn;
      await this.connectChat();
    } on TwitchAuthException catch (e) {
      this.pendingUserCode = null;
      if (this._loginCancelled) {
        this.authState = TwitchAuthState.loggedOut;
      } else {
        this.authState = TwitchAuthState.error;
        this.authError = e.message;
      }
    } catch (e) {
      GeneralHelper.advLog('Twitch login failed unexpectedly — $e');
      this.pendingUserCode = null;
      this.authState = TwitchAuthState.error;
      this.authError = 'Unexpected login error';
    }
  }

  @action
  void cancelLogin() {
    this._loginCancelled = true;
  }

  @action
  Future<void> logout() async {
    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    await this._disconnectChat();
    this.messages.clear();
    this.user = null;
    this.authState = TwitchAuthState.loggedOut;
    await this._authBox.delete(TwitchAuth.kBoxKey);
    if (auth != null) {
      await this._authService.revoke(auth.accessToken);
    }
  }

  /// (Re)connect the EventSub session — called after login and by the UI
  /// retry action.
  @action
  Future<void> connectChat() async {
    if (this.authState != TwitchAuthState.loggedIn) return;
    this.chatError = null;
    this.chatConnection = TwitchChatConnectionState.connecting;

    try {
      final token = await this._validAccessToken();
      await this._eventSub?.dispose();
      this._eventSub = this._eventSubFactory(
        this._appendMessage,
        this._onEventSubState,
        this._onEventSubRevoked,
      );
      await this._eventSub!.connect(
        accessToken: token,
        userId: this.user!.id,
      );
    } on TwitchAuthException catch (e) {
      await this._handleInvalidAuth(e.message);
    } catch (e) {
      GeneralHelper.advLog('Twitch chat connect failed — $e');
      this.chatConnection = TwitchChatConnectionState.failed;
      this.chatError = 'Could not connect to Twitch chat';
    }
  }

  Future<String> _validAccessToken() async {
    final auth = this._authBox.get(TwitchAuth.kBoxKey);
    if (auth == null) throw const TwitchAuthException('Not logged in');

    if (auth.expiresWithin(kRefreshWindow)) {
      final token = await this._authService.refreshToken(auth.refreshToken);
      auth
        ..accessToken = token.accessToken
        ..refreshToken = token.refreshToken ?? auth.refreshToken
        ..expiresAtMs = DateTime.now().millisecondsSinceEpoch +
            token.expiresIn * 1000;
      await auth.save();
    }
    return auth.accessToken;
  }

  Future<void> _persistAuth(TwitchToken token, TwitchUser user) async {
    await this._authBox.put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken ?? '',
        expiresAtMs:
            DateTime.now().millisecondsSinceEpoch + token.expiresIn * 1000,
        scopes: token.scope,
        userId: user.id,
        userLogin: user.login,
        userDisplayName: user.displayName,
      ),
    );
  }

  @action
  void _appendMessage(ChatMessageEvent event) {
    this.messages.add(event);
    while (this.messages.length > kMaxMessages) {
      this.messages.removeAt(0);
    }
  }

  /// Test seam — the store's message intake is normally fed by the
  /// EventSub service callback.
  @action
  void appendChatMessageForTest(ChatMessageEvent event) =>
      this._appendMessage(event);

  void _onEventSubState(TwitchEventSubState state) {
    runInAction(() {
      switch (state) {
        case TwitchEventSubState.connected:
          this.chatConnection = TwitchChatConnectionState.live;
          break;
        case TwitchEventSubState.connecting:
          this.chatConnection = TwitchChatConnectionState.connecting;
          break;
        case TwitchEventSubState.reconnecting:
          this.chatConnection = TwitchChatConnectionState.reconnecting;
          break;
        case TwitchEventSubState.disconnected:
          this.chatConnection = TwitchChatConnectionState.disconnected;
          break;
      }
    });
  }

  void _onEventSubRevoked(String reason) {
    if (reason.contains('authorization_revoked') ||
        reason.contains('user_removed') ||
        reason.startsWith('subscription_failed:401')) {
      this._handleInvalidAuth(
          'Twitch access was revoked — please log in again');
    } else {
      runInAction(() {
        this.chatConnection = TwitchChatConnectionState.failed;
        this.chatError = 'Twitch chat subscription failed ($reason)';
      });
    }
  }

  Future<void> _handleInvalidAuth(String message) async {
    await this._disconnectChat();
    await this._authBox.delete(TwitchAuth.kBoxKey);
    runInAction(() {
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
      this.authError = message;
    });
  }

  void _resetToLoggedOut() {
    runInAction(() {
      this.messages.clear();
      this.user = null;
      this.authState = TwitchAuthState.loggedOut;
    });
    this._disconnectChat();
  }

  Future<void> _disconnectChat() async {
    final eventSub = this._eventSub;
    this._eventSub = null;
    await eventSub?.dispose();
    runInAction(() {
      this.chatConnection = TwitchChatConnectionState.disconnected;
    });
  }

  Future<void> dispose() async {
    await this._authBoxSub?.cancel();
    await this._disconnectChat();
  }
}
```

- [ ] **Step 4: Register the store + codegen**

In `lib/main.dart` `_initializeStores()`, after the `LogsStore` registration, add (plus `import 'stores/views/twitch_chat.dart';` matching the neighboring import style):

```dart
  GetIt.instance.registerLazySingleton<TwitchChatStore>(
    /// Fire-and-forget [init] — cold-start token validation must not
    /// block store creation.
    () => TwitchChatStore()..init(),
    dispose: (store) => store.dispose(),
  );
```

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded` — generates `lib/stores/views/twitch_chat.g.dart`.

- [ ] **Step 5: Run — verify it passes**

Run: `flutter test test/chat/twitch_chat_store_test.dart`
Expected: PASS (8 tests).

- [ ] **Step 6: Analyze**

Run: `flutter analyze`
Expected: no new errors/warnings.

- [ ] **Step 7: Commit**

```bash
git add lib/stores/views/twitch_chat.dart lib/stores/views/twitch_chat.g.dart lib/main.dart test/chat/twitch_chat_store_test.dart
git commit -m "feat(twitch): TwitchChatStore (login state, token lifecycle, message buffer)"
```

---

### Task 7: Native chat UI (message row + view)

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`
- Create: `test/chat/support/fake_twitch_services.dart` (fakes shared by Task 6 + Task 7 tests)
- Test: `test/chat/native_twitch_chat_view_test.dart`

**Interfaces:**
- Consumes: `TwitchChatStore` + `TwitchChatConnectionState` (Task 6), `ChatMessageEvent` + `twitchEmoteUrl` (Task 4), design tokens `AppSpacing`/`AppRadius`/`AppMotion`, `Pressable`.
- Produces: `TwitchChatMessageRow({required ChatMessageEvent event})`, `NativeTwitchChatView()`. Consumed by Task 8.

- [ ] **Step 1: Extract the shared test fakes**

Create `test/chat/support/fake_twitch_services.dart` by **moving** the `FakeTwitchAuthService` and `FakeTwitchEventSubService` classes out of `test/chat/twitch_chat_store_test.dart` (verbatim, plus their imports: `dart:async`, `twitch_device_code.dart`, `twitch_token.dart`, `twitch_user.dart`, `twitch_auth_service.dart`, `twitch_eventsub_service.dart`). In `twitch_chat_store_test.dart` delete both classes and import `support/fake_twitch_services.dart` instead.

Run: `flutter test test/chat/twitch_chat_store_test.dart`
Expected: PASS (8 tests) — pure move, no behavior change.

- [ ] **Step 2: Write the failing widget test**

Create `test/chat/native_twitch_chat_view_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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

void main() {
  late TwitchChatStore store;
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_chat_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);

    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
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
        wrap(TwitchChatMessageRow(event: textEvent('1', 'Viewer32', 'Hi chat'))),
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

      await tester.pumpWidget(wrap(TwitchChatMessageRow(event: event)));

      final richText = tester.widget<RichText>(find.byType(RichText));
      final widgetSpan =
          richText.text.children!.whereType<WidgetSpan>().single;
      final image = widgetSpan.child as Image;
      expect(
        (image.image as NetworkImage).url,
        'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0',
      );
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
```

- [ ] **Step 3: Run — verify it fails**

Run: `flutter test test/chat/native_twitch_chat_view_test.dart`
Expected: FAIL — compilation error, view/row do not exist.

- [ ] **Step 4: Create the message row**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

/// One chat line: colored author name + message text with inline emotes.
/// Cheermote/mention fragments fall back to plain text in Phase 1.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  const TwitchChatMessageRow({super.key, required this.event});

  static const double _emoteSize = 20.0;

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
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
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
    );
  }
}
```

- [ ] **Step 5: Create the view**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'twitch_chat_message_row.dart';

/// Native read-only Twitch chat. Lives in the same dashboard slot the
/// WebView chat uses — driven by [TwitchChatStore]'s message buffer.
class NativeTwitchChatView extends StatefulWidget {
  const NativeTwitchChatView({super.key});

  @override
  State<NativeTwitchChatView> createState() => _NativeTwitchChatViewState();
}

class _NativeTwitchChatViewState extends State<NativeTwitchChatView> {
  final ScrollController _scrollController = ScrollController();

  /// Pinned to the newest message until the user scrolls up
  bool _pinnedToBottom = true;
  bool _unreadWhileScrolledUp = false;
  int _lastRenderedCount = 0;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  @override
  void initState() {
    super.initState();
    this._scrollController.addListener(this._onScroll);
  }

  void _onScroll() {
    if (!this._scrollController.hasClients) return;
    final atBottom = this._scrollController.position.pixels >=
        this._scrollController.position.maxScrollExtent - 24.0;
    if (atBottom && !this._pinnedToBottom) {
      setState(() {
        this._pinnedToBottom = true;
        this._unreadWhileScrolledUp = false;
      });
    } else if (!atBottom && this._pinnedToBottom) {
      setState(() => this._pinnedToBottom = false);
    }
  }

  void _scrollToBottom() {
    if (!this._scrollController.hasClients) return;
    this._scrollController.animateTo(
      this._scrollController.position.maxScrollExtent,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    this._scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final connection = this._store.chatConnection;
        final messageCount = this._store.messages.length;

        if (connection == TwitchChatConnectionState.connecting &&
            messageCount == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Connecting to Twitch chat…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (connection == TwitchChatConnectionState.failed &&
            messageCount == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Text(
                    this._store.chatError ?? 'Could not connect to Twitch chat',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Pressable(
                  haptic: true,
                  onTap: () => this._store.connectChat(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      'Retry',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (messageCount == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Connected — waiting for messages…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        /// New-frame bookkeeping: jump to the newest message while pinned,
        /// flag the unread pill otherwise (post-frame — not during build)
        if (this._pinnedToBottom) {
          this._unreadWhileScrolledUp = false;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this._scrollController.hasClients) {
              this._scrollController.jumpTo(
                  this._scrollController.position.maxScrollExtent);
            }
          });
        } else if (messageCount != this._lastRenderedCount) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (this.mounted) {
              setState(() => this._unreadWhileScrolledUp = true);
            }
          });
        }
        this._lastRenderedCount = messageCount;

        return Stack(
          children: [
            ListView.builder(
              controller: this._scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              itemCount: messageCount,
              itemBuilder: (context, index) =>
                  TwitchChatMessageRow(event: this._store.messages[index]),
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
        );
      },
    );
  }
}
```

- [ ] **Step 6: Run — verify it passes**

Run: `flutter test test/chat/native_twitch_chat_view_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart test/chat/support/fake_twitch_services.dart test/chat/twitch_chat_store_test.dart test/chat/native_twitch_chat_view_test.dart
git commit -m "feat(twitch): native read-only chat view with inline emotes"
```

---

### Task 8: Integration — slot branching + connect/logout UI

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart`
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart` (branch + extract legacy stack + empty-state button)
- Modify: `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart` (Twitch account action)
- Test: `test/chat/twitch_chat_integration_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–7, plus `ModalHandler.showBaseDialog`, `ConfirmationDialog`, `BaseAdaptiveDialog`/`DialogActionConfig`, `OverlayHandler.showStatusOverlay`, `BaseResult`.
- Produces: `startTwitchLogin(BuildContext)` (shared entry point), `TwitchDeviceCodeDialog()`. This is the user-facing surface of the feature.

- [ ] **Step 1: Write the failing integration test**

Create `test/chat/twitch_chat_integration_test.dart`:

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore store;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_integration');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox(HiveKeys.Settings.name);
    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<DashboardStore>(DashboardStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('slot shows the native view for Twitch when logged in',
      (tester) async {
    settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    store.authState = TwitchAuthState.loggedIn;
    store.chatConnection = TwitchChatConnectionState.live;

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsOneWidget);
  });

  testWidgets('slot keeps the empty state + connect button when logged out',
      (tester) async {
    settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(find.text('Connect Twitch'), findsOneWidget);
  });

  testWidgets('connect button starts the login and the dialog auto-closes',
      (tester) async {
    settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect Twitch'));
    await tester.pump();
    expect(find.byType(TwitchDeviceCodeDialog), findsOneWidget);

    /// Fake auth service resolves instantly → logged in → dialog closes
    await tester.pumpAndSettle();
    expect(store.authState, TwitchAuthState.loggedIn);
    expect(find.byType(TwitchDeviceCodeDialog), findsNothing);
  });

  testWidgets('username bar shows the Twitch account action only for Twitch',
      (tester) async {
    settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.link), findsOneWidget);

    settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.YouTube);
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.link), findsNothing);
  });
}
```

(If `UsernameDropdown` misbehaves with zero usernames in the last test, seed one first: `settingsBox().put(SettingsKeys.TwitchUsernames.name, ['someone']); settingsBox().put(SettingsKeys.SelectedTwitchUsername.name, 'someone');` before pumping.)

- [ ] **Step 2: Run — verify it fails**

Run: `flutter test test/chat/twitch_chat_integration_test.dart`
Expected: FAIL — compilation error, dialog does not exist.

- [ ] **Step 3: Create the device code dialog + shared entry point**

Create `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/overlay_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Start the device-flow login and show its dialog — the single entry
/// point every "Connect Twitch" affordance uses.
void startTwitchLogin(BuildContext context) {
  GetIt.instance<TwitchChatStore>().startLogin();
  ModalHandler.showBaseDialog(
    context: context,
    dialogWidget: const TwitchDeviceCodeDialog(),
  );
}

/// Walks the user through Twitch's device code grant: show the code, open
/// twitch.tv/activate, poll until authorized/expired/denied/cancelled.
class TwitchDeviceCodeDialog extends StatelessWidget {
  const TwitchDeviceCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<TwitchChatStore>();

    return Observer(
      builder: (_) {
        /// Auto-close once the flow finished
        if (store.authState == TwitchAuthState.loggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }

        return BaseAdaptiveDialog(
          title: 'Connect Twitch',
          bodyWidget: switch (store.authState) {
            TwitchAuthState.awaitingAuthorization =>
              _CodeEntryState(store: store),
            TwitchAuthState.loggingIn =>
              const _ProgressState('Finishing up…'),
            TwitchAuthState.error => _ErrorState(store: store),
            _ => const _ProgressState('Contacting Twitch…'),
          },
          actions: [
            if (store.authState == TwitchAuthState.error)
              DialogActionConfig(
                onPressed: (_) => store.startLogin(),
                popOnAction: false,
                child: const Text('Try again'),
              ),
            DialogActionConfig(
              onPressed: (_) => store.cancelLogin(),
              isDefaultAction: true,
              child: Text(
                store.authState == TwitchAuthState.error ? 'Close' : 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The code the user enters at twitch.tv/activate + the button to get there
class _CodeEntryState extends StatelessWidget {
  final TwitchChatStore store;

  const _CodeEntryState({required this.store});

  @override
  Widget build(BuildContext context) {
    final code = this.store.pendingUserCode ?? '…';
    final uri = Uri.parse(this.store.pendingVerificationUri ??
        'https://www.twitch.tv/activate');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Open Twitch and enter this code:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Pressable(
          haptic: true,
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            OverlayHandler.showStatusOverlay(
              context: context,
              content: const BaseResult(
                icon: BaseResultIcon.Positive,
                text: 'Code copied',
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SelectableText(
              code,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(letterSpacing: 2.0),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tap the code to copy it',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Pressable(
          haptic: true,
          onTap: () async {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'Open Twitch',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _ProgressState('Waiting for authorization…'),
      ],
    );
  }
}

class _ProgressState extends StatelessWidget {
  final String text;

  const _ProgressState(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StylingHelper.isApple(context)
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.md),
        Text(this.text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final TwitchChatStore store;

  const _ErrorState({required this.store});

  @override
  Widget build(BuildContext context) {
    return Text(
      this.store.authError ?? 'Something went wrong',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
```

- [ ] **Step 4: Branch the chat slot in `stream_chat.dart`**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`, add imports:

```dart
import 'package:flutter_mobx/flutter_mobx.dart';
```
```dart
import '../../../../../stores/views/twitch_chat.dart';
```
```dart
import 'native_twitch_chat_view.dart';
```
```dart
import 'twitch_device_code_dialog.dart';
```

In `_StreamChatState.build`, inside the `HiveBuilder` builder, directly after the `if (chatActive) { _syncWebController(...); }` block and before the existing `return Stack(`, insert:

```dart
              /// Native Twitch chat takes over the slot once logged in;
              /// logged-out Twitch / YouTube / Owncast keep the WebView path
              if (chatType == ChatType.Twitch) {
                return Observer(
                  builder: (_) {
                    if (GetIt.instance<TwitchChatStore>().isLoggedIn) {
                      return const NativeTwitchChatView();
                    }
                    return this._buildLegacyChatStack(
                      context,
                      settingsBox,
                      chatType,
                      chatActive,
                      dashboardStore,
                    );
                  },
                );
              }
```

Then extract the existing `return Stack(...);` block (currently ending the builder, unchanged in behavior) into a new private method on `_StreamChatState` and let the builder fall through to it:

```dart
  /// The pre-native chat slot: WebView embed + loading/empty states.
  /// Verbatim the behavior before native Twitch chat existed.
  Widget _buildLegacyChatStack(
    BuildContext context,
    Box<dynamic> settingsBox,
    ChatType chatType,
    bool chatActive,
    DashboardStore dashboardStore,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Only add the [WebView] to the widget tree if we have an
        /// actual chat to display because otherwise the [WebView]
        /// will still eat up performance
        if (chatActive && _webController != null) ...[
          /// To enable scrolling in the Twitch chat, we need to disabe scrolling for
          /// the main Scroll (the [CustomScrollView] of this view) while trying to scroll
          /// in the region where the Twitch chat is. The Listener is used to determine
          /// where the user is trying to scroll and if it's where the Twitch chat is,
          /// we change to [NeverScrollableScrollPhysics] so the WebView can consume
          /// the scroll
          Listener(
            onPointerDown: (onPointerDown) =>
                dashboardStore.setPointerOnChat(
                    onPointerDown.localPosition.dy > 150.0 &&
                        onPointerDown.localPosition.dy < 450.0),
            onPointerUp: (_) =>
                dashboardStore.setPointerOnChat(false),
            onPointerCancel: (_) =>
                dashboardStore.setPointerOnChat(false),
            child: WebViewWidget(
              key: Key(
                chatType.toString() +
                    settingsBox
                        .get(SettingsKeys.SelectedTwitchUsername.name)
                        .toString() +
                    settingsBox
                        .get(
                            SettingsKeys.SelectedYouTubeUsername.name)
                        .toString() +
                    settingsBox
                        .get(
                            SettingsKeys.SelectedOwncastUsername.name)
                        .toString(),
              ),
              controller: _webController!,
            ),
          ),

          /// Crossfading branded surface hiding the flash of the
          /// keyed [WebView] reload until the page has loaded -
          /// purely visual, touches always fall through to the
          /// [WebView] (and its pointer band) as before
          AnimatedOpacity(
            opacity: _isChatLoading ? 1.0 : 0.0,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            child: _ChatLoadingState(chatType: chatType),
          ),
        ],
        if (!chatActive)
          StaggeredEntrance(
            child: _ChatEmptyState(chatType: chatType),
          ),
      ],
    );
  }
```

The builder's tail becomes:

```dart
              return this._buildLegacyChatStack(
                  context, settingsBox, chatType, chatActive, dashboardStore);
```

- [ ] **Step 5: Add the empty-state "Connect Twitch" button**

In the same file's `_ChatEmptyState.build`, after the explanation `Text(...)` (the `'No ${this.chatType.text} username selected…'` one), append:

```dart
            if (this.chatType == ChatType.Twitch) ...[
              const SizedBox(height: AppSpacing.lg),
              Observer(
                builder: (_) => GetIt.instance<TwitchChatStore>().isLoggedIn
                    ? const SizedBox.shrink()
                    : Pressable(
                        haptic: true,
                        onTap: () => startTwitchLogin(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: brandColor,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            'Connect Twitch',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ],
```

- [ ] **Step 6: Add the Twitch account action to `username_action_row.dart`**

In `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart`, add imports (package-style is fine):

```dart
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import '../twitch_device_code_dialog.dart';
```

In the action `Row`'s `children:`, insert as the **first** children (before the Add `_UsernameAction`):

```dart
          if (chatType == ChatType.Twitch) ...[
            Observer(
              builder: (_) {
                final loggedIn = GetIt.instance<TwitchChatStore>().isLoggedIn;
                return _UsernameAction(
                  icon: loggedIn
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.link,
                  tooltip: loggedIn ? 'Twitch connected' : 'Connect Twitch',
                  onPressed: () {
                    if (loggedIn) {
                      ModalHandler.showBaseDialog(
                        context: context,
                        dialogWidget: ConfirmationDialog(
                          title: 'Disconnect Twitch?',
                          body:
                              'You will be logged out of your Twitch account. The classic WebView chat will be used instead.',
                          okText: 'Disconnect',
                          isYesDestructive: true,
                          onOk: (_) =>
                              GetIt.instance<TwitchChatStore>().logout(),
                        ),
                      );
                    } else {
                      startTwitchLogin(context);
                    }
                  },
                );
              },
            ),
            const SizedBox(
              height: 20.0,
              child: VerticalDivider(width: 1.0, thickness: 0.0),
            ),
          ],
```

- [ ] **Step 7: Run — verify it passes**

Run: `flutter test test/chat/`
Expected: PASS (all chat tests, including the 4 new integration tests).

- [ ] **Step 8: Analyze**

Run: `flutter analyze`
Expected: no new errors/warnings.

- [ ] **Step 9: Commit**

```bash
git add lib/views/dashboard/widgets/obs_widgets/stream_chat/ test/chat/twitch_chat_integration_test.dart
git commit -m "feat(twitch): connect/logout UI + native chat slot integration"
```

---

### Task 9: Verification + docs

**Files:**
- Modify: `docs/chat-webview-audit.md` (roadmap status)
- Modify: `docs/session-handoff.md` (current state)
- Modify: `docs/changelog-agent.md` (entry)

**Interfaces:** none (docs/verification only).

- [ ] **Step 1: Full unit suite**

Run: `flutter test test/chat/ test/websocket/ test/persistence/`
Expected: PASS (all).

- [ ] **Step 2: Full analyze**

Run: `flutter analyze`
Expected: 0 errors; only the 6 pre-existing warnings (`input.dart`, `translucent_sliver_app_bar.dart`, `statistics.dart`).

- [ ] **Step 3: Codegen is clean**

Run: `dart run build_runner build --delete-conflicting-outputs && git status --porcelain`
Expected: `Succeeded`; no modified files (generated code already committed).

- [ ] **Step 4: Manual dogfood (workstation, real Twitch account — maintainer)**

Not automatable — checklist for the user:

1. `flutter devices` → `flutter run -d <sim-id>`.
2. Dashboard → chat widget → Twitch → no username needed: tap **Connect Twitch** (empty-state button or link icon in the username bar) → dialog shows a code → **Open Twitch** → authorize on twitch.tv/activate → dialog closes → chat connects.
3. Post messages from a second account/device: they appear; emotes render inline; author colors show.
4. Scroll up during activity → "New messages ↓" pill appears → tap jumps to bottom.
5. Log out via the username-bar account icon → confirm dialog → WebView fallback appears (with a saved username) or the empty state (without).
6. Background/foreground the app → chat recovers (reconnect).
7. Settings → Force Tablet Mode smoke: chat slot renders correctly side-by-side.
8. Optional: `tool/visual_qa/capture_screenshots.sh` for a visual record.

- [ ] **Step 5: Docs + commit**

In `docs/chat-webview-audit.md`, roadmap row: `| 1 | Native chat UI shell + Twitch OAuth | **Done** (read-only native chat, DCF + EventSub) |`.

In `docs/session-handoff.md` "Right now": replace the "Chat Phase 1 unblocked, in design" note with: native Twitch chat Phase 1 implemented (DCF login + read-only EventSub chat in the existing slot); Phase 2 = send/emotes/badges.

Add a `docs/changelog-agent.md` entry summarizing the feature (files, decisions, Client ID reference, DCF choice).

```bash
git add docs/chat-webview-audit.md docs/session-handoff.md docs/changelog-agent.md
git commit -m "docs: native Twitch chat Phase 1 (read-only) implemented"
```

---

## Self-Review Notes (resolved during plan authoring)

- **Spec deviation accepted:** the spec assumed `http` was already a dependency; it is not. Task 1 adds it as the single new dependency; everything else uses existing packages. Tests use `package:http/testing.dart`'s `MockClient` + hand-written fakes — no mocking library added.
- **Spec deviation accepted:** the spec mentioned `BaseProgressIndicator` reuse; its constructor wasn't verified, so the dialog/view build small local progress states from `CupertinoActivityIndicator`/`CircularProgressIndicator` (same pattern as `_ChatLoadingState`).
- **Verification points from the spec** (recreate-app console values, WS behavior on iOS backgrounding, emote CDN shape) are covered by Task 9's manual dogfood.

import 'dart:async';

import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_emote.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/types/classes/kick/kick_token.dart';
import 'package:obs_blade/utils/kick/kick_api_service.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_emote_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

class FakeKickChannelService extends KickChannelService {
  /// slug → channel info; a missing key resolves to null (channel not
  /// found).
  final Map<String, KickChannelInfo?> channels = <String, KickChannelInfo>{};
  int resolveCalls = 0;
  Object? resolveThrows;

  /// chatroom channel id → scripted history; a missing key resolves to
  /// an empty backfill.
  final Map<int, List<KickChatMessage>> backfills =
      <int, List<KickChatMessage>>{};
  int backfillCalls = 0;
  Object? backfillThrows;

  @override
  Future<KickChannelInfo?> resolveChannel(String slug) async {
    this.resolveCalls++;
    if (this.resolveThrows != null) throw this.resolveThrows!;
    return this.channels[slug];
  }

  /// Optional pin returned with [backfills] for [channelId].
  final Map<int, KickChatMessage?> pinnedBackfills = <int, KickChatMessage?>{};

  @override
  Future<KickChatBackfill> backfillMessages(int channelId) async {
    this.backfillCalls++;
    if (this.backfillThrows != null) throw this.backfillThrows!;
    final messages = List<KickChatMessage>.of(
      this.backfills[channelId] ?? const [],
    );

    /// Same arrival-order contract as the real service.
    messages.sort(
      (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return KickChatBackfill(
      messages: messages,
      pinnedMessage: this.pinnedBackfills[channelId],
    );
  }
}

class FakeKickPusherService extends KickPusherService {
  FakeKickPusherService({
    required super.onEvent,
    required super.onStateChanged,
  });

  /// Chatroom ids of every [connect] call.
  final List<int> connectCalls = <int>[];
  int disconnectCalls = 0;

  /// Whether [connect] reports the socket as connected immediately
  /// (tests drive state transitions via [emitState] when false).
  bool autoConnect = true;

  @override
  Future<void> connect({required int chatroomId}) async {
    this.connectCalls.add(chatroomId);
    if (this.autoConnect) {
      this.onStateChanged(KickPusherConnectionState.connected);
    }
  }

  @override
  Future<void> disconnect() async {
    this.disconnectCalls++;

    /// Intentionally no `disconnected` emission: the store's own flow
    /// guard owns the state on teardown (mirrors the real service's
    /// superseded-callback path).
  }

  void emitEvent(KickPusherEvent event) => this.onEvent(event);

  void emitState(KickPusherConnectionState state) => this.onStateChanged(state);
}

/// Scripted [KickAuthService] — deterministic PKCE session, no HTTP.
/// [parseRedirectCode] is deliberately NOT overridden: it is pure
/// local logic the store tests exercise for real (state mismatch path).
class FakeKickAuthService extends KickAuthService {
  /// The fixed PKCE session every [beginSession] returns.
  static const KickPkceSession kSession = KickPkceSession(
    verifier: 'test-verifier',
    state: 'test-state',
    codeChallenge: 'test-challenge',
  );

  int beginSessionCalls = 0;

  Object? exchangeThrows;
  KickToken? exchangeToken;
  String? lastExchangeCode;
  String? lastExchangeVerifier;

  Object? refreshThrows;
  KickToken? refreshedToken;
  int refreshCalls = 0;
  String? lastRefreshToken;

  Object? fetchUserThrows;
  KickUserIdentity? identity = const KickUserIdentity(
    userId: 9001,
    name: 'kicker',
    profilePicture: 'https://pic.example/k.png',
  );
  int fetchUserCalls = 0;

  final List<String> revokedTokens = <String>[];

  @override
  Future<void> registerProxyLogin(KickPkceSession session) async {}

  @override
  Future<KickToken?> pollProxyLogin(KickPkceSession session) async => null;

  @override
  KickPkceSession beginSession() {
    this.beginSessionCalls++;
    return kSession;
  }

  @override
  Uri authorizeUrl(KickPkceSession session) => Uri.parse(
    'https://id.kick.com/oauth/authorize?state=${session.state}'
    '&code_challenge=${session.codeChallenge}'
    '&redirect_uri=$kKickOAuthRedirectUri',
  );

  @override
  Future<KickToken> exchangeCode({
    required String code,
    required KickPkceSession session,
  }) async {
    this.lastExchangeCode = code;
    this.lastExchangeVerifier = session.verifier;
    if (this.exchangeThrows != null) throw this.exchangeThrows!;
    return this.exchangeToken ??
        const KickToken(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresIn: 3600,
          scope: kKickChatScopes,
        );
  }

  @override
  Future<KickToken> refreshToken(String refreshToken) async {
    this.refreshCalls++;
    this.lastRefreshToken = refreshToken;
    if (this.refreshThrows != null) throw this.refreshThrows!;
    return this.refreshedToken ??
        const KickToken(
          accessToken: 'access-new',
          refreshToken: 'refresh-new',
          expiresIn: 3600,
          scope: kKickChatScopes,
        );
  }

  @override
  Future<KickUserIdentity?> fetchOwnUser(String accessToken) async {
    this.fetchUserCalls++;
    if (this.fetchUserThrows != null) throw this.fetchUserThrows!;
    return this.identity;
  }

  @override
  Future<void> revoke(String token, {String tokenHint = 'access_token'}) async {
    this.revokedTokens.add(token);
  }
}

class KickSendCall {
  final int broadcasterUserId;
  final String content;
  final String? replyToMessageId;

  const KickSendCall({
    required this.broadcasterUserId,
    required this.content,
    this.replyToMessageId,
  });
}

class KickBanCall {
  final int broadcasterUserId;
  final int userId;
  final int? durationMinutes;
  final String? reason;

  const KickBanCall({
    required this.broadcasterUserId,
    required this.userId,
    this.durationMinutes,
    this.reason,
  });
}

/// Scripted [KickApiService] — records calls, returns scripted results,
/// no HTTP (the token provider is a stub).
class FakeKickApiService extends KickApiService {
  FakeKickApiService()
    : super(tokenProvider: ({required forceRefresh}) async => 'test-token');

  final List<KickSendCall> sendCalls = <KickSendCall>[];
  String sendMessageId = 'sent-1';
  Object? sendThrows;

  final List<String> deleteCalls = <String>[];
  Object? deleteThrows;

  final List<KickBanCall> banCalls = <KickBanCall>[];
  Object? banThrows;

  final List<KickBanCall> unbanCalls = <KickBanCall>[];
  Object? unbanThrows;

  final List<int> fetchUserCalls = <int>[];
  KickUserIdentity? fetchUserResult;
  Object? fetchUserThrows;

  @override
  Future<String> sendMessage({
    required int broadcasterUserId,
    required String content,
    String? replyToMessageId,
  }) async {
    this.sendCalls.add(
      KickSendCall(
        broadcasterUserId: broadcasterUserId,
        content: content,
        replyToMessageId: replyToMessageId,
      ),
    );
    if (this.sendThrows != null) throw this.sendThrows!;
    return this.sendMessageId;
  }

  @override
  Future<void> deleteMessage({required String messageId}) async {
    this.deleteCalls.add(messageId);
    if (this.deleteThrows != null) throw this.deleteThrows!;
  }

  @override
  Future<void> banUser({
    required int broadcasterUserId,
    required int userId,
    int? durationMinutes,
    String? reason,
  }) async {
    this.banCalls.add(
      KickBanCall(
        broadcasterUserId: broadcasterUserId,
        userId: userId,
        durationMinutes: durationMinutes,
        reason: reason,
      ),
    );
    if (this.banThrows != null) throw this.banThrows!;
  }

  @override
  Future<void> unbanUser({
    required int broadcasterUserId,
    required int userId,
  }) async {
    this.unbanCalls.add(
      KickBanCall(broadcasterUserId: broadcasterUserId, userId: userId),
    );
    if (this.unbanThrows != null) throw this.unbanThrows!;
  }

  @override
  Future<KickUserIdentity?> fetchUser(int userId) async {
    this.fetchUserCalls.add(userId);
    if (this.fetchUserThrows != null) throw this.fetchUserThrows!;
    return this.fetchUserResult;
  }
}

class FakeKickEmoteService extends KickEmoteService {
  /// slug → scripted sections; a missing key resolves to an empty list.
  final Map<String, List<KickEmoteSection>> sections =
      <String, List<KickEmoteSection>>{};
  final List<String> fetchCalls = <String>[];
  Object? fetchThrows;

  /// Parks [fetchChannelEmotes] instead of returning immediately — lets a
  /// test resolve the fetch at a chosen moment (stale-fetch tests).
  Completer<List<KickEmoteSection>>? fetchGate;

  @override
  Future<List<KickEmoteSection>> fetchChannelEmotes(String slug) async {
    this.fetchCalls.add(slug);
    if (this.fetchThrows != null) throw this.fetchThrows!;
    if (this.fetchGate != null) return this.fetchGate!.future;
    return this.sections[slug] ?? const [];
  }
}

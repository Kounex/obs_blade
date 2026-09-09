import 'dart:async';
import 'dart:collection';

import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_device_code.dart';
import 'package:obs_blade/types/classes/youtube/youtube_token.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';

class FakeYouTubeAuthService extends YouTubeAuthService {
  String clientId = 'client-id';
  YouTubeAuthException? failPollWith;
  YouTubeAuthException? failRefreshWith;
  Object? failChannelTitleWith;
  String? channelTitleResult = 'My Channel';
  String? revokedToken;

  /// Scopes the returned [YouTubeToken] carries (default: the YouTube
  /// scope the device flow requests).
  List<String> tokenScopes = kYouTubeChatScopes;

  static YouTubeToken token({List<String>? scope}) => YouTubeToken(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresIn: 3600,
    scope: scope ?? kYouTubeChatScopes,
  );

  @override
  String resolveClientId() => this.clientId;

  @override
  Future<YouTubeDeviceCode> requestDeviceCode() async =>
      const YouTubeDeviceCode(
        deviceCode: 'dev',
        userCode: 'ABCD-EFGH',
        verificationUrl: 'https://www.google.com/device',
        expiresIn: 1800,
        interval: 0,
      );

  @override
  Future<YouTubeToken> pollForToken(
    YouTubeDeviceCode deviceCode, {
    required FutureOr<void> Function() onPending,
    required bool Function() isCancelled,
  }) async {
    if (isCancelled()) throw const YouTubeAuthException('Login cancelled');
    if (this.failPollWith != null) throw this.failPollWith!;
    return FakeYouTubeAuthService.token(scope: this.tokenScopes);
  }

  @override
  Future<String?> fetchOwnChannelTitle(String accessToken) async {
    if (this.failChannelTitleWith != null) throw this.failChannelTitleWith!;
    return this.channelTitleResult;
  }

  @override
  Future<YouTubeToken> refreshToken(String refreshToken) async {
    if (this.failRefreshWith != null) throw this.failRefreshWith!;
    return FakeYouTubeAuthService.token(scope: this.tokenScopes);
  }

  @override
  Future<void> revoke(String accessToken) async {
    this.revokedToken = accessToken;
  }
}

class FakeYouTubeLiveChatService extends YouTubeLiveChatService {
  /// videoId → activeLiveChatId; a missing key resolves to null (not
  /// live / no active chat).
  final Map<String, String?> liveChatIds = <String, String>{};
  int resolveCalls = 0;
  Object? resolveThrows;

  /// Scripted poll responses — each entry is a [YouTubeLiveChatPage] or
  /// an [Exception] to throw. When empty, [listMessages] parks on a
  /// completer (the poll loop then idles until the test tears down or
  /// [pushPollResponse] delivers the next response).
  final Queue<Object> pollResponses = Queue<Object>();
  int listCalls = 0;

  Completer<YouTubeLiveChatPage>? _parked;

  /// Whether the poll loop is currently parked inside [listMessages].
  bool get isParked => this._parked != null;

  /// Deliver a poll response — completes the parked [listMessages] call
  /// when the loop is waiting, queues it otherwise.
  void pushPollResponse(Object response) {
    final parked = this._parked;
    if (parked == null) {
      this.pollResponses.add(response);
      return;
    }
    this._parked = null;
    if (response is Exception) {
      parked.completeError(response);
    } else {
      parked.complete(response as YouTubeLiveChatPage);
    }
  }

  /// Page tokens per [listMessages] call — asserts token threading.
  final List<String?> listPageTokens = <String?>[];

  int insertCalls = 0;
  String? lastInsertMessage;
  Object? insertThrows;
  YouTubeChatMessage Function(String message)? insertResult;

  final List<String> deletedMessageIds = <String>[];
  Object? deleteThrows;

  final List<({String channelId, int? durationSeconds})> banCalls =
      <({String channelId, int? durationSeconds})>[];
  Object? banThrows;

  final List<String> unbanCalls = <String>[];
  Object? unbanThrows;

  @override
  Future<String?> getActiveLiveChatId(
    String videoId, {
    String? apiKey,
    String? accessToken,
  }) async {
    this.resolveCalls++;
    if (this.resolveThrows != null) throw this.resolveThrows!;
    return this.liveChatIds[videoId];
  }

  @override
  Future<YouTubeLiveChatPage> listMessages(
    String liveChatId,
    String? pageToken, {
    String? apiKey,
    String? accessToken,
  }) async {
    this.listCalls++;
    this.listPageTokens.add(pageToken);
    if (this.pollResponses.isEmpty) {
      // Idle — the store cancels the loop via its generation guard.
      final parked = Completer<YouTubeLiveChatPage>();
      this._parked = parked;
      return parked.future;
    }
    final next = this.pollResponses.removeFirst();
    if (next is Exception) throw next;
    return next as YouTubeLiveChatPage;
  }

  @override
  Future<YouTubeChatMessage> insert({
    required String accessToken,
    required String liveChatId,
    required String message,
  }) async {
    this.insertCalls++;
    this.lastInsertMessage = message;
    if (this.insertThrows != null) throw this.insertThrows!;
    if (this.insertResult != null) return this.insertResult!(message);
    return YouTubeChatMessage(
      id: 'sent-${this.insertCalls}',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'self',
        displayMessage: message,
        textMessageDetails: YouTubeTextMessageDetails(messageText: message),
      ),
    );
  }

  @override
  Future<void> delete({
    required String accessToken,
    required String messageId,
  }) async {
    this.deletedMessageIds.add(messageId);
    if (this.deleteThrows != null) throw this.deleteThrows!;
  }

  @override
  Future<void> ban({
    required String accessToken,
    required String liveChatId,
    required String channelId,
    int? durationSeconds,
  }) async {
    this.banCalls.add((channelId: channelId, durationSeconds: durationSeconds));
    if (this.banThrows != null) throw this.banThrows!;
  }

  @override
  Future<void> unban({
    required String accessToken,
    required String banId,
  }) async {
    this.unbanCalls.add(banId);
    if (this.unbanThrows != null) throw this.unbanThrows!;
  }
}

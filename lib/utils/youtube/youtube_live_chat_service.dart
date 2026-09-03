import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';

const String _kApiBase = 'https://www.googleapis.com/youtube/v3';

/// One page of a `liveChatMessages.list` response.
class YouTubeLiveChatPage {
  final List<YouTubeChatMessage> messages;
  final String? nextPageToken;

  /// Server-mandated delay before the next poll — polling faster triggers
  /// `rateLimitExceeded`.
  final int pollingIntervalMillis;

  /// Set when the broadcast went offline (stream-end signal).
  final DateTime? offlineAt;

  /// The currently active poll (full liveChatMessage resource), if any.
  final YouTubeChatMessage? activePollItem;

  const YouTubeLiveChatPage({
    required this.messages,
    required this.pollingIntervalMillis,
    this.nextPageToken,
    this.offlineAt,
    this.activePollItem,
  });
}

/// Failure of a YouTube Data API call the UI can surface via [message].
class YouTubeApiException implements Exception {
  final String message;
  final Object? cause;
  final int? statusCode;

  const YouTubeApiException(this.message, {this.cause, this.statusCode});

  @override
  String toString() =>
      'YouTubeApiException: $message${this.cause != null ? ' (${this.cause})' : ''}';
}

/// Project quota is exhausted (`quotaExceeded` / `rateLimitExceeded` /
/// `dailyLimitExceeded`) — polling must stop until the midnight-PT reset.
class YouTubeQuotaExceededException extends YouTubeApiException {
  const YouTubeQuotaExceededException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// 401/403 that isn't quota — missing credentials, insufficient
/// permission (e.g. a mod action without being a mod), or a dead token.
class YouTubeForbiddenException extends YouTubeApiException {
  const YouTubeForbiddenException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// The live chat has ended (`liveChatEnded`) — stop polling, no retry.
class YouTubeChatEndedException extends YouTubeApiException {
  const YouTubeChatEndedException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// Hand-rolled YouTube Data API live-chat REST service — same idiom as
/// `lib/utils/twitch/` ([client] is injectable, no real HTTP in tests).
///
/// Reads accept either an API key (`key` query param) or an OAuth bearer
/// token; writes (insert/delete/ban) require the bearer token.
class YouTubeLiveChatService {
  final http.Client _client;

  YouTubeLiveChatService({http.Client? client})
    : _client = client ?? http.Client();

  /// API key resolution: the user's own key ([SettingsKeys.YouTubeApiKey])
  /// wins over the app-owned [kYouTubeApiKey] constant.
  static String resolveApiKey() {
    if (Hive.isBoxOpen(HiveKeys.Settings.name)) {
      final value = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.YouTubeApiKey.name);
      if (value is String && value.isNotEmpty) return value;
    }
    return kYouTubeApiKey;
  }

  Uri _uri(String path, Map<String, String> query, {String? apiKey}) =>
      Uri.parse('$_kApiBase/$path').replace(
        queryParameters: {
          ...query,
          if (apiKey != null && apiKey.isNotEmpty) 'key': apiKey,
        },
      );

  Map<String, String> _headers({String? accessToken, bool jsonBody = false}) =>
      {
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
        if (jsonBody) 'Content-Type': 'application/json',
      };

  /// `liveChatMessages.list` — one poll page. [pageToken] resumes where
  /// the last poll left off; honor [YouTubeLiveChatPage.pollingIntervalMillis]
  /// before calling again.
  Future<YouTubeLiveChatPage> listMessages(
    String liveChatId,
    String? pageToken, {
    String? apiKey,
    String? accessToken,
  }) async {
    final response = await this._client.get(
      this._uri('liveChat/messages', {
        'liveChatId': liveChatId,
        'part': 'id,snippet,authorDetails',
        'pageToken': ?pageToken,
      }, apiKey: apiKey),
      headers: this._headers(accessToken: accessToken),
    );
    if (response.statusCode != 200) {
      throw YouTubeLiveChatService._errorFor(response, 'Listing chat');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    return YouTubeLiveChatPage(
      messages: ((body['items'] as List?) ?? const [])
          .map(
            (item) => YouTubeChatMessage.fromJson(item as Map<String, Object?>),
          )
          .toList(),
      nextPageToken: body['nextPageToken'] as String?,
      pollingIntervalMillis:
          (body['pollingIntervalMillis'] as num?)?.toInt() ?? 5000,
      offlineAt: body['offlineAt'] != null
          ? DateTime.parse(body['offlineAt'] as String)
          : null,
      activePollItem: body['activePollItem'] != null
          ? YouTubeChatMessage.fromJson(
              body['activePollItem'] as Map<String, Object?>,
            )
          : null,
    );
  }

  /// `liveChatMessages.insert` — sends a text message as the
  /// authenticated user (requires the `youtube` scope).
  Future<YouTubeChatMessage> insert({
    required String accessToken,
    required String liveChatId,
    required String message,
  }) async {
    final response = await this._client.post(
      this._uri('liveChat/messages', {'part': 'snippet'}),
      headers: this._headers(accessToken: accessToken, jsonBody: true),
      body: json.encode({
        'snippet': {
          'liveChatId': liveChatId,
          'type': 'textMessageEvent',
          'textMessageDetails': {'messageText': message},
        },
      }),
    );
    if (response.statusCode != 200) {
      throw YouTubeLiveChatService._errorFor(response, 'Sending chat message');
    }
    return YouTubeChatMessage.fromJson(
      json.decode(response.body) as Map<String, Object?>,
    );
  }

  /// `liveChatMessages.delete` — 204 on success. Only the channel owner
  /// or a moderator can delete (403 surfaces as [YouTubeForbiddenException]).
  Future<void> delete({
    required String accessToken,
    required String messageId,
  }) async {
    final response = await this._client.delete(
      this._uri('liveChat/messages', {'id': messageId}),
      headers: this._headers(accessToken: accessToken),
    );
    if (response.statusCode != 204) {
      throw YouTubeLiveChatService._errorFor(response, 'Deleting chat message');
    }
  }

  /// `liveChatBans.insert` — permanent when [durationSeconds] is null,
  /// temporary (timeout) otherwise.
  Future<void> ban({
    required String accessToken,
    required String liveChatId,
    required String channelId,
    int? durationSeconds,
  }) async {
    final response = await this._client.post(
      this._uri('liveChat/bans', {'part': 'snippet'}),
      headers: this._headers(accessToken: accessToken, jsonBody: true),
      body: json.encode({
        'snippet': {
          'liveChatId': liveChatId,
          'type': durationSeconds != null ? 'temporary' : 'permanent',
          'banDurationSeconds': ?durationSeconds,
          'bannedUserDetails': {'channelId': channelId},
        },
      }),
    );
    if (response.statusCode != 200) {
      throw YouTubeLiveChatService._errorFor(response, 'Banning user');
    }
  }

  /// `liveChatBans.delete` — [banId] is the id of the ban resource
  /// (not the channel id).
  Future<void> unban({
    required String accessToken,
    required String banId,
  }) async {
    final response = await this._client.delete(
      this._uri('liveChat/bans', {'id': banId}),
      headers: this._headers(accessToken: accessToken),
    );
    if (response.statusCode != 204) {
      throw YouTubeLiveChatService._errorFor(response, 'Unbanning user');
    }
  }

  /// `videos.list?part=liveStreamingDetails` — resolves a video id to its
  /// `activeLiveChatId` (1 quota unit). Null = not live / no active chat.
  Future<String?> getActiveLiveChatId(
    String videoId, {
    String? apiKey,
    String? accessToken,
  }) async {
    final response = await this._client.get(
      this._uri('videos', {
        'part': 'liveStreamingDetails',
        'id': videoId,
      }, apiKey: apiKey),
      headers: this._headers(accessToken: accessToken),
    );
    if (response.statusCode != 200) {
      throw YouTubeLiveChatService._errorFor(response, 'Resolving live chat');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final items = body['items'];
    if (items is! List || items.isEmpty) return null;
    final details =
        (items.first as Map<String, dynamic>)['liveStreamingDetails'];
    if (details is! Map<String, dynamic>) return null;
    return details['activeLiveChatId'] as String?;
  }

  /// Maps a failing response to a typed error. YouTube error bodies look
  /// like `{error: {code, message, errors: [{reason, ...}]}}`.
  static YouTubeApiException _errorFor(http.Response response, String action) {
    String? reason;
    String? apiMessage;
    try {
      final error =
          (json.decode(response.body) as Map<String, dynamic>)['error'];
      if (error is Map<String, dynamic>) {
        apiMessage = error['message'] as String?;
        final errors = error['errors'];
        if (errors is List && errors.isNotEmpty) {
          reason = (errors.first as Map<String, dynamic>)['reason'] as String?;
        }
      }
    } catch (_) {
      // non-JSON body
    }

    final message =
        '$action failed (${response.statusCode}${apiMessage != null ? ': $apiMessage' : ''})';

    if (reason == 'liveChatEnded') {
      return YouTubeChatEndedException(
        message,
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    if (reason == 'quotaExceeded' ||
        reason == 'dailyLimitExceeded' ||
        reason == 'rateLimitExceeded' ||
        reason == 'userRateLimitExceeded') {
      return YouTubeQuotaExceededException(
        message,
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      return YouTubeForbiddenException(
        message,
        cause: response.body,
        statusCode: response.statusCode,
      );
    }
    return YouTubeApiException(
      message,
      cause: response.body,
      statusCode: response.statusCode,
    );
  }
}

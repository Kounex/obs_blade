import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the YouTube Data API responds with a non-200 status.
class YouTubeApiException implements Exception {
  YouTubeApiException(this.endpoint, this.statusCode, this.body);

  final String endpoint;
  final int statusCode;
  final String body;

  bool get isQuotaExceeded =>
      statusCode == 403 && body.contains('quotaExceeded');

  @override
  String toString() =>
      'YouTubeApiException($endpoint, HTTP $statusCode): $body';
}

/// Resolves `liveStreamingDetails.activeLiveChatId` for [videoId] via
/// `videos.list`. Costs 1 quota unit — callers should log that.
///
/// Throws [YouTubeApiException] on HTTP errors and [StateError] when the
/// video has no active live chat (not live, or chat disabled).
Future<String> resolveLiveChatId(
  http.Client client,
  String apiKey,
  String videoId,
) async {
  final uri = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
    'part': 'liveStreamingDetails',
    'id': videoId,
    'key': apiKey,
  });
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw YouTubeApiException(
        'videos.list', response.statusCode, response.body);
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final items = json['items'] as List<dynamic>? ?? const [];
  final chatId = items.isEmpty
      ? null
      : ((items.first as Map<String, dynamic>)['liveStreamingDetails']
          as Map<String, dynamic>?)?['activeLiveChatId'] as String?;
  if (chatId == null) {
    throw StateError(
        'video $videoId has no activeLiveChatId (not live or chat disabled)');
  }
  return chatId;
}

/// One page of `liveChatMessages.list`.
class ChatPage {
  ChatPage({
    required this.nextPageToken,
    required this.pollingIntervalMillis,
    required this.offlineAt,
    required this.messageCount,
    required this.chatEnded,
  });

  final String? nextPageToken;
  final int pollingIntervalMillis;
  final String? offlineAt;
  final int messageCount;

  /// True when an item with `snippet.type == 'chatEndedEvent'` is present.
  final bool chatEnded;
}

/// Fetches one page of `liveChatMessages.list` (~5 quota units per call,
/// community-verified). Pass [pageToken] to resume where the previous page
/// left off.
Future<ChatPage> fetchChatPage(
  http.Client client,
  String apiKey,
  String liveChatId, {
  String? pageToken,
}) async {
  final params = <String, String>{
    'liveChatId': liveChatId,
    'part': 'id,snippet,authorDetails',
    'key': apiKey,
  };
  if (pageToken != null) params['pageToken'] = pageToken;
  final uri =
      Uri.https('www.googleapis.com', '/youtube/v3/liveChat/messages', params);
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw YouTubeApiException(
        'liveChatMessages.list', response.statusCode, response.body);
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final items = json['items'] as List<dynamic>? ?? const [];
  final chatEnded = items.any((item) =>
      ((item as Map<String, dynamic>)['snippet']
          as Map<String, dynamic>?)?['type'] ==
      'chatEndedEvent');
  return ChatPage(
    nextPageToken: json['nextPageToken'] as String?,
    pollingIntervalMillis: (json['pollingIntervalMillis'] as num?)?.toInt() ?? 5000,
    offlineAt: json['offlineAt'] as String?,
    messageCount: items.length,
    chatEnded: chatEnded,
  );
}

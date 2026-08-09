/// Tombstone kind + marker copy for dimmed chat rows (Twitch mod view).
enum ChatTombstoneKind { deleted, timedOut, banned }

/// Why a message was tombstoned — drives the ` —Deleted` / ` —Timed out`
/// / ` —Banned` marker.
class ChatTombstoneInfo {
  final ChatTombstoneKind kind;
  final Duration? timeoutDuration;

  const ChatTombstoneInfo.deleted()
      : kind = ChatTombstoneKind.deleted,
        timeoutDuration = null;

  const ChatTombstoneInfo.banned()
      : kind = ChatTombstoneKind.banned,
        timeoutDuration = null;

  const ChatTombstoneInfo.timedOut(Duration this.timeoutDuration)
      : kind = ChatTombstoneKind.timedOut;

  const ChatTombstoneInfo._(this.kind, this.timeoutDuration);
}

/// Compact duration for timeout markers (`30s`, `10m`, `1h`, `1d`).
String formatChatTimeoutDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 60) return '${seconds}s';
  final minutes = duration.inMinutes;
  if (minutes < 60) return '${minutes}m';
  final hours = duration.inHours;
  if (hours < 24) return '${hours}h';
  return '${duration.inDays}d';
}

/// Italic marker appended to a dimmed tombstone body.
String chatTombstoneMarker(ChatTombstoneInfo info) => switch (info.kind) {
      ChatTombstoneKind.deleted => ' —Deleted',
      ChatTombstoneKind.banned => ' —Banned',
      ChatTombstoneKind.timedOut =>
        ' —Timed out (${formatChatTimeoutDuration(info.timeoutDuration ?? Duration.zero)})',
    };

/// Duration implied by a `channel.moderate` timeout `expires_at`.
Duration timeoutDurationFromExpiresAt(
  DateTime expiresAt, {
  DateTime? now,
}) {
  final remaining = expiresAt.difference(now ?? DateTime.now());
  if (remaining.isNegative) return Duration.zero;
  return Duration(seconds: remaining.inSeconds);
}

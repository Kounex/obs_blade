/// Kind of system banner merged into the native chat scroll. One kind so
/// far: the whole chat was cleared by a moderator (`/clear`).
enum ChatSystemNoticeKind { chatCleared }

/// System banner in the native chat scroll — NOT a wire DTO (no JSON).
/// Merged into the message list by arrival sequence: the notice sorts
/// after every message whose seq is <= [afterSeq].
class ChatSystemNotice {
  /// Arrival seq of the last message this notice sorts after.
  final int afterSeq;
  final ChatSystemNoticeKind kind;

  const ChatSystemNotice({required this.afterSeq, required this.kind});
}

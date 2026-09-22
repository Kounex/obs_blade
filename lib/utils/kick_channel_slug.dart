/// Extract a Kick channel slug from a bare slug or common kick.com URLs
/// (channel page, popout chat link).
///
/// Returns `null` when nothing usable can be found. Slugs are lowercased —
/// kick.com URLs are case-insensitive and the slug is the canonical form
/// used by the API (`/api/v2/channels/{slug}`) and the popout chat URL.
String? extractKickChannelSlug(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  const slugPattern = r'^[A-Za-z0-9_-]+$';

  // Bare slug (no dot, so it can't be a host).
  if (!trimmed.contains('.') && !trimmed.contains('/')) {
    return RegExp(slugPattern).hasMatch(trimmed)
        ? trimmed.toLowerCase()
        : null;
  }

  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (host != 'kick.com' && !host.endsWith('.kick.com')) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;

  // kick.com/popout/{channel}/chat — the link Kick's own OBS-dock help
  // article tells users to copy
  final candidate =
      segments.first.toLowerCase() == 'popout' && segments.length > 1
      ? segments[1]
      : segments.first;

  return RegExp(slugPattern).hasMatch(candidate)
      ? candidate.toLowerCase()
      : null;
}

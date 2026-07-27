/// Extract a YouTube video id from a bare id or common watch/live/embed URLs.
///
/// Returns `null` when nothing usable can be found. Stored Hive values may be
/// a bare id (what the UI copy historically asked for) or a full link.
String? extractYouTubeVideoId(String? input) {
  if (input == null) return null;
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // Classic YouTube video ids are 11 chars from [A-Za-z0-9_-].
  final bareId = RegExp(r'^[\w-]{11}$');
  if (bareId.hasMatch(trimmed)) return trimmed;

  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null) return null;

  final fromQuery = uri.queryParameters['v'];
  if (fromQuery != null && fromQuery.isNotEmpty) {
    final id = fromQuery.split(RegExp(r'[^A-Za-z0-9_-]')).first;
    if (id.isNotEmpty) return id;
  }

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  if ((host == 'youtu.be' || host.endsWith('.youtu.be')) &&
      segments.isNotEmpty) {
    final id = segments.first.split(RegExp(r'[^A-Za-z0-9_-]')).first;
    if (id.isNotEmpty) return id;
  }

  const idParents = {'live', 'embed', 'shorts', 'v', 'e'};
  for (var i = 0; i < segments.length - 1; i++) {
    if (idParents.contains(segments[i].toLowerCase())) {
      final id = segments[i + 1].split(RegExp(r'[^A-Za-z0-9_-]')).first;
      if (id.isNotEmpty) return id;
    }
  }

  // Last path segment that looks like a video id (e.g. pasted path fragments).
  for (final segment in segments.reversed) {
    final candidate = segment.split(RegExp(r'[^A-Za-z0-9_-]')).first;
    if (bareId.hasMatch(candidate)) return candidate;
  }

  return null;
}

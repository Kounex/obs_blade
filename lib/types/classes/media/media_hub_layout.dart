/// User layout of the Media hub for one OBS connection: which media inputs
/// are hidden and the manual order. Keyed by input name (the v5 subset in
/// use has no stable input ids) - a renamed input falls back to the default
/// (visible, appended in OBS order), the same limitation hidden scenes have.
///
/// Stored as plain settings JSON in `SettingsKeys.MediaHubLayouts`
/// (connection key → layout) - additive, no Hive type involved.
class MediaHubLayout {
  final Set<String> hidden;
  final List<String> order;

  const MediaHubLayout({this.hidden = const {}, this.order = const []});

  static const MediaHubLayout empty = MediaHubLayout();

  factory MediaHubLayout.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    List<String> strings(Object? list) =>
        list is List ? list.whereType<String>().toList() : const [];
    return MediaHubLayout(
      hidden: strings(raw['hidden']).toSet(),
      order: strings(raw['order']),
    );
  }

  Map<String, Object?> toJson() => {
    'hidden': this.hidden.toList(),
    'order': this.order,
  };

  /// [names] (OBS order) sorted by the manual order - names the layout
  /// doesn't know yet keep their OBS order after the known ones. Hidden
  /// names are included; filter with [isHidden] where needed
  List<String> arrange(Iterable<String> names) {
    final List<String> present = names.toList();
    final Set<String> presentSet = present.toSet();
    final List<String> known = this.order.where(presentSet.contains).toList();
    final Set<String> knownSet = known.toSet();
    return [...known, ...present.where((name) => !knownSet.contains(name))];
  }

  bool isHidden(String name) => this.hidden.contains(name);

  MediaHubLayout withHidden(String name, bool hidden) => MediaHubLayout(
    hidden: hidden ? {...this.hidden, name} : ({...this.hidden}..remove(name)),
    order: this.order,
  );

  MediaHubLayout withOrder(List<String> order) =>
      MediaHubLayout(hidden: this.hidden, order: List.unmodifiable(order));
}

/// Identity of a connection for per-connection UI state: the saved
/// connection name when there is one (unique), the host otherwise - the
/// same rule `HiddenScene.isScene` uses
String mediaHubConnectionKey({String? connectionName, required String host}) =>
    connectionName != null ? 'name:$connectionName' : 'host:$host';

/// Reads one connection's layout out of the raw `MediaHubLayouts` setting -
/// anything malformed reads as the default layout
MediaHubLayout readMediaHubLayout(Object? raw, String connectionKey) =>
    raw is Map
    ? MediaHubLayout.fromJson(raw[connectionKey])
    : MediaHubLayout.empty;

/// The raw `MediaHubLayouts` setting with [connectionKey] replaced by
/// [layout] - other connections' entries are kept verbatim
Map<String, Object?> writeMediaHubLayout(
  Object? raw,
  String connectionKey,
  MediaHubLayout layout,
) => {
  if (raw is Map)
    for (final entry in raw.entries)
      if (entry.key is String) entry.key as String: entry.value,
  connectionKey: layout.toJson(),
};

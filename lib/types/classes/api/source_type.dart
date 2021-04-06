import 'package:flutter/foundation.dart';

import 'source_type_capabilities.dart';

class SourceType {
  /// Non-unique internal source type ID
  String typeID;

  /// Display name of the source type
  String displayName;

  /// Value is one of the following: "input", "filter", "transition" or "other"
  String type;

  /// Default settings of this source type
  dynamic defaultSettings;

  /// Source type capabilities
  SourceTypeCapabilities caps;

  SourceType({
    required this.typeID,
    required this.displayName,
    required this.type,
    required this.defaultSettings,
    required this.caps,
  });

  static SourceType fromJSON(Map<String, dynamic> json) {
    return SourceType(
      typeID: json['typeId'],
      displayName: json['displayName'],
      type: json['type'],
      defaultSettings: json['defaultSettings'],
      caps: SourceTypeCapabilities.fromJSON(json['caps']),
    );
  }
}

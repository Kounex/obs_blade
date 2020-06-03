import 'package:flutter/foundation.dart';

class Source {
  /// Unique source name
  String name;

  /// Non-unique source internal type (a.k.a type id)
  String typeID;

  /// Source type. Value is one of the following: "input", "filter", "transition", "scene" or "unknown"
  String type;

  Source({
    @required this.name,
    @required this.typeID,
    @required this.type,
  });

  static Source fromJSON(Map<String, dynamic> json) => Source(
        name: json['name'],
        typeID: json['typeId'],
        type: json['type'],
      );
}

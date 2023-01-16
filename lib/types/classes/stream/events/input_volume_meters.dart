import 'package:obs_blade/types/classes/api/input.dart';

import 'base.dart';

/// A high-volume event providing volume levels of all active inputs every 50 milliseconds.
class InputVolumeMetersEvent extends BaseEvent {
  InputVolumeMetersEvent(super.json);

  /// Array of active inputs with their associated volume levels
  List<InputLevel> get inputs =>
      List.from(this.json['inputs'].map((input) => InputLevel.fromJSON(input)));
}

class InputLevel {
  String? inputName;
  List<InputChannel>? inputLevelsMul;

  InputLevel({
    required this.inputName,
    required this.inputLevelsMul,
  });

  static List<InputChannel> _mapToChannel(List<dynamic> channels) =>
      List.from(channels.map(
        (channel) => InputChannel(
          current: channel[1],
          average: channel[0],
          potential: channel[2],
        ),
      ));

  static InputLevel fromJSON(Map<String, dynamic> json) => InputLevel(
        inputName: json['inputName'],
        inputLevelsMul: json['inputLevelsMul'].isNotEmpty
            ? _mapToChannel(json['inputLevelsMul'])
            : [],
      );
}

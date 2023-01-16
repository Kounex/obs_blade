class Input {
  String? inputKind;
  String? inputName;
  String? unversionedInputKind;

  double? inputVolumeMul;
  double? inputVolumeDb;

  List<InputChannel>? inputLevelsMul;

  bool? inputMuted;

  Input({
    required this.inputKind,
    required this.inputName,
    required this.unversionedInputKind,
  });

  static Input fromJSON(Map<String, dynamic> json) => Input(
        inputKind: json['inputKind'],
        inputName: json['inputName'],
        unversionedInputKind: json['unversionedInputKind'],
      );
}

class InputChannel {
  double? current;
  double? average;
  double? potential;

  InputChannel({
    required this.current,
    required this.average,
    required this.potential,
  });
}

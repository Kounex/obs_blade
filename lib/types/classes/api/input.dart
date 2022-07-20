class Input {
  String? inputKind;
  String? inputName;
  String? unversionedInputKind;

  double? inputVolumeMul;
  double? inputVolumeDb;

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

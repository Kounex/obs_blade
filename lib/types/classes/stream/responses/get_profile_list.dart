import 'base.dart';

/// Gets an array of all profiles
class GetProfileListResponse extends BaseResponse {
  GetProfileListResponse(super.json);

  /// The name of the current profile
  String get currentProfileName => this.json['currentProfileName'];

  /// Array of all available profiles
  List<String> get profiles => List.from(this.json['profiles']);
}

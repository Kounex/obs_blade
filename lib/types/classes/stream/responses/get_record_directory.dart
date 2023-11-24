import 'base.dart';

/// Gets the current directory that the record output is set to.
class GetRecordDirectoryResponse extends BaseResponse {
  GetRecordDirectoryResponse(super.json);

  /// Output directory
  String get recordDirectory => this.json['recordDirectory'];
}

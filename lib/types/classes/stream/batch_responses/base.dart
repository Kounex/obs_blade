import 'package:obs_blade/types/classes/stream/responses/base.dart';
import 'package:obs_blade/types/enums/request_batch_type.dart';
import 'package:obs_blade/types/interfaces/message.dart';

import '../../../enums/request_type.dart';

class BaseBatchResponse implements Message {
  @override
  Map<String, dynamic> json;

  @override
  Map<String, dynamic> jsonRAW;

  List<BaseResponse> responses;

  BaseBatchResponse(this.json)
      : jsonRAW = json,
        responses = List.from(json['d']['results'])
            .map((response) => BaseResponse.d(response))
            .toList();

  String get uuid => this.jsonRAW['d']['requestId'];

  RequestBatchType get batchRequestType => RequestBatchType.values.firstWhere(
        (type) => type.requestTypes.every(
          (requestType) => this.responses.any(
                (response) => requestType == response.requestType,
              ),
        ),
      );

  T response<T extends BaseResponse>(
          RequestType requestType, T Function(Map<String, dynamic>) creation) =>
      creation(this
          .responses
          .firstWhere((response) => response.requestType == requestType)
          .jsonRAW);
}

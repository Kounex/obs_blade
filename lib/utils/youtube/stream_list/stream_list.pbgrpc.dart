// This is a generated file - do not edit.
//
// Generated from stream_list.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'stream_list.pb.dart' as $0;

export 'stream_list.pb.dart';

@$pb.GrpcServiceName('youtube.api.v3.V3DataLiveChatMessageService')
class V3DataLiveChatMessageServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  V3DataLiveChatMessageServiceClient(super.channel,
      {super.options, super.interceptors});

  /// Allows a user to load live chat through a server-streamed RPC.
  $grpc.ResponseStream<$0.LiveChatMessageListResponse> streamList(
    $0.LiveChatMessageListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamList, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$streamList = $grpc.ClientMethod<$0.LiveChatMessageListRequest,
          $0.LiveChatMessageListResponse>(
      '/youtube.api.v3.V3DataLiveChatMessageService/StreamList',
      ($0.LiveChatMessageListRequest value) => value.writeToBuffer(),
      $0.LiveChatMessageListResponse.fromBuffer);
}

@$pb.GrpcServiceName('youtube.api.v3.V3DataLiveChatMessageService')
abstract class V3DataLiveChatMessageServiceBase extends $grpc.Service {
  $core.String get $name => 'youtube.api.v3.V3DataLiveChatMessageService';

  V3DataLiveChatMessageServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LiveChatMessageListRequest,
            $0.LiveChatMessageListResponse>(
        'StreamList',
        streamList_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.LiveChatMessageListRequest.fromBuffer(value),
        ($0.LiveChatMessageListResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.LiveChatMessageListResponse> streamList_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.LiveChatMessageListRequest> $request) async* {
    yield* streamList($call, await $request);
  }

  $async.Stream<$0.LiveChatMessageListResponse> streamList(
      $grpc.ServiceCall call, $0.LiveChatMessageListRequest request);
}

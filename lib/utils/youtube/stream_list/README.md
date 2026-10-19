# streamList proto

`stream_list.proto` is Google's proto for `liveChatMessages.streamList`
(`V3DataLiveChatMessageService.StreamList`), copied verbatim from the
"stream_list.proto" section of the official guide:
<https://developers.google.com/youtube/v3/live/streaming-live-chat>.
The method is gRPC only - it isn't in the REST discovery doc, so
`package:googleapis` doesn't cover it.

The `*.pb*.dart` files are `protoc --dart_out=grpc` output (protobuf 6,
grpc 5) - don't edit them. To regenerate, run `tool/youtube_spike/setup.sh`
(fetches the proto and runs protoc) and copy `stream_list.proto` plus
`lib/src/generated/stream_list.{pb,pbenum,pbgrpc}.dart` here.

Read through `lib/utils/youtube/youtube_live_chat_stream.dart`.

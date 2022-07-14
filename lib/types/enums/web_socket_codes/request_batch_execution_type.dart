import 'package:obs_blade/types/enums/web_socket_codes/base.dart';

enum RequestBatchExecutionType implements BaseWebSocketCode {
  /// Not a request batch.
  None,

  /// A request batch which processes all requests serially, as fast as possible.
  ///
  /// Note: To introduce artificial delay, use the Sleep request and the sleepMillis request field.
  SerialRealtime,

  /// A request batch type which processes all requests serially, in sync with the graphics thread. Designed to provide high accuracy for animations.
  ///
  /// Note: To introduce artificial delay, use the Sleep request and the sleepFrames request field.
  SerialFrame,

  /// A request batch type which processes all requests using all available threads in the thread pool.
  ///
  /// Note: This is mainly experimental, and only really shows its colors during requests which require lots of active processing, like GetSourceScreenshot.
  Parallel;

  @override
  int get identifier => {
        RequestBatchExecutionType.None: -1,
        RequestBatchExecutionType.SerialRealtime: 0,
        RequestBatchExecutionType.SerialFrame: 1,
        RequestBatchExecutionType.Parallel: 2,
      }[this]!;

  @override
  String get message => {
        RequestBatchExecutionType.None: 'Not a request batch.',
        RequestBatchExecutionType.SerialRealtime:
            'A request batch which processes all requests serially, as fast as possible.\n\nNote: To introduce artificial delay, use the Sleep request and the sleepMillis request field.',
        RequestBatchExecutionType.SerialFrame:
            'A request batch type which processes all requests serially, in sync with the graphics thread. Designed to provide high accuracy for animations.\n\nNote: To introduce artificial delay, use the Sleep request and the sleepFrames request field.',
        RequestBatchExecutionType.Parallel:
            'A request batch type which processes all requests using all available threads in the thread pool.\n\nNote: This is mainly experimental, and only really shows its colors during requests which require lots of active processing, like GetSourceScreenshot.',
      }[this]!;
}

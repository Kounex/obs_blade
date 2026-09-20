import '../enums/request_type.dart';
import '../enums/web_socket_codes/request_status.dart';

/// Why an acknowledged OBS request ([NetworkHelper.makeRequest]) failed.
enum ObsRequestFailureKind {
  /// OBS answered with `requestStatus.result == false` (explicit rejection,
  /// carries the OBS status code and usually a comment)
  rejected,

  /// No answer arrived within the ack timeout
  timeout,

  /// The connection dropped / was closed before an answer arrived
  connectionLost,

  /// Never reached the wire: refused locally because the OBS connection is
  /// down (stale-state guard in DashboardStore.sendMutation). Not an OBS
  /// failure - no resync read, no failure surface
  notSent,
}

/// Typed outcome of an OBS request sent through the command-ack layer.
///
/// The result must never be used to *assign* optimistic state from - on
/// failure the confirmed state is re-read from OBS via the matching `Get*`
/// request and the existing response handlers apply it (self-healing).
class ObsRequestAck {
  /// The request that was sent (null when it could not be determined, e.g.
  /// unknown request types inside a batch response)
  final RequestType? requestType;

  /// null when OBS confirmed the request
  final ObsRequestFailureKind? failureKind;

  /// OBS `requestStatus.code` ([RequestStatus.identifier]) when [failureKind]
  /// is [ObsRequestFailureKind.rejected]
  final int? statusCode;

  /// OBS `requestStatus.comment` when provided
  final String? statusComment;

  const ObsRequestAck._(
    this.requestType,
    this.failureKind,
    this.statusCode,
    this.statusComment,
  );

  const ObsRequestAck.success(RequestType? requestType)
    : this._(requestType, null, null, null);

  const ObsRequestAck.rejected(
    RequestType? requestType,
    int statusCode,
    String? statusComment,
  ) : this._(
        requestType,
        ObsRequestFailureKind.rejected,
        statusCode,
        statusComment,
      );

  const ObsRequestAck.timeout(RequestType? requestType)
    : this._(requestType, ObsRequestFailureKind.timeout, null, null);

  const ObsRequestAck.connectionLost(RequestType? requestType)
    : this._(requestType, ObsRequestFailureKind.connectionLost, null, null);

  const ObsRequestAck.notSent(RequestType? requestType)
    : this._(requestType, ObsRequestFailureKind.notSent, null, null);

  bool get success => this.failureKind == null;

  /// The resolved [RequestStatus] for rejected requests (null for unknown /
  /// custom codes and for non-rejection failures)
  RequestStatus? get status {
    if (this.statusCode == null) return null;
    for (final status in RequestStatus.values) {
      if (status.identifier == this.statusCode) return status;
    }
    return null;
  }

  /// Single line summary for logs / failure surfacing
  String describe() {
    switch (this.failureKind) {
      case null:
        return '${this.requestType} succeeded';
      case ObsRequestFailureKind.rejected:
        return '${this.requestType} rejected by OBS (code ${this.statusCode}'
            '${this.statusComment != null ? ", ${this.statusComment}" : ""})';
      case ObsRequestFailureKind.timeout:
        return '${this.requestType} timed out waiting for the OBS ack';
      case ObsRequestFailureKind.connectionLost:
        return '${this.requestType} failed - connection to OBS was lost';
      case ObsRequestFailureKind.notSent:
        return '${this.requestType} not sent - OBS connection is down';
    }
  }
}

/// Outcome of an OBS batch request ([NetworkHelper.makeBatchRequest]) - v5
/// batches carry a per-request `requestStatus`, so a batch as a whole only
/// fails on its own (timeout / connection loss) while individual entries
/// can be rejected.
class ObsBatchAck {
  /// Batch-level failure (no response at all); null when OBS answered
  final ObsRequestFailureKind? failureKind;

  /// Per-request outcomes in response order
  final List<ObsRequestAck> results;

  const ObsBatchAck({this.failureKind, this.results = const []});

  const ObsBatchAck.timeout()
    : this(failureKind: ObsRequestFailureKind.timeout);

  const ObsBatchAck.connectionLost()
    : this(failureKind: ObsRequestFailureKind.connectionLost);

  bool get success =>
      this.failureKind == null &&
      this.results.every((result) => result.success);

  List<ObsRequestAck> get failures =>
      this.results.where((result) => !result.success).toList(growable: false);

  String describe() {
    if (this.failureKind != null) {
      return 'batch ${this.failureKind!.name}';
    }
    if (this.success) {
      return 'batch succeeded (${this.results.length} request(s))';
    }
    return 'batch partially failed: '
        '${this.failures.map((failure) => failure.describe()).join(" | ")}';
  }
}

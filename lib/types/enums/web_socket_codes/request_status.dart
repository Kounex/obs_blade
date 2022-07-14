import 'package:obs_blade/types/enums/web_socket_codes/base.dart';

enum RequestStatus implements BaseWebSocketCode {
  /// ******************************************************************************
  /// As specified by the WebSocket protocol
  /// ******************************************************************************

  /// Unknown status, should never be used.
  Unknown,

  /// For internal use to signify a successful field check.
  NoError,

  /// The request has succeeded.
  Success,

  /// The requestType field is missing from the request data.
  MissingRequestType,

  /// The request type is invalid or does not exist.
  UnknownRequestType,

  /// Generic error code.
  ///
  /// Note: A comment is required to be provided by obs-websocket.
  GenericError,

  /// The request batch execution type is not supported.
  UnsupportedRequestBatchExecutionType,

  /// A required request field is missing.
  MissingRequestField,

  /// The request does not have a valid requestData object.
  MissingRequestData,

  /// Generic invalid request field message.
  InvalidRequestField,

  /// A request field has the wrong data type.
  InvalidRequestFieldType,

  /// A request field (number) is outside of the allowed range.
  RequestFieldOutOfRange,

  /// A request field (string or array) is empty and cannot be.
  RequestFieldEmpty,

  /// There are too many request fields (eg. a request takes two optionals, where only one is allowed at a time).
  TooManyRequestFields,

  /// An output is running and cannot be in order to perform the request.
  OutputRunning,

  /// An output is not running and should be.
  OutputNotRunning,

  /// An output is paused and should not be.
  OutputPaused,

  /// An output is not paused and should be.
  OutputNotPaused,

  /// An output is disabled and should not be.
  OutputDisabled,

  /// Studio mode is active and cannot be.
  StudioModeActive,

  /// Studio mode is not active and should be.
  StudioModeNotActive,

  /// The resource was not found.
  ResourceNotFound,

  /// The resource already exists.
  ResourceAlreadyExists,

  /// The type of resource found is invalid.
  InvalidResourceType,

  /// There are not enough instances of the resource in order to perform the request.
  NotEnoughResources,

  /// The state of the resource is invalid. For example, if the resource is blocked from being accessed.
  InvalidResourceState,

  /// The specified input (obs_source_t-OBS_SOURCE_TYPE_INPUT) had the wrong kind.
  InvalidInputKind,

  /// The resource does not support being configured.
  ///
  /// This is particularly relevant to transitions, where they do not always have changeable settings.
  ResourceNotConfigurable,

  /// The specified filter (obs_source_t-OBS_SOURCE_TYPE_FILTER) had the wrong kind.
  InvalidFilterKind,

  /// Creating the resource failed.
  ResourceCreationFailed,

  /// Performing an action on the resource failed.
  ResourceActionFailed,

  /// Processing the request failed unexpectedly.
  ///
  /// Note: A comment is required to be provided by obs-websocket.
  RequestProcessingFailed,

  /// The combination of request fields cannot be used to perform an action.
  CannotAct,

  /// ******************************************************************************
  /// Custom ones to handle internal stuff
  /// ******************************************************************************

  /// Timeout
  Timeout;

  @override
  int get identifier => {
        RequestStatus.Unknown: 0,
        RequestStatus.NoError: 10,
        RequestStatus.Success: 100,
        RequestStatus.MissingRequestType: 203,
        RequestStatus.UnknownRequestType: 204,
        RequestStatus.GenericError: 205,
        RequestStatus.UnsupportedRequestBatchExecutionType: 206,
        RequestStatus.MissingRequestField: 300,
        RequestStatus.MissingRequestData: 301,
        RequestStatus.InvalidRequestField: 400,
        RequestStatus.InvalidRequestFieldType: 401,
        RequestStatus.RequestFieldOutOfRange: 402,
        RequestStatus.RequestFieldEmpty: 403,
        RequestStatus.TooManyRequestFields: 404,
        RequestStatus.OutputRunning: 500,
        RequestStatus.OutputNotRunning: 501,
        RequestStatus.OutputPaused: 502,
        RequestStatus.OutputNotPaused: 503,
        RequestStatus.OutputDisabled: 504,
        RequestStatus.StudioModeActive: 505,
        RequestStatus.StudioModeNotActive: 506,
        RequestStatus.ResourceNotFound: 600,
        RequestStatus.ResourceAlreadyExists: 601,
        RequestStatus.InvalidResourceType: 602,
        RequestStatus.NotEnoughResources: 603,
        RequestStatus.InvalidResourceState: 604,
        RequestStatus.InvalidInputKind: 605,
        RequestStatus.ResourceNotConfigurable: 606,
        RequestStatus.InvalidFilterKind: 607,
        RequestStatus.ResourceCreationFailed: 700,
        RequestStatus.ResourceActionFailed: 701,
        RequestStatus.RequestProcessingFailed: 702,
        RequestStatus.CannotAct: 703,
        RequestStatus.Timeout: 999,
      }[this]!;

  @override
  String get message => {
        RequestStatus.Unknown: 'Unknown status, should never be used.',
        RequestStatus.NoError:
            'For internal use to signify a successful field check.',
        RequestStatus.Success: 'The request has succeeded.',
        RequestStatus.MissingRequestType:
            'The requestType field is missing from the request data.',
        RequestStatus.UnknownRequestType:
            'The request type is invalid or does not exist.',
        RequestStatus.GenericError:
            'Generic error code.\n\nNote: A comment is required to be provided by obs-websocket.',
        RequestStatus.UnsupportedRequestBatchExecutionType:
            'The request batch execution type is not supported.',
        RequestStatus.MissingRequestField:
            'A required request field is missing.',
        RequestStatus.MissingRequestData:
            'The request does not have a valid requestData object.',
        RequestStatus.InvalidRequestField:
            'Generic invalid request field message.',
        RequestStatus.InvalidRequestFieldType:
            'A request field has the wrong data type.',
        RequestStatus.RequestFieldOutOfRange:
            'A request field (number) is outside of the allowed range.',
        RequestStatus.RequestFieldEmpty:
            'A request field (string or array) is empty and cannot be.',
        RequestStatus.TooManyRequestFields:
            'There are too many request fields (eg. a request takes two optionals, where only one is allowed at a time).',
        RequestStatus.OutputRunning:
            'An output is running and cannot be in order to perform the request.',
        RequestStatus.OutputNotRunning:
            'An output is not running and should be.',
        RequestStatus.OutputPaused: 'An output is paused and should not be.',
        RequestStatus.OutputNotPaused: 'An output is not paused and should be.',
        RequestStatus.OutputDisabled:
            'An output is disabled and should not be.',
        RequestStatus.StudioModeActive: 'Studio mode is active and cannot be.',
        RequestStatus.StudioModeNotActive:
            'Studio mode is not active and should be.',
        RequestStatus.ResourceNotFound: 'The resource was not found.',
        RequestStatus.ResourceAlreadyExists: 'The resource already exists.',
        RequestStatus.InvalidResourceType:
            'The type of resource found is invalid.',
        RequestStatus.NotEnoughResources:
            'There are not enough instances of the resource in order to perform the request.',
        RequestStatus.InvalidResourceState:
            'The state of the resource is invalid. For example, if the resource is blocked from being accessed.',
        RequestStatus.InvalidInputKind:
            'The specified input (obs_source_t-OBS_SOURCE_TYPE_INPUT) had the wrong kind.',
        RequestStatus.ResourceNotConfigurable:
            'The resource does not support being configured.\n\nThis is particularly relevant to transitions, where they do not always have changeable settings.',
        RequestStatus.InvalidFilterKind:
            'The specified filter (obs_source_t-OBS_SOURCE_TYPE_FILTER) had the wrong kind.',
        RequestStatus.ResourceCreationFailed: 'Creating the resource failed.',
        RequestStatus.ResourceActionFailed:
            'Performing an action on the resource failed.',
        RequestStatus.RequestProcessingFailed:
            'Processing the request failed unexpectedly.\n\nNote: A comment is required to be provided by obs-websocket.',
        RequestStatus.CannotAct:
            'The combination of request fields cannot be used to perform an action.',
        RequestStatus.Timeout: 'Timeout',
      }[this]!;
}

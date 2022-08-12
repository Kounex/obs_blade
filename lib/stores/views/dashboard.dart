import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/transition.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/inputs.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/stats.dart';
import 'package:obs_blade/types/classes/stream/events/input_mute_state_changed.dart';
import 'package:obs_blade/types/classes/stream/events/replay_buffer_state_changed.dart';
import 'package:obs_blade/types/classes/stream/events/transition_duration_changed.dart';
import 'package:obs_blade/types/classes/stream/responses/get_replay_buffer_status.dart';
import 'package:obs_blade/types/classes/stream/responses/get_scene_collection_list.dart';
import 'package:obs_blade/types/classes/stream/responses/get_special_inputs.dart';
import 'package:obs_blade/types/enums/request_batch_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

import '../../models/enums/log_level.dart';
import '../../models/past_record_data.dart';
import '../../models/past_stream_data.dart';
import '../../types/classes/api/record_stats.dart';
import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/current_preview_scene_changed.dart';
import '../../types/classes/stream/events/current_program_scene_changed.dart';
import '../../types/classes/stream/events/current_scene_collection_changed.dart';
import '../../types/classes/stream/events/input_volume_changed.dart';
import '../../types/classes/stream/events/scene_collection_list_changed.dart';
import '../../types/classes/stream/events/scene_item_enable_state_changed.dart';
import '../../types/classes/stream/events/studio_mode_switched.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene_transition.dart';
import '../../types/classes/stream/responses/get_group_scene_item_list.dart';
import '../../types/classes/stream/responses/get_input_kind_list.dart';
import '../../types/classes/stream/responses/get_input_list.dart';
import '../../types/classes/stream/responses/get_input_mute.dart';
import '../../types/classes/stream/responses/get_input_volume.dart';
import '../../types/classes/stream/responses/get_scene_item_list.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_scene_transition_list.dart';
import '../../types/classes/stream/responses/get_source_screenshot.dart';
import '../../types/classes/stream/responses/get_stats.dart';
import '../../types/classes/stream/responses/get_studio_mode_enabled.dart';
import '../../types/classes/stream/responses/get_version.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../../utils/overlay_handler.dart';
import '../shared/network.dart';

part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;
  @observable
  bool isRecording = false;
  @observable
  bool isRecordingPaused = false;
  @observable
  bool isReplayBufferActive = false;
  @observable
  int? latestStreamTimeDurationMS;
  @observable
  int? latestRecordTimeDurationMS;
  @observable
  PastStreamData? streamData;
  @observable
  StreamStats? latestStreamStats;
  @observable
  PastRecordData? recordData;
  @observable
  RecordStats? latestRecordStats;
  @observable
  GetStatsResponse? latestOBSStats;

  @observable
  String? currentSceneCollectionName;
  @observable
  ObservableList<String>? sceneCollections;
  @observable
  String? activeSceneName;
  @observable
  ObservableList<Scene>? scenes;

  /// WebSocket API will return all top level scene items for
  /// the current scene and elements of groups are inside the
  /// separate [SceneItem.groupChildren]. To better maintain and work
  /// with scene items, I flatten these so all scene items, even
  /// the children of groups are on top level and a custom
  /// [SceneItem.displayGroup] propertry toggles whether they
  /// will be displayed or not, but this makes searching and
  /// updating scene items easier
  @observable
  ObservableList<SceneItem>? currentSceneItems;

  /// Not used currently as the WebSocket API does not expose working
  /// with such sources (playing, stopping, etc.) right now. This will likely
  /// be supported in the near future which therefore enables Soundboard support!
  // @computed
  // ObservableList<SceneItem> get currentSoundboardSceneItems =>
  //     this.currentSceneItems != null
  //         ? ObservableList.of(this.currentSceneItems!.where((sceneItem) =>
  //             sceneItem.type == 'ffmpeg_source' && sceneItem.render!))
  //         : ObservableList();

  /// Will contain all inputs returned by [GetInputList] which will even contian
  /// special inputs etc.
  @observable
  ObservableList<Input> allInputs = ObservableList();

  /// Names of the global inputs - used for filtering
  @observable
  ObservableList<String> globalInputNames = ObservableList();

  /// Inputs which are present due to scene item elements - therefore bound to
  /// individual scenes
  @computed
  ObservableList<Input> get currentInputs => ObservableList.of(
        this.allInputs.where((input) => this
            .globalInputNames
            .every((globalInputName) => globalInputName != input.inputName)),
      );

  /// "Special" audio inputs produced by global entities like Desktop or Mic
  @computed
  ObservableList<Input> get globalInputs => ObservableList.of(
        this.allInputs.where((input) => this
            .globalInputNames
            .any((globalInputName) => globalInputName == input.inputName)),
      );

  @observable
  Transition? currentTransition;

  @observable
  List<Transition>? availableTransitions;

  /// Indicates whether the the [requestPreviewImage] method should be called.
  /// Will do so as long as it stays true and stops once its false again
  @observable
  bool shouldRequestPreviewImage = false;

  /// Will hold the current image (screenshot) for the active scene - will be
  /// set and updated as fast as possible with new screenshots while [shouldRequestPreviewImage]
  /// is true and will therefore be used as the workaround of a live preview of the
  /// active scene
  @observable
  Uint8List? scenePreviewImageBytes;

  /// Checks whether the user is trying to scroll while the pointer (finger) is
  /// on the chat - this means the user probably wants to scroll the chat.
  /// If the user wants to scroll inside the app, the pointer (finger) may not
  /// be on the chat but above or underneath (UI wise)
  @observable
  bool isPointerOnChat = false;

  /// Indicator (which is used in [_checkOBSConnection]) whether we attempt a
  /// reconnect since the WebSocket connection closed. Can and is currently listened
  /// to in [ReconnectToast] to show the user that a reconnect attempt is ongoing
  @observable
  bool reconnecting = false;

  /// Toggles the visibility of the hide/show sliding pane of the scene items
  @observable
  bool editSceneItemVisibility = false;

  /// Toggles the visibility of the hide/show sliding pane of the audios
  @observable
  bool editAudioVisibility = false;

  /// Whether studio mode is active
  @observable
  bool studioMode = false;

  /// Currently selected preview scene (only in studio mode)
  @observable
  String? studioModePreviewSceneName;

  @observable
  bool editSceneVisibility = false;

  List<String>? inputKinds;

  Timer? checkConnectionTimer;

  String previewFileFormat = 'jpeg';

  /// Will be used internally while switching scene collections.
  /// Since this operation takes time and "random" events are coming
  /// in while we dont even have all the new information from the
  /// new scene collection, we need to stop handling those events /requests
  /// while waiting until we actually changed the scene collection
  /// (getting the response from [SetCurrentSceneCollection]) and then
  /// call [sceneCollectionRequests]
  bool handleRequestsEvents = true;

  /// Bytes output of the stream - emitted by GetStreamStatus and will
  /// be used as the previous temp value to calculate kbit/s
  int _streamBytes = 0;

  /// Bytes output of the record - emitted by GetRecordStatus and will
  /// be used as the previous temp value to calculate kbit/s
  int _recordBytes = 0;

  /// Set of initial requests to call in order to get all the basic
  /// information / configuration for the OBS session
  void initialRequests() {
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetVersion,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSceneCollectionList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetStudioModeEnabled,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetRecordStatus,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetStreamStatus,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetReplayBufferStatus,
    );

    _periodicStatsRequest();

    _sceneCollectionRequests();
  }

  /// Requests dedicated to get all the information from the current
  /// scene collection (can be called independently after switching the
  /// scene collection or if we want to refresh the information for the
  /// current scene collection)
  void _sceneCollectionRequests() {
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSceneList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetInputList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSpecialInputs,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetInputKindList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSceneTransitionList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetInputList,
    );
  }

  void handleStream() {
    GetIt.instance<NetworkStore>().watchOBSStream().listen((message) {
      try {
        if (handleRequestsEvents ||
            (message is BaseEvent &&
                message.eventType == EventType.CurrentSceneCollectionChanged)) {
          if (message is BaseEvent) {
            _handleEvent(message);
          } else if (message is BaseResponse) {
            _handleResponse(message);
          } else if (message is BaseBatchResponse) {
            _handleBatchResponse(message);
          }
        }
      } catch (e) {
        GeneralHelper.advLog(e);
      }
    });
  }

  void _requestPreviewImage() => NetworkHelper.makeRequest(
        GetIt.instance<NetworkStore>().activeSession!.socket,
        RequestType.GetSourceScreenshot,
        {
          'sourceName': Hive.box(HiveKeys.Settings.name).get(
                      SettingsKeys.ExposeStudioControls.name,
                      defaultValue: false) &&
                  this.studioMode
              ? this.studioModePreviewSceneName
              : this.activeSceneName,
          'imageFormat': this.previewFileFormat,
          'compressionQuality': -1,
        },
      );

  /// Periodically polls the OBS, stream and record stats by making use
  /// of the batch request capabilities every second since we don't receive
  /// a status event every 2 seconds (as it was prior OBS WebSocket 4.9.1 and
  /// below)
  void _periodicStatsRequest() {
    Timer.periodic(
      const Duration(milliseconds: 1000),
      (_) => NetworkHelper.makeBatchRequest(
        GetIt.instance<NetworkStore>().activeSession!.socket,
        RequestBatchType.Stats,
        [
          RequestBatchObject(RequestType.GetStreamStatus),
          RequestBatchObject(RequestType.GetRecordStatus),
          RequestBatchObject(RequestType.GetStats),
        ],
      ),
    );
  }

  /// SceneItems which type is 'group' can have children which are
  /// SceneItems again - this would lead to checking those children
  /// in many cases (a lot of work and extra code). So instead I flatten
  /// this by adding those children to the general list and since
  /// those children have their parent name as a property I can easily
  /// identify them in the flat list
  List<SceneItem> _flattenSceneItems(Iterable<SceneItem> sceneItems) {
    List<SceneItem> tmpSceneItems = [];
    for (var sceneItem in sceneItems) {
      tmpSceneItems.add(sceneItem);
      if (sceneItem.groupChildren != null &&
          sceneItem.groupChildren!.isNotEmpty) {
        tmpSceneItems.addAll(sceneItem.groupChildren!);
      }
    }
    return tmpSceneItems;
  }

  /// If we are live and have no [PastStreamData]
  /// instance (null) we need to check if we create a completely new
  /// instance (indicating new stream) or we use the last one since it
  /// seems as this is the same stream we already were connected to
  Future<void> _manageStreamDataInit() async {
    Box<PastStreamData> pastStreamDataBox =
        Hive.box<PastStreamData>(HiveKeys.PastStreamData.name);
    List<PastStreamData> tmp = pastStreamDataBox.values.toList();

    /// Sort ascending so the last entry is the latest stream
    tmp.sort((a, b) => a.listEntryDateMS.last - b.listEntryDateMS.last);

    /// Check if the latest stream has its last entry (based on [listEntryDateMS]
    /// set later than current time - [totalStreamTime] which means that we
    /// connected to an OBS session we already were connected to
    if (tmp.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestStreamStats!.totalStreamTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.streamData = tmp.last;
    } else {
      this.streamData = PastStreamData();
      await pastStreamDataBox.add(this.streamData!);
    }
  }

  /// If we are recording and have no [PastRecordData]
  /// instance (null) we need to check if we create a completely new
  /// instance (indicating new stream) or we use the last one since it
  /// seems as this is the same stream we already were connected to
  Future<void> _manageRecordDataInit() async {
    Box<PastRecordData> pastRecordDataBox =
        Hive.box<PastRecordData>(HiveKeys.PastRecordData.name);
    List<PastRecordData> tmp = pastRecordDataBox.values.toList();

    /// Sort ascending so the last entry is the latest stream
    tmp.sort((a, b) => a.listEntryDateMS.last - b.listEntryDateMS.last);

    /// Check if the latest stream has its last entry (based on [listEntryDateMS]
    /// set later than current time - [totalStreamTime] which means that we
    /// connected to an OBS session we already were connected to
    if (tmp.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestRecordStats!.totalRecordTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.recordData = tmp.last;
    } else {
      this.recordData = PastRecordData();
      await pastRecordDataBox.add(this.recordData!);
    }
  }

  /// Check if we have ongoing statistics (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> _finishPastStreamData() async {
    if (this.streamData != null) {
      /// Check if [streamData] is even "legit" - if [totalStreamTime]
      /// is not greater than 3, it's not worth the statistic entry and
      /// will probably cause problems anyway. We will delete it therefore
      if (this.streamData!.isInBox &&
          (this.streamData!.totalStreamTime == null ||
              this.streamData!.totalStreamTime! <= 3)) {
        await this.streamData!.delete();
      }
      this.streamData = null;
    }
  }

  /// Check if we have ongoing statistics (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> _finishPastRecordData() async {
    if (this.recordData != null) {
      /// Check if [recordData] is even "legit" - if [totalRecordTime]
      /// is not greater than 3, it's not worth the statistic entry and
      /// will probably cause problems anyway. We will delete it therefore
      if (this.recordData!.isInBox &&
          (this.recordData!.totalRecordTime == null ||
              this.recordData!.totalRecordTime! <= 3)) {
        await this.recordData!.delete();
      }
      this.recordData = null;
    }
  }

  int? _timecodeToMS(String? timecode) {
    if (timecode != null) {
      List<String> recTimeFragments = timecode.split(':');

      return Duration(
        hours: int.parse(recTimeFragments[0]),
        minutes: int.parse(recTimeFragments[1]),
        seconds: int.parse(recTimeFragments[2].split('.')[0]),
      ).inMilliseconds;
    }
    return null;
  }

  @action
  void init() {
    this.handleStream();
    this.initialRequests();

    /// Since [setupNetworkStoreHandling] gets called as soon as we connect
    /// to an OBS instance, we trigger this [Timer] which will check if
    /// the connection is still alive periodically - see [_checkOBSConnection]
    /// for more information
    this.checkConnectionTimer = Timer(
      const Duration(seconds: 5),
      () => _checkOBSConnection(),
    );
  }

  /// While using the device this app is running on while connected to an OBS
  /// instance, it may happen that we lose the connection due to OS background
  /// behaviour or because we lose network connection or other reasons. This function
  /// intents to check if the connection (in this case a WebSocket connection) is
  /// still active (no [closeCode] present) - if so, we try to establish a new connection.
  /// If we still have a [closeCode] after trying to establish a new connection, we
  /// set the [obsTerminated] flag to initiate that we can't reach OBS anymore and
  /// we get back to our [HomeView]
  @action
  Future<void> _checkOBSConnection() async {
    if (GetIt.instance<NetworkStore>().activeSession?.socket.closeCode !=
            null &&
        !GetIt.instance<NetworkStore>().obsTerminated) {
      this.reconnecting = true;
      WebSocketCloseCode? closeCode;
      int tries = 0;

      GeneralHelper.advLog(
        'Lost active connection to OBS, trying to reconnect',
        level: LogLevel.Warning,
        includeInLogs: true,
      );

      while ((Hive.box(HiveKeys.Settings.name).get(
                  SettingsKeys.UnlimitedReconnects.name,
                  defaultValue: false) ||
              tries < 5) &&
          (closeCode == null || closeCode != WebSocketCloseCode.DontClose)) {
        await Future.delayed(
          const Duration(seconds: 3),
        );
        closeCode = await GetIt.instance<NetworkStore>().setOBSWebSocket(
          GetIt.instance<NetworkStore>().activeSession!.connection,
          reconnect: true,
        );
        tries++;
        GeneralHelper.advLog(
          '$tries. attempt to reconnect...',
          level: LogLevel.Warning,
          includeInLogs: true,
        );
      }
      if (closeCode == null || closeCode != WebSocketCloseCode.DontClose) {
        GeneralHelper.advLog(
          'Not able to reconnect to OBS, initiating termination process!',
          level: LogLevel.Warning,
          includeInLogs: true,
        );
        GetIt.instance<NetworkStore>().obsTerminated = true;
      } else {
        GeneralHelper.advLog(
          'Successfully reconnected to OBS!',
          level: LogLevel.Warning,
          includeInLogs: true,
        );

        this.reconnecting = false;
        this.handleStream();
        this.initialRequests();
        this.checkConnectionTimer = Timer(
          const Duration(seconds: 3),
          () => _checkOBSConnection(),
        );
      }
    } else {
      this.checkConnectionTimer = Timer(
        const Duration(seconds: 3),
        () => _checkOBSConnection(),
      );
    }
  }

  @action
  void setShouldRequestPreviewImage(bool shouldRequestPreviewImage) {
    this.shouldRequestPreviewImage = shouldRequestPreviewImage;
    if (shouldRequestPreviewImage) {
      this.scenePreviewImageBytes = null;
      _requestPreviewImage();
    }
  }

  @action
  void setPointerOnChat(bool isPointerOnChat) =>
      this.isPointerOnChat = isPointerOnChat;

  @action
  void toggleSceneItemGroupVisibility(SceneItem sceneItem) {
    sceneItem.displayGroup = !sceneItem.displayGroup;
    this.currentSceneItems = ObservableList.of(this.currentSceneItems!);
  }

  @action
  void setEditSceneItemVisibility(bool editSceneItemVisibility) =>
      this.editSceneItemVisibility = editSceneItemVisibility;

  @action
  void setEditAudioVisibility(bool editAudioVisibility) =>
      this.editAudioVisibility = editAudioVisibility;

  @action
  void setEditSceneVisibility(bool editSceneVisibility) =>
      this.editSceneVisibility = editSceneVisibility;

  @action
  void setActiveSceneName(String activeSceneName) =>
      this.activeSceneName = activeSceneName;

  @action
  void setStudioModePreviewSceneName(String studioModePreviewSceneName) =>
      this.studioModePreviewSceneName = studioModePreviewSceneName;

  @action
  Future<void> _handleEvent(BaseEvent event) async {
    if (event.eventType == null) {
      GeneralHelper.advLog(
        'NOT HANDLED - Event Incoming: ${event.jsonRAW['d']['eventType']}',
      );
    } else {
      GeneralHelper.advLog(
        'Event Incoming: ${event.eventType}',
      );
    }

    switch (event.eventType) {
      // case EventType.StreamStateChanged:
      //   StreamStateChangedEvent streamStateChangedEvent =
      //       StreamStateChangedEvent(event.jsonRAW);

      //   this.isLive = streamStateChangedEvent.outputActive;

      //   if (!this.isLive) {
      //     this.latestStreamTimeDurationMS = null;
      //   }
      //   break;
      // case EventType.RecordStateChanged:
      //   RecordStateChangedEvent recordStateChangedEvent =
      //       RecordStateChangedEvent(event.jsonRAW);

      //   switch (recordStateChangedEvent.outputState) {
      //     case 'OBS_WEBSOCKET_OUTPUT_STARTING':
      //       this.isRecording = true;
      //       break;
      //     case 'OBS_WEBSOCKET_OUTPUT_STOPPED':
      //       this.isRecording = false;
      //       this.isRecordingPaused = false;
      //       this.latestRecordTimeDurationMS = null;
      //       break;
      //     case 'OBS_WEBSOCKET_OUTPUT_PAUSED':
      //       this.isRecordingPaused = true;
      //       break;
      //     case 'OBS_WEBSOCKET_OUTPUT_RESUMED':
      //       this.isRecordingPaused = false;
      //       break;
      //   }
      //   break;
      case EventType.ReplayBufferStateChanged:
        ReplayBufferStateChangedEvent replayBufferStateChangedEvent =
            ReplayBufferStateChangedEvent(event.jsonRAW);
        this.isReplayBufferActive = replayBufferStateChangedEvent.outputActive;

        if (!this.isReplayBufferActive) {
          OverlayHandler.closeAnyOverlay(immediately: false);
        }
        break;

      case EventType.CurrentSceneCollectionChanging:
        this.handleRequestsEvents = false;
        break;
      case EventType.CurrentSceneCollectionChanged:
        CurrentSceneCollectionChangedEvent currentSceneCollectionChangedEvent =
            CurrentSceneCollectionChangedEvent(event.jsonRAW);

        OverlayHandler.closeAnyOverlay(immediately: false);

        this.currentSceneCollectionName =
            currentSceneCollectionChangedEvent.sceneCollectionName;

        this.handleRequestsEvents = true;
        _sceneCollectionRequests();
        break;
      case EventType.SceneCollectionListChanged:
        SceneCollectionListChangedEvent sceneCollectionListChangedEvent =
            SceneCollectionListChangedEvent(event.jsonRAW);

        this.sceneCollections =
            ObservableList.of(sceneCollectionListChangedEvent.sceneCollections);

        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetSceneList);
        break;
      case EventType.CurrentSceneTransitionChanged:
        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.GetSceneTransitionList,
        );
        break;
      case EventType.CurrentSceneTransitionDurationChanged:
        CurrentSceneTransitionDurationChangedEvent
            currentSceneTransitionDurationChangedEvent =
            CurrentSceneTransitionDurationChangedEvent(event.jsonRAW);
        this.currentTransition?.transitionDuration =
            currentSceneTransitionDurationChangedEvent.transitionDuration;

        this.currentTransition = this.currentTransition;
        break;
      case EventType.StudioModeStateChanged:
        if (Hive.box(HiveKeys.Settings.name)
            .get(SettingsKeys.ExposeStudioControls.name, defaultValue: false)) {
          StudioModeStateChangedEvent studioModeStateChangedEvent =
              StudioModeStateChangedEvent(event.jsonRAW);

          this.studioMode = studioModeStateChangedEvent.studioModeEnabled;

          NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetSceneList,
          );
        }
        break;
      case EventType.CurrentProgramSceneChanged:
        CurrentProgramSceneChangedEvent currentProgramSceneChangedEvent =
            CurrentProgramSceneChangedEvent(event.jsonRAW);

        this.activeSceneName = currentProgramSceneChangedEvent.sceneName;
        _sceneCollectionRequests();
        break;
      case EventType.CurrentPreviewSceneChanged:
        CurrentPreviewSceneChangedEvent currentPreviewSceneChangedEvent =
            CurrentPreviewSceneChangedEvent(event.jsonRAW);

        this.studioModePreviewSceneName =
            currentPreviewSceneChangedEvent.sceneName;

        if (Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false) &&
            this.studioMode) {
          _sceneCollectionRequests();
        }
        break;

      /// I could handle the following events smarter in the future - instead
      /// of making the full request I could handle the change. Currently
      /// not worth the hassle since we have to deal with cross synergies
      /// like scene items being tied to inputs, having groups etc.
      case EventType.SceneItemCreated:
        _sceneCollectionRequests();
        break;
      case EventType.SceneItemRemoved:
        _sceneCollectionRequests();
        break;
      case EventType.InputNameChanged:
        _sceneCollectionRequests();
        break;
      case EventType.SceneItemListReindexed:
        _sceneCollectionRequests();
        break;
      case EventType.InputVolumeChanged:
        InputVolumeChangedEvent inputVolumeChangedEvent =
            InputVolumeChangedEvent(event.jsonRAW);

        this.allInputs.firstWhere(
            (input) => input.inputName == inputVolumeChangedEvent.inputName)
          ..inputVolumeMul = inputVolumeChangedEvent.inputVolumeMul
          ..inputVolumeDb = inputVolumeChangedEvent.inputVolumeDb;
        this.allInputs = this.allInputs;

        break;
      case EventType.InputMuteStateChanged:
        InputMuteStateChangedEvent inputMuteStateChangedEvent =
            InputMuteStateChangedEvent(event.jsonRAW);

        this
            .allInputs
            .firstWhere((input) =>
                input.inputName == inputMuteStateChangedEvent.inputName)
            .inputMuted = inputMuteStateChangedEvent.inputMuted;
        this.allInputs = this.allInputs;

        break;
      case EventType.SceneItemEnableStateChanged:
        SceneItemEnableStateChangedEvent sceneItemEnableStateChangedEvent =
            SceneItemEnableStateChangedEvent(event.jsonRAW);

        this
                .currentSceneItems!
                .firstWhere((sceneItem) =>
                    sceneItem.sceneItemId ==
                    sceneItemEnableStateChangedEvent.sceneItemId)
                .sceneItemEnabled =
            sceneItemEnableStateChangedEvent.sceneItemEnabled;

        this.currentSceneItems = ObservableList.of(this.currentSceneItems!);

        break;
      case EventType.ExitStarted:
        await _finishPastStreamData();
        GetIt.instance<NetworkStore>().obsTerminated = true;
        break;
      default:
        break;
    }
  }

  @action
  void _handleResponse(BaseResponse response) {
    GeneralHelper.advLog(
      'Response Incoming: ${(response.requestType)}',
    );

    switch (response.requestType) {
      case RequestType.GetVersion:
        GetVersionResponse getVersionResponse =
            GetVersionResponse(response.jsonRAW);

        if (!getVersionResponse.supportedImageFormats.contains('jpg') &&
            !getVersionResponse.supportedImageFormats.contains('jpeg')) {
          this.previewFileFormat = 'png';
        }
        break;
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.jsonRAW);

        this.activeSceneName = getSceneListResponse.currentProgramSceneName;
        this.studioModePreviewSceneName =
            getSceneListResponse.currentPreviewSceneName;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);

        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.GetSceneItemList,
          {
            'sceneName': Hive.box(HiveKeys.Settings.name).get(
                        SettingsKeys.ExposeStudioControls.name,
                        defaultValue: false) &&
                    this.studioMode
                ? this.studioModePreviewSceneName
                : this.activeSceneName,
          },
        );
        break;
      case RequestType.GetSceneCollectionList:
        GetSceneCollectionListResponse getSceneCollectionListResponse =
            GetSceneCollectionListResponse(response.jsonRAW);

        this.sceneCollections =
            ObservableList.of(getSceneCollectionListResponse.sceneCollections);

        this.currentSceneCollectionName =
            getSceneCollectionListResponse.currentSceneCollectionName;
        break;
      case RequestType.GetSceneItemList:
        GetSceneItemListResponse getSceneItemListResponse =
            GetSceneItemListResponse(response.jsonRAW);

        this.currentSceneItems =
            ObservableList.of(getSceneItemListResponse.sceneItems)
              ..sort((sc1, sc2) =>
                  (sc2.sceneItemIndex ?? 0) - (sc1.sceneItemIndex ?? 0));

        for (final sceneItem in this.currentSceneItems!) {
          if (sceneItem.isGroup ?? false) {
            NetworkHelper.makeRequest(
              GetIt.instance<NetworkStore>().activeSession!.socket,
              RequestType.GetGroupSceneItemList,
              {
                'sceneName': sceneItem.sourceName,
              },
            );
          }
        }

        break;
      case RequestType.GetGroupSceneItemList:
        GetGroupSceneItemListResponse getGroupSceneItemListResponse =
            GetGroupSceneItemListResponse(response.jsonRAW);

        final parentSceneItemName = NetworkHelper.getRequestBodyForUUID(
            getGroupSceneItemListResponse.uuid)!['sceneName'];

        List<SceneItem> childrenSceneItems =
            getGroupSceneItemListResponse.sceneItems;

        for (var sceneItem in childrenSceneItems) {
          sceneItem.parentGroupName = parentSceneItemName;
        }

        this.currentSceneItems = ObservableList.of([
          ...this.currentSceneItems!
            ..insertAll(
                this.currentSceneItems!.indexOf(
                          this.currentSceneItems!.firstWhere((sceneItem) =>
                              (sceneItem.isGroup ?? false) &&
                              sceneItem.sourceName == parentSceneItemName),
                        ) +
                    1,
                childrenSceneItems
                  ..sort((sc1, sc2) =>
                      (sc2.sceneItemIndex ?? 0) - (sc1.sceneItemIndex ?? 0))),
        ]);

        break;
      case RequestType.GetInputList:
        GetInputListResponse getInputListResponse =
            GetInputListResponse(response.jsonRAW);

        this.allInputs = ObservableList.of(getInputListResponse.inputs);

        NetworkHelper.makeBatchRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestBatchType.Input,
          [
            for (var input in this.allInputs) ...[
              RequestBatchObject(
                  RequestType.GetInputVolume, {'inputName': input.inputName}),
              RequestBatchObject(
                  RequestType.GetInputMute, {'inputName': input.inputName}),
            ],
          ],
        );
        break;
      case RequestType.GetSceneTransitionList:
        GetSceneTransitionListResponse getSceneTransitionListResponse =
            GetSceneTransitionListResponse(response.jsonRAW);

        this.availableTransitions = getSceneTransitionListResponse.transitions;

        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.GetCurrentSceneTransition,
        );
        break;
      case RequestType.GetCurrentSceneTransition:
        GetCurrentSceneTransitionResponse getCurrentSceneTransitionResponse =
            GetCurrentSceneTransitionResponse(response.jsonRAW);

        this.currentTransition = Transition(
          transitionName: getCurrentSceneTransitionResponse.transitionName,
          transitionKind: getCurrentSceneTransitionResponse.transitionKind,
          transitionFixed: getCurrentSceneTransitionResponse.transitionFixed,
          transitionDuration:
              getCurrentSceneTransitionResponse.transitionDuration,
          transitionConfigurable:
              getCurrentSceneTransitionResponse.transitionConfigurable,
          transitionSettings:
              getCurrentSceneTransitionResponse.transitionSettings,
        );
        break;
      case RequestType.GetStudioModeEnabled:
        GetStudioModeEnabledResponse getStudioModeEnabledResponse =
            GetStudioModeEnabledResponse(response.jsonRAW);

        this.studioMode = getStudioModeEnabledResponse.studioModeEnabled;
        if (Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStudioControls.name,
                defaultValue: false) &&
            this.studioMode) {
          NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.GetSceneList,
          );
        }
        break;
      // case RequestType.GetStreamStatus:
      //   GetStreamStatusResponse getStreamStatusResponse =
      //       GetStreamStatusResponse(response.jsonRAW);

      //   this.isLive = getStreamStatusResponse.outputActive;

      //   if (this.isLive) {
      //     this.latestStreamTimeDurationMS =
      //         _timecodeToMS(getStreamStatusResponse.outputTimecode);
      //   }
      //   break;
      // case RequestType.GetRecordStatus:
      //   GetRecordStatusResponse getRecordStatusResponse =
      //       GetRecordStatusResponse(response.jsonRAW);

      //   this.isRecordingPaused = getRecordStatusResponse.ouputPaused ?? false;
      //   this.isRecording = this.isRecordingPaused
      //       ? true
      //       : getRecordStatusResponse.outputActive;

      //   if (this.isRecording) {
      //     this.latestRecordTimeDurationMS =
      //         _timecodeToMS(getRecordStatusResponse.outputTimecode);
      //   }
      //   break;
      case RequestType.GetReplayBufferStatus:
        GetReplayBufferStatusResponse getReplayBufferStatusResponse =
            GetReplayBufferStatusResponse(response.jsonRAW);

        this.isReplayBufferActive =
            getReplayBufferStatusResponse.isReplayBufferActive;

        break;
      case RequestType.GetSpecialInputs:
        GetSpecialInputsResponse getSpecialInputsResponse =
            GetSpecialInputsResponse(response.jsonRAW);

        this.globalInputNames = ObservableList.of([
          if (getSpecialInputsResponse.desktop1 != null)
            getSpecialInputsResponse.desktop1!,
          if (getSpecialInputsResponse.desktop2 != null)
            getSpecialInputsResponse.desktop2!,
          if (getSpecialInputsResponse.mic1 != null)
            getSpecialInputsResponse.mic1!,
          if (getSpecialInputsResponse.mic2 != null)
            getSpecialInputsResponse.mic2!,
          if (getSpecialInputsResponse.mic3 != null)
            getSpecialInputsResponse.mic3!,
          if (getSpecialInputsResponse.mic4 != null)
            getSpecialInputsResponse.mic4!,
        ]);

        break;
      case RequestType.GetInputKindList:
        GetInputKindListResponse getInputKindListResponse =
            GetInputKindListResponse(response.jsonRAW);
        this.inputKinds = getInputKindListResponse.inputKinds;
        break;
      case RequestType.GetInputVolume:
        GetInputVolumeResponse getInputVolumeResponse =
            GetInputVolumeResponse(response.jsonRAW);

        final requestData = NetworkHelper.requestBodyByUUID
            .remove(getInputVolumeResponse.uuid)!;

        Input input = allInputs
            .firstWhere((input) => input.inputName == requestData['inputName']);

        input.inputVolumeDb = getInputVolumeResponse.inputVolumeDb;
        input.inputVolumeMul = getInputVolumeResponse.inputVolumeMul;

        this.allInputs = ObservableList.of(this.allInputs);

        break;
      case RequestType.GetInputMute:
        GetInputMuteResponse getInputMuteResponse =
            GetInputMuteResponse(response.jsonRAW);

        final requestData = NetworkHelper.getRequestBodyForUUID(response.uuid)!;

        Input input = this
            .allInputs
            .firstWhere((input) => input.inputName == requestData['inputName']);

        input.inputMuted = getInputMuteResponse.inputMuted;

        this.allInputs = ObservableList.of(this.allInputs);
        break;
      case RequestType.GetSourceScreenshot:
        GetSourceScreenshotResponse getSourceScreenshotResponse =
            GetSourceScreenshotResponse(response.jsonRAW);

        this.scenePreviewImageBytes =
            base64Decode(getSourceScreenshotResponse.imageData.split(',')[1]);

        if (this.shouldRequestPreviewImage) _requestPreviewImage();
        break;
      default:
        break;
    }
  }

  @action
  Future<void> _handleBatchResponse(BaseBatchResponse batchResponse) async {
    if (batchResponse.batchRequestType != RequestBatchType.Stats) {
      GeneralHelper.advLog(
        'Batch Response Incoming: ${batchResponse.batchRequestType}',
      );
    }

    switch (batchResponse.batchRequestType) {
      case RequestBatchType.Stats:
        StatsBatchResponse statsBatchResponse =
            StatsBatchResponse(batchResponse.jsonRAW);

        this.latestOBSStats = statsBatchResponse.stats;

        /// Set the timestamps or recording and streaming according
        /// to the current status received by the batch
        this.latestRecordTimeDurationMS =
            _timecodeToMS(statsBatchResponse.recordStatus.outputTimecode);
        this.latestStreamTimeDurationMS =
            _timecodeToMS(statsBatchResponse.streamStatus.outputTimecode);

        this.isRecordingPaused =
            statsBatchResponse.recordStatus.ouputPaused ?? false;

        this.isRecording = this.isRecordingPaused
            ? true
            : statsBatchResponse.recordStatus.outputActive;

        bool previouslyLive = this.isLive;
        this.isLive = statsBatchResponse.streamStatus.outputActive;

        /// We were live and this batch request now indicates we are
        /// not live anymore - we can finish our stream statistic
        if (previouslyLive && !this.isLive) {
          _finishPastStreamData();
        }

        if (this.isLive) {
          if (this.streamData == null) {
            _manageStreamDataInit();
          }

          /// Make sure our temp value is lower than the actual bytes emitted
          /// (might not be the case when starting and stopping the stream
          /// multiple times in a session and the value of the response gets
          /// resetted)
          if (_streamBytes > statsBatchResponse.streamStatus.outputBytes) {
            _streamBytes = statsBatchResponse.streamStatus.outputBytes;
          }

          this.latestStreamStats = StreamStats(
            kbitsPerSec:
                (statsBatchResponse.streamStatus.outputBytes - _streamBytes) ~/
                    125,
            totalStreamTime: (_timecodeToMS(
                        statsBatchResponse.streamStatus.outputTimecode) ??
                    0) ~/
                1000,
            fps: statsBatchResponse.stats.activeFps,
            renderTotalFrames: statsBatchResponse.stats.renderTotalFrames,
            renderMissedFrames: statsBatchResponse.stats.renderSkippedFrames,
            outputTotalFrames:
                statsBatchResponse.streamStatus.outputTotalFrames,
            outputSkippedFrames:
                statsBatchResponse.streamStatus.outputSkippedFrames,
            averageFrameTime: statsBatchResponse.stats.averageFrameRenderTime,
            cpuUsage: statsBatchResponse.stats.cpuUsage,
            memoryUsage: statsBatchResponse.stats.memoryUsage,
            freeDiskSpace: statsBatchResponse.stats.availableDiskSpace,
          );

          /// Set temp bytes to current for next iteration to correctly caluclate
          /// kbits
          _streamBytes = statsBatchResponse.streamStatus.outputBytes;

          this.streamData!.addStreamStats(this.latestStreamStats!);
          await this.streamData!.save();
        }

        if (this.isRecording && !this.isRecordingPaused) {
          if (this.recordData == null) {
            _manageRecordDataInit();
          }

          /// Make sure our temp value is lower than the actual bytes emitted
          /// (might not be the case when starting and stopping the stream
          /// multiple times in a session and the value of the response gets
          /// resetted)
          if (_recordBytes > statsBatchResponse.recordStatus.outputBytes) {
            _recordBytes = statsBatchResponse.recordStatus.outputBytes;
          }

          this.latestRecordStats = RecordStats(
            kbitsPerSec:
                (statsBatchResponse.recordStatus.outputBytes - _streamBytes) ~/
                    125,
            totalRecordTime: (_timecodeToMS(
                        statsBatchResponse.recordStatus.outputTimecode) ??
                    0) ~/
                1000,
            fps: statsBatchResponse.stats.activeFps,
            renderTotalFrames: statsBatchResponse.stats.renderTotalFrames,
            renderMissedFrames: statsBatchResponse.stats.renderSkippedFrames,
            averageFrameTime: statsBatchResponse.stats.averageFrameRenderTime,
            cpuUsage: statsBatchResponse.stats.cpuUsage,
            memoryUsage: statsBatchResponse.stats.memoryUsage,
            freeDiskSpace: statsBatchResponse.stats.availableDiskSpace,
          );

          /// Set temp bytes to current for next iteration to correctly caluclate
          /// kbits
          _recordBytes = statsBatchResponse.recordStatus.outputBytes;

          this.recordData!.addRecordStats(this.latestRecordStats!);
          await this.recordData!.save();
        }
        break;
      case RequestBatchType.Input:
        InputsBatchResponse inputsBatchResponse =
            InputsBatchResponse(batchResponse.jsonRAW);

        final requestBatchObjects =
            NetworkHelper.getRequestBatchBodyForUUID(inputsBatchResponse.uuid)!;

        final validGetInputMuteRespones = inputsBatchResponse.inputsMute.where(
          (getInputMuteRespone) =>
              getInputMuteRespone.status.code !=
              RequestStatus.InvalidResourceState.identifier,
        );

        List<Map<String, dynamic>> muteObjects = [];
        List<Map<String, dynamic>> volumeObjects = [];

        for (final validGetInputMuteRespone in validGetInputMuteRespones) {
          for (final requestBatchObject in requestBatchObjects) {
            if (validGetInputMuteRespone.uuid == requestBatchObject.uuid) {
              muteObjects.add({
                'inputName': requestBatchObject.body!['inputName'],
                'response': validGetInputMuteRespone,
              });
              break;
            }
          }
        }

        for (final muteObject in muteObjects) {
          for (final requestBatchObject in requestBatchObjects) {
            if (requestBatchObject.type == RequestType.GetInputVolume &&
                muteObject['inputName'] ==
                    requestBatchObject.body!['inputName']) {
              volumeObjects.add({
                'inputName': requestBatchObject.body!['inputName'],
                'response': inputsBatchResponse.inputsVolume.firstWhere(
                    (getInputVolumeResponse) =>
                        getInputVolumeResponse.uuid == requestBatchObject.uuid),
              });
              break;
            }
          }
        }

        this.allInputs = ObservableList.of(this
            .allInputs
            .where((tempInput) => muteObjects.any(
                (muteObject) => muteObject['inputName'] == tempInput.inputName))
            .map((tempInput) {
          final muteObject = muteObjects.firstWhere(
              (muteObject) => muteObject['inputName'] == tempInput.inputName);

          final volumeObject = volumeObjects.firstWhere(
              (muteObject) => muteObject['inputName'] == tempInput.inputName);

          tempInput.inputVolumeDb =
              (volumeObject['response'] as GetInputVolumeResponse)
                  .inputVolumeDb;

          tempInput.inputVolumeMul =
              (volumeObject['response'] as GetInputVolumeResponse)
                  .inputVolumeMul;

          tempInput.inputMuted =
              (muteObject['response'] as GetInputMuteResponse).inputMuted;

          return tempInput;
        }));

        break;
    }
  }
}

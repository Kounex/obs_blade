import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/transition.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/base.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/filter_default_settings.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/filter_list.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/inputs.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/screenshot.dart';
import 'package:obs_blade/types/classes/stream/batch_responses/stats.dart';
import 'package:obs_blade/types/classes/stream/events/current_profile_changed.dart';
import 'package:obs_blade/types/classes/stream/events/input_mute_state_changed.dart';
import 'package:obs_blade/types/classes/stream/events/profile_list_changed.dart';
import 'package:obs_blade/types/classes/stream/events/replay_buffer_state_changed.dart';
import 'package:obs_blade/types/classes/stream/events/transition_duration_changed.dart';
import 'package:obs_blade/types/classes/stream/responses/get_input_audio_sync_offset.dart';
import 'package:obs_blade/types/classes/stream/responses/get_profile_list.dart';
import 'package:obs_blade/types/classes/stream/responses/get_record_directory.dart';
import 'package:obs_blade/types/classes/stream/responses/get_replay_buffer_status.dart';
import 'package:obs_blade/types/classes/stream/responses/get_scene_collection_list.dart';
import 'package:obs_blade/types/classes/stream/responses/get_source_filter_list.dart';
import 'package:obs_blade/types/classes/stream/responses/get_special_inputs.dart';
import 'package:obs_blade/types/enums/request_batch_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/types/extensions/int.dart';

import '../../models/enums/log_level.dart';
import '../../models/past_record_data.dart';
import '../../models/past_stream_data.dart';
import '../../types/classes/api/filter.dart';
import '../../types/classes/api/record_stats.dart';
import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/default_filter.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/current_preview_scene_changed.dart';
import '../../types/classes/stream/events/current_program_scene_changed.dart';
import '../../types/classes/stream/events/current_scene_collection_changed.dart';
import '../../types/classes/stream/events/input_audio_sync_offset_changed.dart';
import '../../types/classes/stream/events/input_volume_changed.dart';
import '../../types/classes/stream/events/input_volume_meters.dart';
import '../../types/classes/stream/events/scene_collection_list_changed.dart';
import '../../types/classes/stream/events/scene_item_enable_state_changed.dart';
import '../../types/classes/stream/events/source_filter_enable_state_changed.dart';
import '../../types/classes/stream/events/studio_mode_switched.dart';
import '../../types/classes/stream/events/virtual_cam_state_changed.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene_transition.dart';
import '../../types/classes/stream/responses/get_group_scene_item_list.dart';
import '../../types/classes/stream/responses/get_hotkey_list.dart';
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
import '../../types/classes/stream/responses/get_virtual_cam_status.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/general_helper.dart';
import '../../utils/network_helper.dart';
import '../../utils/overlay_handler.dart';
import '../shared/network.dart';

part 'dashboard.g.dart';

int kMinimumTotalTimeForStatisticInS = 10;

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
  bool isVirtualCamActive = false;
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
  String? currentProfileName;
  @observable
  ObservableList<String>? profiles;
  @observable
  String? activeSceneName;
  @observable
  ObservableList<Scene>? scenes;
  @observable
  ObservableSet<Hotkey>? hotkeys;

  /// WebSocket API will return all top level scene items for
  /// the current scene and elements of groups have to be requested
  /// seperately. To better maintain and work with scene items, I
  /// flatten these so all scene items, even the children of groups
  /// are on top level and a custom [SceneItem.displayGroup] propertry
  /// toggles whether they will be displayed or not, but this makes
  /// searching and updating scene items easier
  @observable
  ObservableList<SceneItem> currentSceneItems = ObservableList();

  @computed
  ObservableList<SceneItem> get mediaSceneItems =>
      ObservableList.of(this.currentSceneItems.where((sceneItem) =>
          (sceneItem.inputKind?.toLowerCase().contains('ffmpeg') ?? false) &&
          (sceneItem.sceneItemEnabled ?? false)));

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

  /// Users can take screenshots of their current OBS scene manually. If they
  /// do, the screenshot will be saved on their system where OBS is running and
  /// we will get the taken screenshot as a response
  @observable
  Uint8List? manualScreenshotImageBytes;

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

  @computed
  String get screenshotPath =>
      '${this.recordDirectory}/Screenshot ${DateTime.now().millisecondsSinceEpoch.millisecondsToFileNameDate(separator: "-", withTime: true)}.${this.screenshotFileFormat}';

  String previewFileFormat = 'jpeg';
  String screenshotFileFormat = 'png';
  String? recordDirectory;

  Timer? _checkConnectionTimer;
  Timer? _getStatsTimer;

  /// Will be used internally while switching scene collections.
  /// Since this operation takes time and "random" events are coming
  /// in while we dont even have all the new information from the
  /// new scene collection, we need to stop handling those events /requests
  /// while waiting until we actually changed the scene collection
  /// (getting the response from [SetCurrentSceneCollection]) and then
  /// call [sceneCollectionRequests]
  bool _handleRequestsEvents = true;

  /// Bytes output of the stream - emitted by GetStreamStatus and will
  /// be used as the previous temp value to calculate kbit/s
  int _streamBytes = 0;

  /// Bytes output of the record - emitted by GetRecordStatus and will
  /// be used as the previous temp value to calculate kbit/s
  int _recordBytes = 0;

  /// The amount of render frames (in total and skipped) are part of the
  /// general OBS stats and not bound to stream / record. To know the amount
  /// of these in our stream / recording session, we will persist the latest
  /// amount as received by the general OBS stats and subtract this for all
  /// new values so we have only the new amounts which came in while streaming
  /// recording
  int _streamStartedRenderFramesTotal = 0;
  int _streamStartedRenderFramesSkipped = 0;

  int _recordingStartedRenderFramesTotal = 0;
  int _recordingStartedRenderFramesSkipped = 0;

  final List<DefaultFilter> _defaultFilters = [];

  /// Set of initial requests to call in order to get all the basic
  /// information / configuration for the OBS session
  void initialRequests() {
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetVersion,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetRecordDirectory,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetSceneCollectionList,
    );
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetProfileList,
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
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetVirtualCamStatus,
    );

    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.GetHotkeyList,
    );

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
      RequestType.GetSceneTransitionList,
    );
  }

  void handleStream() {
    GetIt.instance<NetworkStore>().watchOBSStream().listen((message) {
      try {
        if (_handleRequestsEvents ||
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
    _getStatsTimer?.cancel();
    _getStatsTimer = Timer.periodic(
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
    /// set later than current time - [totalTime] which means that we
    /// connected to an OBS session we already were connected to
    if (tmp.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestStreamStats!.totalTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.streamData = tmp.last;
    } else {
      this.streamData = PastStreamData();
      await pastStreamDataBox.add(this.streamData!);
    }
  }

  /// If we are recording and have no [PastRecordData]
  /// instance (null) we need to check if we create a completely new
  /// instance (indicating new recording) or we use the last one since it
  /// seems as this is the same recording we already were connected to
  Future<void> _manageRecordDataInit() async {
    Box<PastRecordData> pastRecordDataBox =
        Hive.box<PastRecordData>(HiveKeys.PastRecordData.name);
    List<PastRecordData> tmp = pastRecordDataBox.values.toList();

    /// Sort ascending so the last entry is the latest stream
    tmp.sort((a, b) => a.listEntryDateMS.last - b.listEntryDateMS.last);

    /// Check if the latest recording has its last entry (based on [listEntryDateMS]
    /// set later than current time - [totalTime] which means that we
    /// connected to an OBS session we already were connected to
    if (tmp.isNotEmpty &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestRecordStats!.totalTime * 1000 <=
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
      /// Check if [streamData] is even "legit" - if [totalTime]
      /// is not greater than [kMinimumTotalTimeForStatisticInS], it's not worth
      /// the statistic entry and will probably cause problems anyway. We will
      /// delete it therefore
      if (this.streamData!.isInBox &&
          (this.streamData!.totalTime == null ||
              this.streamData!.totalTime! < kMinimumTotalTimeForStatisticInS)) {
        await this.streamData!.delete();
      }
      this.streamData = null;
      this.latestStreamStats = null;
    }
  }

  /// Check if we have ongoing statistics (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> _finishPastRecordData() async {
    if (this.recordData != null) {
      /// Check if [recordData] is even "legit" - if [totalTime]
      /// is not greater than [kMinimumTotalTimeForStatisticInS], it's not worth
      /// the statistic entry and will probably cause problems anyway. We will
      /// delete it therefore
      if (this.recordData!.isInBox &&
          (this.recordData!.totalTime == null ||
              this.recordData!.totalTime! < kMinimumTotalTimeForStatisticInS)) {
        await this.recordData!.delete();
      }
      this.recordData = null;
      this.latestRecordStats = null;
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

  /// Here we need to drill down to every single FilterSetting of every [Filter]
  /// a [SceneItem] can have and check if the values in those have been updated
  /// (which means the corresponding FilterSetting in [filterObjects] has a
  /// different value)
  bool _filterSettingsUnchanged(List<Map<String, dynamic>> filterObjects) =>
      this.currentSceneItems.every((sceneItem) {
        final filterObject = filterObjects.firstWhere((filterObject) =>
            filterObject['sourceName'] == sceneItem.sourceName);

        if (sceneItem.filters.length !=
            (filterObject['response'] as GetSourceFilterListResponse)
                .filters
                .length) {
          return false;
        }

        return sceneItem.filters.every((filter) {
          final responseFilter =
              (filterObject['response'] as GetSourceFilterListResponse)
                  .filters
                  .firstWhere((responseFilter) =>
                      responseFilter.filterName == filter.filterName);

          if (filter.filterSettings.length !=
              responseFilter.filterSettings.length) {
            return false;
          }

          return filter.filterSettings.entries.every((filterSetting) {
            return filterSetting.value ==
                responseFilter.filterSettings.entries
                    .firstWhere((responseFilterSetting) =>
                        responseFilterSetting.key == filterSetting.key)
                    .value;
          });
        });
      });

  /// Currently (hopefully fixed someday) not all [Filter]s have default
  /// FilterSettings... some are just empty. To have a consistent experience
  /// with this circumstance, we need to remove FilterSettings which have
  /// been set back to a default value and we just don't have that default
  /// value
  void _removeEmptyDefaultFilterSettings(
    Map<String, dynamic> filterSettings,
    Map<String, dynamic> responseFilterSettings,
    Filter filter,
  ) {
    final defaultFilter = _defaultFilters.firstWhere(
        (defaultFilter) => defaultFilter.filterKind == filter.filterKind);

    filterSettings.removeWhere((key, value) =>
        (!responseFilterSettings.containsKey(key) &&
            !defaultFilter.filterSettings.containsKey(key)));
  }

  Filter _populateFiltersWithDefaults(Filter filter) {
    try {
      final defaultFilterSettings = _defaultFilters
          .firstWhere(
              (defaultFilter) => defaultFilter.filterKind == filter.filterKind)
          .filterSettings;

      final filterSettings = <String, dynamic>{}..addAll(filter.filterSettings);

      /// Other than in the update request for our [Filter]s, where we
      /// use the update function on map, we will use the putIfAbsent
      /// since we only want to add a default value when there is no
      /// other present because otherwise the changed value is the
      /// correct one.
      for (final defaultFilterSetting in defaultFilterSettings.entries) {
        filterSettings.putIfAbsent(
            defaultFilterSetting.key, () => defaultFilterSetting.value);
      }

      return filter.copyWith(filterSettings: filterSettings);
    } catch (_) {
      return filter;
    }
  }

  void stopTimers() {
    _getStatsTimer?.cancel();
    _checkConnectionTimer?.cancel();
  }

  void fetchSceneItemsFilters() => NetworkHelper.makeBatchRequest(
        GetIt.instance<NetworkStore>().activeSession!.socket,
        RequestBatchType.FilterList,
        this
            .currentSceneItems
            .map(
              (sceneItem) => RequestBatchObject(
                RequestType.GetSourceFilterList,
                {'sourceName': sceneItem.sourceName},
              ),
            )
            .toList(),
      );

  @action
  void init() {
    this.handleStream();
    this.initialRequests();

    /// Since [setupNetworkStoreHandling] gets called as soon as we connect
    /// to an OBS instance, we trigger this [Timer] which will check if
    /// the connection is still alive periodically - see [_checkOBSConnection]
    /// for more information_checkConnectionTimer
    _checkConnectionTimer?.cancel();
    _checkConnectionTimer = Timer(
      const Duration(seconds: 5),
      () => _checkOBSConnection(),
    );

    _periodicStatsRequest();
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
        _checkConnectionTimer?.cancel();
        _checkConnectionTimer = Timer(
          const Duration(seconds: 3),
          () => _checkOBSConnection(),
        );
      }
    } else {
      _checkConnectionTimer?.cancel();
      _checkConnectionTimer = Timer(
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
    this.currentSceneItems =
        ObservableList.of(this.currentSceneItems.map((currentSceneItem) {
      if (currentSceneItem == sceneItem) {
        return currentSceneItem.copyWith(
          displayGroup: !sceneItem.displayGroup,
        );
      }
      return currentSceneItem;
    }));
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
      if (event.eventType != EventType.InputVolumeMeters) {
        GeneralHelper.advLog(
          'Event Incoming: ${event.eventType}',
        );
      }
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
          OverlayHandler.closeAnyOverlay();
        }
        break;
      case EventType.VirtualcamStateChanged:
        VirtualCamStateChangedEvent virtualCamStateChangedEvent =
            VirtualCamStateChangedEvent(event.jsonRAW);
        this.isVirtualCamActive = virtualCamStateChangedEvent.outputActive;
        break;
      case EventType.CurrentSceneCollectionChanging:
        _handleRequestsEvents = false;
        break;
      case EventType.CurrentSceneCollectionChanged:
        CurrentSceneCollectionChangedEvent currentSceneCollectionChangedEvent =
            CurrentSceneCollectionChangedEvent(event.jsonRAW);

        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.GetSceneCollectionList,
        );

        OverlayHandler.closeAnyOverlay();

        this.currentSceneCollectionName =
            currentSceneCollectionChangedEvent.sceneCollectionName;

        _handleRequestsEvents = true;
        _sceneCollectionRequests();
        break;
      case EventType.SceneCollectionListChanged:
        SceneCollectionListChangedEvent sceneCollectionListChangedEvent =
            SceneCollectionListChangedEvent(event.jsonRAW);

        this.sceneCollections =
            ObservableList.of(sceneCollectionListChangedEvent.sceneCollections);

        break;
      case EventType.CurrentProfileChanged:
        CurrentProfileChangedEvent currentProfileChangedEvent =
            CurrentProfileChangedEvent(event.jsonRAW);

        this.currentProfileName = currentProfileChangedEvent.profileName;
        break;
      case EventType.ProfileListChanged:
        ProfileListChangedEvent profileListChangedEvent =
            ProfileListChangedEvent(event.jsonRAW);

        this.profiles = ObservableList.of(profileListChangedEvent.profiles);

        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.GetSceneList,
        );
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

        this.currentTransition = this.currentTransition?.copyWith(
            transitionDuration:
                currentSceneTransitionDurationChangedEvent.transitionDuration);
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

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == inputVolumeChangedEvent.inputName) {
            return input.copyWith(
              inputVolumeMul: inputVolumeChangedEvent.inputVolumeMul,
              inputVolumeDb: inputVolumeChangedEvent.inputVolumeDb,
            );
          }
          return input;
        }));

        break;
      case EventType.InputVolumeMeters:
        InputVolumeMetersEvent inputVolumeMetersEvent =
            InputVolumeMetersEvent(event.jsonRAW);

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          try {
            InputLevel inputLevel = inputVolumeMetersEvent.inputs.firstWhere(
                (inputLevel) => inputLevel.inputName == input.inputName);

            if (input.inputName == inputLevel.inputName) {
              return input.copyWith(inputLevelsMul: inputLevel.inputLevelsMul);
            }
          } catch (e) {}

          return input;
        }));

        break;
      case EventType.InputMuteStateChanged:
        InputMuteStateChangedEvent inputMuteStateChangedEvent =
            InputMuteStateChangedEvent(event.jsonRAW);

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == inputMuteStateChangedEvent.inputName) {
            return input.copyWith(
              inputMuted: inputMuteStateChangedEvent.inputMuted,
            );
          }
          return input;
        }));

        break;
      case EventType.SceneItemEnableStateChanged:
        SceneItemEnableStateChangedEvent sceneItemEnableStateChangedEvent =
            SceneItemEnableStateChangedEvent(event.jsonRAW);

        this.currentSceneItems =
            ObservableList.of(this.currentSceneItems.map((sceneItem) {
          if (sceneItem.sceneItemId ==
              sceneItemEnableStateChangedEvent.sceneItemId) {
            return sceneItem.copyWith(
              sceneItemEnabled:
                  sceneItemEnableStateChangedEvent.sceneItemEnabled,
            );
          }
          return sceneItem;
        }));
        break;
      case EventType.InputAudioSyncOffsetChanged:
        InputAudioSyncOffsetChangedEvent inputAudioSyncOffsetChangedEvent =
            InputAudioSyncOffsetChangedEvent(event.jsonRAW);

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == inputAudioSyncOffsetChangedEvent.inputName) {
            return input.copyWith(
              syncOffset: inputAudioSyncOffsetChangedEvent.inputAudioSyncOffset,
            );
          }
          return input;
        }));

        break;

      case EventType.SourceFilterEnableStateChanged:
        SourceFilterEnableStateChangedEvent
            sourceFilterEnableStateChangedEvent =
            SourceFilterEnableStateChangedEvent(event.jsonRAW);

        this.currentSceneItems = ObservableList.of(
          this.currentSceneItems.map((sceneItem) {
            if ((sceneItem.filters.isNotEmpty) &&
                sceneItem.sourceName ==
                    sourceFilterEnableStateChangedEvent.sourceName) {
              return sceneItem.copyWith(
                  filters: sceneItem.filters.map((filter) {
                if (filter.filterName ==
                    sourceFilterEnableStateChangedEvent.filterName) {
                  return filter.copyWith(
                    filterEnabled:
                        sourceFilterEnableStateChangedEvent.filterEnabled,
                  );
                }
                return filter;
              }).toList());
            }
            return sceneItem;
          }),
        );
        break;
      case EventType.ExitStarted:
        await _finishPastStreamData();
        await _finishPastRecordData();
        this.stopTimers();
        GetIt.instance<NetworkStore>().obsTerminated = true;
        break;
      default:
        break;
    }
  }

  @action
  void _handleResponse(BaseResponse response) {
    if (response.requestType != RequestType.GetSourceScreenshot) {
      GeneralHelper.advLog(
        'Response Incoming: ${(response.requestType)}',
      );
    }

    switch (response.requestType) {
      case RequestType.GetVersion:
        GetVersionResponse getVersionResponse =
            GetVersionResponse(response.jsonRAW);

        if (!getVersionResponse.supportedImageFormats.contains('jpg') &&
            !getVersionResponse.supportedImageFormats.contains('jpeg')) {
          this.previewFileFormat = 'png';
        }

        if (!getVersionResponse.supportedImageFormats.contains('png')) {
          this.screenshotFileFormat = this.previewFileFormat;
        }
        break;
      case RequestType.GetRecordDirectory:
        GetRecordDirectoryResponse getRecordDirectoryResponse =
            GetRecordDirectoryResponse(response.jsonRAW);

        this.recordDirectory = getRecordDirectoryResponse.recordDirectory;
        break;
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.jsonRAW);

        this.activeSceneName = getSceneListResponse.currentProgramSceneName;
        this.studioModePreviewSceneName =
            getSceneListResponse.currentPreviewSceneName;
        this.scenes = ObservableList.of([...getSceneListResponse.scenes]
          ..sort((a, b) => b.sceneIndex - a.sceneIndex));

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

      case RequestType.GetProfileList:
        GetProfileListResponse getProfileListResponse =
            GetProfileListResponse(response.jsonRAW);

        this.profiles = ObservableList.of(getProfileListResponse.profiles);

        this.currentProfileName = getProfileListResponse.currentProfileName;
        break;
      case RequestType.GetSceneItemList:
        GetSceneItemListResponse getSceneItemListResponse =
            GetSceneItemListResponse(response.jsonRAW);

        this.currentSceneItems =
            ObservableList.of(getSceneItemListResponse.sceneItems)
              ..sort((sc1, sc2) =>
                  (sc2.sceneItemIndex ?? 0) - (sc1.sceneItemIndex ?? 0));

        this.fetchSceneItemsFilters();

        for (final sceneItem in this.currentSceneItems) {
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
            getGroupSceneItemListResponse.sceneItems
                .map(
                  (sceneItem) =>
                      sceneItem.copyWith(parentGroupName: parentSceneItemName),
                )
                .toList();

        this.currentSceneItems = ObservableList.of([
          ...this.currentSceneItems
            ..insertAll(
                this.currentSceneItems.indexOf(
                          this.currentSceneItems.firstWhere((sceneItem) =>
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
                RequestType.GetInputVolume,
                {'inputName': input.inputName},
              ),
              RequestBatchObject(
                RequestType.GetInputMute,
                {'inputName': input.inputName},
              ),
              RequestBatchObject(
                RequestType.GetInputAudioSyncOffset,
                {'inputName': input.inputName},
              ),
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
            getReplayBufferStatusResponse.isReplayBufferActive ?? false;

        break;
      case RequestType.GetVirtualCamStatus:
        GetVirtualCamStatusResponse getVirtualCamStatusResponse =
            GetVirtualCamStatusResponse(response.jsonRAW);

        this.isVirtualCamActive = getVirtualCamStatusResponse.outputActive;

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
      case RequestType.GetInputVolume:
        GetInputVolumeResponse getInputVolumeResponse =
            GetInputVolumeResponse(response.jsonRAW);

        final requestData =
            NetworkHelper.getRequestBodyForUUID(getInputVolumeResponse.uuid)!;

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == requestData['inputName']) {
            return input.copyWith(
              inputVolumeDb: getInputVolumeResponse.inputVolumeDb,
              inputVolumeMul: getInputVolumeResponse.inputVolumeMul,
            );
          }
          return input;
        }));

        break;
      case RequestType.GetInputMute:
        GetInputMuteResponse getInputMuteResponse =
            GetInputMuteResponse(response.jsonRAW);

        final requestData = NetworkHelper.getRequestBodyForUUID(response.uuid)!;

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == requestData['inputName']) {
            return input.copyWith(inputMuted: getInputMuteResponse.inputMuted);
          }
          return input;
        }));
        break;
      case RequestType.GetInputAudioSyncOffset:
        GetInputAudioSyncOffsetResponse getInputAudioSyncOffsetResponse =
            GetInputAudioSyncOffsetResponse(response.jsonRAW);

        final requestData = NetworkHelper.getRequestBodyForUUID(response.uuid)!;

        this.allInputs = ObservableList.of(this.allInputs.map((input) {
          if (input.inputName == requestData['inputName']) {
            return input.copyWith(
              syncOffset: getInputAudioSyncOffsetResponse.inputAudioSyncOffset,
            );
          }
          return input;
        }));
        break;
      case RequestType.GetSourceScreenshot:
        GetSourceScreenshotResponse getSourceScreenshotResponse =
            GetSourceScreenshotResponse(response.jsonRAW);

        this.scenePreviewImageBytes =
            base64Decode(getSourceScreenshotResponse.imageData.split(',')[1]);

        if (this.shouldRequestPreviewImage) _requestPreviewImage();
        break;
      // case RequestType.SaveSourceScreenshot:
      //   SaveSourceScreenshotResponse saveSourceScreenshotResponse =
      //       SaveSourceScreenshotResponse(response.jsonRAW);

      //   this.manualScreenshotImageBytes =
      //       base64Decode(saveSourceScreenshotResponse.imageData.split(',')[1]);
      //   break;
      case RequestType.GetHotkeyList:
        GetHotkeyListResponse getHotkeyListResponse =
            GetHotkeyListResponse(response.jsonRAW);

        this.hotkeys = ObservableSet.of(
          Set.of(getHotkeyListResponse.hotkeys).map(
            (name) => Hotkey(name),
          ),
        );
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
            statsBatchResponse.recordStatus.outputPaused ?? false;

        bool previouslyRecording = this.isRecording;
        this.isRecording = this.isRecordingPaused
            ? true
            : statsBatchResponse.recordStatus.outputActive;

        /// We were recording and this batch request now indicates we are
        /// not recording anymore - we can finish our recording statistic
        if (previouslyRecording && !this.isRecording) {
          _finishPastRecordData();
        }

        bool previouslyLive = this.isLive;
        this.isLive = statsBatchResponse.streamStatus.outputActive;

        /// We were live and this batch request now indicates we are
        /// not live anymore - we can finish our stream statistic
        if (previouslyLive && !this.isLive) {
          _finishPastStreamData();
        }

        if (this.isLive) {
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
            totalTime: (_timecodeToMS(
                        statsBatchResponse.streamStatus.outputTimecode) ??
                    0) ~/
                1000,
            fps: statsBatchResponse.stats.activeFps,
            renderTotalFrames: statsBatchResponse.stats.renderTotalFrames -
                _streamStartedRenderFramesTotal,
            renderSkippedFrames: statsBatchResponse.stats.renderSkippedFrames -
                _streamStartedRenderFramesSkipped,
            outputTotalFrames:
                statsBatchResponse.streamStatus.outputTotalFrames,
            outputSkippedFrames:
                statsBatchResponse.streamStatus.outputSkippedFrames,
            averageFrameTime: statsBatchResponse.stats.averageFrameRenderTime,
            cpuUsage: statsBatchResponse.stats.cpuUsage,
            memoryUsage: statsBatchResponse.stats.memoryUsage,
            freeDiskSpace: statsBatchResponse.stats.availableDiskSpace,
          );

          if (this.streamData == null) {
            _manageStreamDataInit();
          }

          /// Set temp bytes to current for next iteration to correctly caluclate
          /// kbits
          _streamBytes = statsBatchResponse.streamStatus.outputBytes;

          this.streamData!.addStreamStats(this.latestStreamStats!);
          await this.streamData!.save();
        } else {
          /// While we are not streaming, we set the render data to the current
          /// value as exposed by the general OBS stats wo when we start to
          /// stream, we can subtract this value by all upcoming stats so
          /// we have the ones which have been generated while streaming
          _streamStartedRenderFramesTotal =
              statsBatchResponse.stats.renderTotalFrames;
          _streamStartedRenderFramesSkipped =
              statsBatchResponse.stats.renderSkippedFrames;
        }

        if (this.isRecording && !this.isRecordingPaused) {
          /// Make sure our temp value is lower than the actual bytes emitted
          /// (might not be the case when starting and stopping the stream
          /// multiple times in a session and the value of the response gets
          /// resetted)
          if (_recordBytes > statsBatchResponse.recordStatus.outputBytes) {
            _recordBytes = statsBatchResponse.recordStatus.outputBytes;
          }

          this.latestRecordStats = RecordStats(
            kbitsPerSec:
                (statsBatchResponse.recordStatus.outputBytes - _recordBytes) ~/
                    125,
            totalTime: (_timecodeToMS(
                        statsBatchResponse.recordStatus.outputTimecode) ??
                    0) ~/
                1000,
            fps: statsBatchResponse.stats.activeFps,
            renderTotalFrames: statsBatchResponse.stats.renderTotalFrames -
                _recordingStartedRenderFramesTotal,
            renderSkippedFrames: statsBatchResponse.stats.renderSkippedFrames -
                _recordingStartedRenderFramesSkipped,
            outputTotalFrames: statsBatchResponse.stats.outputTotalFrames,
            outputSkippedFrames: statsBatchResponse.stats.outputSkippedFrames,
            averageFrameTime: statsBatchResponse.stats.averageFrameRenderTime,
            cpuUsage: statsBatchResponse.stats.cpuUsage,
            memoryUsage: statsBatchResponse.stats.memoryUsage,
            freeDiskSpace: statsBatchResponse.stats.availableDiskSpace,
          );

          if (this.recordData == null) {
            _manageRecordDataInit();
          }

          /// Set temp bytes to current for next iteration to correctly caluclate
          /// kbits
          _recordBytes = statsBatchResponse.recordStatus.outputBytes;

          this.recordData!.addRecordStats(this.latestRecordStats!);
          await this.recordData!.save();
        } else {
          /// While we are not recording, we set the render data to the current
          /// value as exposed by the general OBS stats wo when we start to
          /// record, we can subtract this value by all upcoming stats so
          /// we have the ones which have been generated while recording
          _recordingStartedRenderFramesTotal =
              statsBatchResponse.stats.renderTotalFrames;
          _recordingStartedRenderFramesSkipped =
              statsBatchResponse.stats.renderSkippedFrames;
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
        List<Map<String, dynamic>> syncOffsetObjects = [];

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

        for (final muteObject in muteObjects) {
          for (final requestBatchObject in requestBatchObjects) {
            if (requestBatchObject.type ==
                    RequestType.GetInputAudioSyncOffset &&
                muteObject['inputName'] ==
                    requestBatchObject.body!['inputName']) {
              syncOffsetObjects.add({
                'inputName': requestBatchObject.body!['inputName'],
                'response': inputsBatchResponse.inputsAudioSyncOffset
                    .firstWhere((getInputAudioSyncOffset) =>
                        getInputAudioSyncOffset.uuid ==
                        requestBatchObject.uuid),
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

          final volumeObject = volumeObjects.firstWhere((volumeObject) =>
              volumeObject['inputName'] == tempInput.inputName);

          final syncOffsetObject = syncOffsetObjects.firstWhere(
              (syncOffsetObject) =>
                  syncOffsetObject['inputName'] == tempInput.inputName);

          tempInput = tempInput.copyWith(
            inputVolumeDb: (volumeObject['response'] as GetInputVolumeResponse)
                .inputVolumeDb,
            inputVolumeMul: (volumeObject['response'] as GetInputVolumeResponse)
                .inputVolumeMul,
            inputMuted:
                (muteObject['response'] as GetInputMuteResponse).inputMuted,
            syncOffset: (syncOffsetObject['response']
                    as GetInputAudioSyncOffsetResponse)
                .inputAudioSyncOffset,
          );

          return tempInput;
        }));

        break;
      case RequestBatchType.Screenshot:
        ScreenshotBatchResponse screenshotBatchResponse =
            ScreenshotBatchResponse(batchResponse.jsonRAW);

        this.manualScreenshotImageBytes = base64Decode(screenshotBatchResponse
            .getSourceScreenshotResponse.imageData
            .split(',')[1]);
        break;

      case RequestBatchType.FilterList:
        FilterListBatchResponse filterListBatchResponse =
            FilterListBatchResponse(batchResponse.jsonRAW);
        final requestBatchObjects = NetworkHelper.getRequestBatchBodyForUUID(
            filterListBatchResponse.uuid)!;

        List<Map<String, dynamic>> filterObjects = [];

        for (final getSourceFilterListResponse
            in filterListBatchResponse.filterLists) {
          for (final requestBatchObject in requestBatchObjects) {
            if (getSourceFilterListResponse.uuid == requestBatchObject.uuid) {
              filterObjects.add({
                'sourceName': requestBatchObject.body!['sourceName'],
                'response': getSourceFilterListResponse,
              });
            }
          }
        }

        /// We only want to update our [currentSceneItems] when we actually have
        /// new values in our FilterSettings of our [Filters] to avoid possible
        /// UI rebuilds
        if (!_filterSettingsUnchanged(filterObjects)) {
          this.currentSceneItems = ObservableList.of(
            this.currentSceneItems.map((sceneItem) {
              final filterObject = filterObjects.firstWhere((filterObject) =>
                  filterObject['sourceName'] == sceneItem.sourceName);

              final List<Filter> responseFilters =
                  (filterObject['response'] as GetSourceFilterListResponse)
                      .filters;

              /// Our existing [Filter]s are the leading information. Since the
              /// the order is: first getting all [Filter]s of a [SceneItem]
              /// which will only expose the FilterSettings of non-default values
              /// and then (since we now have the [filterKind]s) we fetch the
              /// default FilterSettings of these.
              List<Filter> filters = [...sceneItem.filters];

              /// If this is the first time we fetch the current [Filter]s or we
              /// have new ones or some were deleted, we can just add them since
              /// there are no default ones.
              if (filters.length != responseFilters.length) {
                filters = [];
                filters
                    .addAll(responseFilters.map(_populateFiltersWithDefaults));
              } else {
                /// We handle this case if this is a subsequent fetch and our
                /// [Filter]s are already populated. Here we need to make sure
                /// to find the correct corresponding FilterSetting of our response
                /// and update our existing ones.
                filters = filters.map((filter) {
                  final responseFilterSettings = responseFilters
                      .firstWhere((responseFilter) =>
                          responseFilter.filterKind == filter.filterKind)
                      .filterSettings;

                  final filterSettings = <String, dynamic>{}
                    ..addAll(filter.filterSettings);

                  _removeEmptyDefaultFilterSettings(
                    filterSettings,
                    responseFilterSettings,
                    filter,
                  );

                  for (final responseFilterSetting
                      in responseFilterSettings.entries) {
                    filterSettings.update(
                      responseFilterSetting.key,
                      (_) => responseFilterSetting.value,
                      ifAbsent: () => responseFilterSetting.value,
                    );
                  }

                  return filter.copyWith(filterSettings: filterSettings);
                }).toList();
              }
              filters.sort((a, b) => a.filterIndex - b.filterIndex);

              return sceneItem.copyWith(filters: filters);
            }),
          );
        }

        /// Since this request is used for updating our FilterSettings but is
        /// also the first one to call without having one before, we need
        /// to check that. We basically check if we already have the
        /// default values for the [Filter]s we have active. If that is
        /// the case, we don't need to get these and therefore don't update
        /// our [Filter]s. If not done yet or we just got a new [Filter], we
        /// will make an additional batch request (see below)
        Set<String> filterKinds = {};

        for (final sceneItem in this.currentSceneItems) {
          for (final filter in sceneItem.filters) {
            if (!_defaultFilters.any((defaultFilter) =>
                defaultFilter.filterKind == filter.filterKind)) {
              filterKinds.add(filter.filterKind);
            }
          }
        }

        if (filterKinds.isNotEmpty) {
          NetworkHelper.makeBatchRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestBatchType.FilterDefaultSettings,
            filterKinds
                .map(
                  (filterKind) => RequestBatchObject(
                      RequestType.GetSourceFilterDefaultSettings, {
                    'filterKind': filterKind,
                  }),
                )
                .toList(),
          );
        }
        break;
      case RequestBatchType.FilterDefaultSettings:
        FilterDefaultSettingsResponse filterDefaultSettingsResponse =
            FilterDefaultSettingsResponse(batchResponse.jsonRAW);
        final requestBatchObjects = NetworkHelper.getRequestBatchBodyForUUID(
            filterDefaultSettingsResponse.uuid)!;

        for (final getSourceFilterDefaultSettingsResponse
            in filterDefaultSettingsResponse.defaultSettings) {
          for (final requestBatchObject in requestBatchObjects) {
            if (getSourceFilterDefaultSettingsResponse.uuid ==
                    requestBatchObject.uuid &&
                !_defaultFilters.any((defaultFilter) =>
                    defaultFilter.filterKind ==
                    requestBatchObject.body!['filterKind'])) {
              _defaultFilters.add(
                DefaultFilter(
                  requestBatchObject.body!['filterKind'],
                  getSourceFilterDefaultSettingsResponse.defaultFilterSettings,
                ),
              );
            }
          }
        }

        this.currentSceneItems = ObservableList.of(
          this.currentSceneItems.map(
                (sceneItem) => sceneItem.copyWith(
                  filters: sceneItem.filters
                      .map(_populateFiltersWithDefaults)
                      .toList(),
                ),
              ),
        );

        break;
    }
  }
}

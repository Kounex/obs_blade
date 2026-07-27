/// Foundational mock data for Hive persistence tests.
///
/// Values are intentionally self-explanatory from field names alone
/// (e.g. a [Connection] named `Living Room PC` uses host `192.168.1.50`).
/// Sizes are large enough to stress adapters/lists without slowing CI.
library;

import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/models/hidden_scene.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/models/purchased_tip.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// Stable epoch so fixtures are deterministic across runs.
const int kFixtureEpochMs = 1700000000000; // 2023-11-14T22:13:20Z

class FixtureCounts {
  static const connections = 12;
  static const pastStreams = 24;
  static const pastRecords = 18;
  static const themes = 8;
  static const hiddenScenes = 16;
  static const hiddenSceneItems = 32;
  static const appLogs = 120;
  static const purchasedTips = 6;
  static const hotkeys = 24;

  /// Chart samples per past stream/record (lists used for statistics UI).
  static const chartSamplesPerSession = 48;
}

/// All typed HiveObject seeds used to populate production box names.
class HiveFoundationData {
  HiveFoundationData();

  late final List<Connection> connections = buildConnections();
  late final List<PastStreamData> pastStreams = buildPastStreams();
  late final List<PastRecordData> pastRecords = buildPastRecords();
  late final List<CustomTheme> themes = buildThemes();
  late final List<HiddenScene> hiddenScenes = buildHiddenScenes();
  late final List<HiddenSceneItem> hiddenSceneItems = buildHiddenSceneItems();
  late final List<AppLog> appLogs = buildAppLogs();
  late final List<PurchasedTip> purchasedTips = buildPurchasedTips();
  late final List<Hotkey> hotkeys = buildHotkeys();
  late final Map<String, dynamic> settings = buildSettings(themes.first.uuid);

  static List<Connection> buildConnections() => [
        Connection('192.168.1.50', 4455, 'living-room-pw', false)
          ..name = 'Living Room PC'
          ..ssid = 'HomeWiFi-5G',
        Connection('192.168.1.51', 4455, null, false)
          ..name = 'Office Mini-PC (no password)'
          ..ssid = 'HomeWiFi-5G',
        Connection('10.0.0.12', 4455, 'basement-stream', false)
          ..name = 'Basement Streaming Rig'
          ..ssid = 'IoT-VLAN',
        Connection('192.168.0.20', 4456, 'alt-port-secret', false)
          ..name = 'Laptop Dock (custom port 4456)'
          ..ssid = 'CafeGuest',
        Connection('obs.example.lan', 4455, 'lan-dns-pw', true)
          ..name = 'LAN DNS alias (isDomain=true)'
          ..ssid = 'HomeWiFi-5G',
        Connection('stream.kounex.com', 443, 'remote-tls-ish', true)
          ..name = 'Remote domain (stream.kounex.com)'
          ..ssid = null,
        Connection('192.168.1.60', null, 'default-port-pw', false)
          ..name = 'Null port (client default)'
          ..ssid = 'HomeWiFi-2G',
        Connection('172.16.4.8', 4455, '', false)
          ..name = 'Empty password string'
          ..ssid = 'LabNet',
        Connection('192.168.1.70', 4455, 'tablet-obs', false)
          ..name = 'iPad Companion Target'
          ..ssid = 'HomeWiFi-5G',
        Connection('192.168.1.80', 4455, 'secondary', false)
          ..name = 'Backup Encoder NUC'
          ..ssid = 'HomeWiFi-5G',
        Connection('obs-main.local', 4455, 'mdns-pw', true)
          ..name = 'mDNS host obs-main.local'
          ..ssid = 'HomeWiFi-5G',
        Connection('203.0.113.10', 4455, 'docs-net-pw', false)
          ..name = 'Documentation NET (203.0.113.10)'
          ..ssid = null,
      ];

  static List<PastStreamData> buildPastStreams() {
    final sessions = <PastStreamData>[];
    for (var i = 0; i < FixtureCounts.pastStreams; i++) {
      final starred = i % 5 == 0;
      final name = starred
          ? 'Starred Raid Night #$i'
          : (i % 7 == 0 ? null : 'Casual Stream #$i');
      sessions.add(
        _pastStream(
          name: name,
          starred: starred,
          notes: i % 4 == 0
              ? 'Notes for stream #$i: bitrate dipped mid-raid.'
              : null,
          seed: i,
          totalTimeSeconds: 1800 + i * 120,
        ),
      );
    }
    return sessions;
  }

  static List<PastRecordData> buildPastRecords() {
    final sessions = <PastRecordData>[];
    for (var i = 0; i < FixtureCounts.pastRecords; i++) {
      sessions.add(
        _pastRecord(
          name: i % 3 == 0 ? null : 'Local Recording #$i',
          starred: i % 4 == 0,
          notes: i % 5 == 0 ? 'Recording #$i kept for VOD edit.' : null,
          seed: 100 + i,
          totalTimeSeconds: 600 + i * 90,
        ),
      );
    }
    return sessions;
  }

  static List<CustomTheme> buildThemes() => [
        CustomTheme(
          'Midnight Blade',
          'Default-like dark theme with blue accents',
          true,
          '141C24',
          '101823',
          '101823',
          '3D8BFF',
          '5AA2FF',
          '0B1118',
          'FFFFFF',
          false,
          'theme-uuid-midnight-blade',
          kFixtureEpochMs,
        )..dateUpdatedMS = kFixtureEpochMs + 86400000,
        CustomTheme(
          'True Black OLED',
          'Reduce smearing on OLED — pure black cards',
          true,
          '000000',
          '000000',
          '000000',
          'FF3B30',
          'FF9500',
          '000000',
          'F2F2F7',
          false,
          'theme-uuid-true-black-oled',
          kFixtureEpochMs + 1,
        ),
        CustomTheme(
          'Light Studio',
          'Light brightness for daytime control',
          false,
          'FFFFFF',
          'F2F2F7',
          'E5E5EA',
          '007AFF',
          '34C759',
          'F9F9FB',
          '1C1C1E',
          true,
          'theme-uuid-light-studio',
          kFixtureEpochMs + 2,
        ),
        CustomTheme(
          'Halloween Stream',
          'Seasonal orange/purple — not starred',
          false,
          '1A1020',
          '120A18',
          '120A18',
          'FF6A00',
          'B24BF3',
          '0D0712',
          null,
          false,
          'theme-uuid-halloween',
          kFixtureEpochMs + 3,
        )..customLogo = 'data:image/png;base64,halloween-logo-placeholder'
          ..logoAppBarColorHex = 'FF6A00'
          ..dividerColorHex = '333333'
          ..cardBorderColorHex = 'FF6A0033',
        CustomTheme(
          'Forest Cam',
          'Greens for outdoor / irl streams',
          false,
          '14201A',
          '0E1612',
          '0E1612',
          '30D158',
          'A8E6A1',
          '0A100C',
          'E8FFE8',
          false,
          'theme-uuid-forest-cam',
          kFixtureEpochMs + 4,
        ),
        CustomTheme(
          'High Contrast A11y',
          'Max contrast for bright venues',
          true,
          '000000',
          '000000',
          '000000',
          'FFFF00',
          '00FFFF',
          '000000',
          'FFFFFF',
          false,
          'theme-uuid-high-contrast',
          kFixtureEpochMs + 5,
        ),
        CustomTheme(
          'Minimal Grey',
          null,
          false,
          '2C2C2E',
          '1C1C1E',
          '1C1C1E',
          '8E8E93',
          'AEAEB2',
          '000000',
          null,
          false,
          'theme-uuid-minimal-grey',
          kFixtureEpochMs + 6,
        ),
        CustomTheme(
          'Unnamed draft',
          'Incomplete theme still in box',
          null,
          '212123',
          '212123',
          '212123',
          '3D8BFF',
          '3D8BFF',
          '101823',
          null,
          false,
          'theme-uuid-unnamed-draft',
          kFixtureEpochMs + 7,
        ),
      ];

  static List<HiddenScene> buildHiddenScenes() {
    const scenes = [
      'BRB',
      'Starting Soon',
      'Ending',
      'Tech Difficulties',
      'Just Chatting',
      'Gameplay',
      'IRL Cam',
      'Empty',
    ];
    final list = <HiddenScene>[];
    for (var i = 0; i < FixtureCounts.hiddenScenes; i++) {
      final scene = scenes[i % scenes.length];
      final useConnectionName = i % 3 != 2;
      list.add(
        HiddenScene(
          '$scene (slot $i)',
          useConnectionName ? 'Living Room PC' : null,
          '192.168.1.${50 + (i % 5)}',
        ),
      );
    }
    return list;
  }

  static List<HiddenSceneItem> buildHiddenSceneItems() {
    final list = <HiddenSceneItem>[];
    for (var i = 0; i < FixtureCounts.hiddenSceneItems; i++) {
      final isAudio = i % 2 == 0;
      list.add(
        HiddenSceneItem(
          isAudio ? 'Gameplay' : 'Just Chatting',
          isAudio ? SceneItemType.Audio : SceneItemType.Source,
          isAudio && i % 5 == 0 ? null : 1000 + i,
          isAudio
              ? (i % 5 == 0 ? 'Mic/Aux' : 'Desktop Audio #$i')
              : 'Display Capture #$i',
          isAudio ? 'wasapi_input_capture' : (i % 7 == 0 ? 'group' : 'monitor_capture'),
          i % 4 == 0 ? null : 'Living Room PC',
          '192.168.1.50',
        ),
      );
    }
    return list;
  }

  static List<AppLog> buildAppLogs() {
    final levels = LogLevel.values;
    final list = <AppLog>[];
    for (var i = 0; i < FixtureCounts.appLogs; i++) {
      final level = levels[i % levels.length];
      final manually = i % 11 == 0;
      list.add(
        AppLog(
          kFixtureEpochMs + i * 1000,
          level,
          '${level.name} log #$i: websocket heartbeat sample',
          level == LogLevel.Error
              ? 'StackTrace mock for error #$i\n  at NetworkStore.setOBSWebSocket'
              : null,
          manually,
        ),
      );
    }
    return list;
  }

  static List<PurchasedTip> buildPurchasedTips() => [
        PurchasedTip(kFixtureEpochMs, 'tip.coffee', 'Coffee Tip', '2.99', '€'),
        PurchasedTip(
            kFixtureEpochMs + 1, 'tip.pizza', 'Pizza Tip', '4.99', '€'),
        PurchasedTip(
            kFixtureEpochMs + 2, 'tip.dinner', 'Dinner Tip', '9.99', '€'),
        PurchasedTip(
            kFixtureEpochMs + 3, 'tip.supporter', 'Supporter Tip', '14.99', '\$'),
        PurchasedTip(
            kFixtureEpochMs + 4, 'tip.legend', 'Legend Tip', '24.99', '\$'),
        PurchasedTip(kFixtureEpochMs + 5, 'tip.blacksmith', 'Blacksmith',
            '8.99', '€'),
      ];

  static List<Hotkey> buildHotkeys() => [
        for (var i = 0; i < FixtureCounts.hotkeys; i++)
          Hotkey(
            i % 3 == 0
                ? 'OBSBasic.StartStreaming'
                : (i % 3 == 1
                    ? 'OBSBasic.Mute.Mic/Aux.$i'
                    : 'CustomHotkey.SceneSwitch.$i'),
          ),
      ];

  /// Settings box is untyped — mirrors production `HiveKeys.Settings`.
  static Map<String, dynamic> buildSettings(String activeThemeUuid) => {
        SettingsKeys.HasUserSeenIntro202208.name: true,
        SettingsKeys.BoughtBlacksmith.name: true,
        SettingsKeys.TrueDark.name: true,
        SettingsKeys.ReduceSmearing.name: false,
        SettingsKeys.EnforceTabletMode.name: false,
        SettingsKeys.SelectedChatType.name: ChatType.Twitch,
        SettingsKeys.TwitchUsernames.name: <String>[
          'kounex',
          'blade_bot',
          'raid_partner',
        ],
        SettingsKeys.SelectedTwitchUsername.name: 'kounex',
        SettingsKeys.YouTubeUsernames.name: <String, String>{
          'Main VOD channel': 'https://www.youtube.com/live_chat?v=dQw4w9WgXcQ',
          'Alt stream': 'https://www.youtube.com/live_chat?v=altstream01',
        },
        SettingsKeys.SelectedYouTubeUsername.name: 'Main VOD channel',
        SettingsKeys.OwncastUsernames.name: <String, String>{
          'Home Owncast': 'https://owncast.local',
        },
        SettingsKeys.SelectedOwncastUsername.name: 'Home Owncast',
        SettingsKeys.CustomTheme.name: true,
        SettingsKeys.ActiveCustomThemeUUID.name: activeThemeUuid,
        SettingsKeys.ForceNonNativeElements.name: false,
        SettingsKeys.WakeLock.name: true,
        SettingsKeys.StreamingMode.name: false,
        SettingsKeys.ExposeRecordingControls.name: true,
        SettingsKeys.ExposeStudioControls.name: true,
        SettingsKeys.ExposeStreamingControls.name: true,
        SettingsKeys.ExposeScenePreview.name: true,
        SettingsKeys.ExposeSceneCollection.name: true,
        SettingsKeys.ExposeProfile.name: true,
        SettingsKeys.ExposeReplayBufferControls.name: false,
        SettingsKeys.ExposeHotkeys.name: true,
        SettingsKeys.ExposeInputAudioSyncOffset.name: false,
        SettingsKeys.UnlimitedReconnects.name: false,
        SettingsKeys.DashboardElementsOrder.name: DashboardElement.values,
        SettingsKeys.DontShowPreviewWarning.name: true,
        SettingsKeys.DontShowHidingSceneItemsWarning.name: false,
        SettingsKeys.DontShowYouTubeChatBetaWarning.name: true,
        SettingsKeys.DontShowHidingScenesWarning.name: false,
        SettingsKeys.DontShowStreamStartMessage.name: false,
        SettingsKeys.DontShowStreamStopMessage.name: false,
        SettingsKeys.DontShowRecordStartMessage.name: false,
        SettingsKeys.DontShowRecordStopMessage.name: false,
        SettingsKeys.DontShowConsiderBlacksmithBeforeTip.name: true,
        SettingsKeys.DontShowHotkeysTechnicalPreviewWarning.name: false,
      };

  static PastStreamData _pastStream({
    required String? name,
    required bool starred,
    required String? notes,
    required int seed,
    required int totalTimeSeconds,
  }) {
    final data = PastStreamData()
      ..name = name
      ..starred = starred
      ..notes = notes
      ..totalTime = totalTimeSeconds
      ..renderTotalFrames = totalTimeSeconds * 60
      ..renderSkippedFrames = seed % 7
      ..outputTotalFrames = totalTimeSeconds * 60 - seed
      ..outputSkippedFrames = seed % 5
      ..averageFrameTime = 16.6 + (seed % 10) * 0.1
      ..strain = seed.isEven ? 0.0 : 1.5
      ..numTotalFrames = totalTimeSeconds * 60
      ..numDroppedFrames = seed % 3;

    for (var s = 0; s < FixtureCounts.chartSamplesPerSession; s++) {
      data.kbitsPerSecList.add(2500 + seed * 10 + s * 3);
      data.fpsList.add(59.0 + (s % 5) * 0.2);
      data.cpuUsageList.add(20.0 + (seed % 40) + (s % 10));
      data.memoryUsageList.add(800.0 + seed * 5 + s);
      data.listEntryDateMS.add(kFixtureEpochMs + seed * 100000 + s * 10000);
    }
    return data;
  }

  static PastRecordData _pastRecord({
    required String? name,
    required bool starred,
    required String? notes,
    required int seed,
    required int totalTimeSeconds,
  }) {
    final data = PastRecordData()
      ..name = name
      ..starred = starred
      ..notes = notes
      ..totalTime = totalTimeSeconds
      ..renderTotalFrames = totalTimeSeconds * 60
      ..renderSkippedFrames = seed % 4
      ..outputTotalFrames = totalTimeSeconds * 60 - seed
      ..outputSkippedFrames = seed % 6
      ..averageFrameTime = 16.6 + (seed % 8) * 0.15;

    for (var s = 0; s < FixtureCounts.chartSamplesPerSession; s++) {
      data.kbitsPerSecList.add(8000 + seed * 8 + s * 2);
      data.fpsList.add(60.0 - (s % 3) * 0.1);
      data.cpuUsageList.add(30.0 + (seed % 25) + (s % 8));
      data.memoryUsageList.add(1200.0 + seed * 4 + s);
      data.listEntryDateMS.add(kFixtureEpochMs + seed * 100000 + s * 10000);
    }
    return data;
  }
}

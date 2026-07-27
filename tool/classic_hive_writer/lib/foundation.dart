/// Same self-explanatory foundation dataset as
/// `test/persistence/fixtures/foundation_data.dart` (keep counts/key rows in sync).
library;

import 'models.dart';

const int kFixtureEpochMs = 1700000000000;

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
  static const chartSamplesPerSession = 48;
}

class ClassicFoundationData {
  late final connections = buildConnections();
  late final pastStreams = buildPastStreams();
  late final pastRecords = buildPastRecords();
  late final themes = buildThemes();
  late final hiddenScenes = buildHiddenScenes();
  late final hiddenSceneItems = buildHiddenSceneItems();
  late final appLogs = buildAppLogs();
  late final purchasedTips = buildPurchasedTips();
  late final hotkeys = buildHotkeys();
  late final settings = buildSettings(themes.first.uuid);

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
    final list = <PastStreamData>[];
    for (var i = 0; i < FixtureCounts.pastStreams; i++) {
      final starred = i % 5 == 0;
      final data = PastStreamData()
        ..name = starred
            ? 'Starred Raid Night #$i'
            : (i % 7 == 0 ? null : 'Casual Stream #$i')
        ..starred = starred
        ..notes = i % 4 == 0
            ? 'Notes for stream #$i: bitrate dipped mid-raid.'
            : null
        ..totalTime = 1800 + i * 120
        ..renderTotalFrames = (1800 + i * 120) * 60
        ..renderSkippedFrames = i % 7
        ..outputTotalFrames = (1800 + i * 120) * 60 - i
        ..outputSkippedFrames = i % 5
        ..averageFrameTime = 16.6 + (i % 10) * 0.1
        ..strain = i.isEven ? 0.0 : 1.5
        ..numTotalFrames = (1800 + i * 120) * 60
        ..numDroppedFrames = i % 3;
      for (var s = 0; s < FixtureCounts.chartSamplesPerSession; s++) {
        data.kbitsPerSecList.add(2500 + i * 10 + s * 3);
        data.fpsList.add(59.0 + (s % 5) * 0.2);
        data.cpuUsageList.add(20.0 + (i % 40) + (s % 10));
        data.memoryUsageList.add(800.0 + i * 5 + s);
        data.listEntryDateMS.add(kFixtureEpochMs + i * 100000 + s * 10000);
      }
      list.add(data);
    }
    return list;
  }

  static List<PastRecordData> buildPastRecords() {
    final list = <PastRecordData>[];
    for (var i = 0; i < FixtureCounts.pastRecords; i++) {
      final seed = 100 + i;
      final total = 600 + i * 90;
      final data = PastRecordData()
        ..name = i % 3 == 0 ? null : 'Local Recording #$i'
        ..starred = i % 4 == 0
        ..notes = i % 5 == 0 ? 'Recording #$i kept for VOD edit.' : null
        ..totalTime = total
        ..renderTotalFrames = total * 60
        ..renderSkippedFrames = seed % 4
        ..outputTotalFrames = total * 60 - seed
        ..outputSkippedFrames = seed % 6
        ..averageFrameTime = 16.6 + (seed % 8) * 0.15;
      for (var s = 0; s < FixtureCounts.chartSamplesPerSession; s++) {
        data.kbitsPerSecList.add(8000 + seed * 8 + s * 2);
        data.fpsList.add(60.0 - (s % 3) * 0.1);
        data.cpuUsageList.add(30.0 + (seed % 25) + (s % 8));
        data.memoryUsageList.add(1200.0 + seed * 4 + s);
        data.listEntryDateMS.add(kFixtureEpochMs + seed * 100000 + s * 10000);
      }
      list.add(data);
    }
    return list;
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
        )
          ..customLogo = 'data:image/png;base64,halloween-logo-placeholder'
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
    return [
      for (var i = 0; i < FixtureCounts.hiddenScenes; i++)
        HiddenScene(
          '${scenes[i % scenes.length]} (slot $i)',
          i % 3 != 2 ? 'Living Room PC' : null,
          '192.168.1.${50 + (i % 5)}',
        ),
    ];
  }

  static List<HiddenSceneItem> buildHiddenSceneItems() => [
        for (var i = 0; i < FixtureCounts.hiddenSceneItems; i++)
          HiddenSceneItem(
            i.isEven ? 'Gameplay' : 'Just Chatting',
            i.isEven ? SceneItemType.Audio : SceneItemType.Source,
            i.isEven && i % 5 == 0 ? null : 1000 + i,
            i.isEven
                ? (i % 5 == 0 ? 'Mic/Aux' : 'Desktop Audio #$i')
                : 'Display Capture #$i',
            i.isEven
                ? 'wasapi_input_capture'
                : (i % 7 == 0 ? 'group' : 'monitor_capture'),
            i % 4 == 0 ? null : 'Living Room PC',
            '192.168.1.50',
          ),
      ];

  static List<AppLog> buildAppLogs() {
    final levels = LogLevel.values;
    return [
      for (var i = 0; i < FixtureCounts.appLogs; i++)
        AppLog(
          kFixtureEpochMs + i * 1000,
          levels[i % levels.length],
          '${levels[i % levels.length].name} log #$i: websocket heartbeat sample',
          levels[i % levels.length] == LogLevel.Error
              ? 'StackTrace mock for error #$i\n  at NetworkStore.setOBSWebSocket'
              : null,
          i % 11 == 0,
        ),
    ];
  }

  static List<PurchasedTip> buildPurchasedTips() => [
        PurchasedTip(kFixtureEpochMs, 'tip.coffee', 'Coffee Tip', '2.99', '€'),
        PurchasedTip(
            kFixtureEpochMs + 1, 'tip.pizza', 'Pizza Tip', '4.99', '€'),
        PurchasedTip(
            kFixtureEpochMs + 2, 'tip.dinner', 'Dinner Tip', '9.99', '€'),
        PurchasedTip(kFixtureEpochMs + 3, 'tip.supporter', 'Supporter Tip',
            '14.99', '\$'),
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

  /// Keys must match obs_blade SettingsKeys.name values.
  static Map<String, dynamic> buildSettings(String activeThemeUuid) => {
        'has-user-seen-intro-202208': true,
        'bought-blacksmith': true,
        'true-dark': true,
        'reduce-smearing': false,
        'enforce-tablet-mode': false,
        'selected-chat-type': ChatType.Twitch,
        'twitch-usernames': <String>['kounex', 'blade_bot', 'raid_partner'],
        'selected-twitch-username': 'kounex',
        'youtube-usernames': <String, String>{
          'Main VOD channel':
              'https://www.youtube.com/live_chat?v=dQw4w9WgXcQ',
          'Alt stream': 'https://www.youtube.com/live_chat?v=altstream01',
        },
        'selected-youtube-username': 'Main VOD channel',
        'owncast-usernames': <String, String>{
          'Home Owncast': 'https://owncast.local',
        },
        'selected-owncast-username': 'Home Owncast',
        'custom-theme': true,
        'active-custom-theme-uuid': activeThemeUuid,
        'force-non-native-elements': false,
        'wake-lock': true,
        'streaming-mode': false,
        'expose-recording-controls': true,
        'expose-studio-controls': true,
        'expose-streaming-controls': true,
        'expose-scene-preview': true,
        'expose-scene-collection': true,
        'expose-profile': true,
        'expose-replay-buffer-collection': false,
        'expose-hotkeys': true,
        'expose-input-audio-sync-offset': false,
        'unlimited-reconnects': false,
        'dashboard-elements-order': DashboardElement.values,
        'dont-show-preview-warning': true,
        'dont-show-hiding-scene-items-warning': false,
        'dont-show-youtube-chat-beta-warning': true,
        'dont-show-hiding-scenes-warning': false,
        'dont-show-stream-start-message': false,
        'dont-show-stream-stop-message': false,
        'dont-show-record-start-message': false,
        'dont-show-record-stop-message': false,
        'dont-show-consider-blacksmith-before-tip': true,
        'dont-show-hotkeys-technical-preview-warning': false,
      };
}

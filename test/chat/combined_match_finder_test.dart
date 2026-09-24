import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/utils/combined/combined_match_finder.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';

import 'support/fake_kick_services.dart';

/// Page titles by handle; a missing handle = no such channel.
class FakeNamer extends YouTubeEntryNamer {
  final Map<String, String> titles;
  final List<String> asked = <String>[];

  FakeNamer(this.titles);

  @override
  Future<String?> channelPageTitle(String path) async {
    this.asked.add(path);
    return this.titles[path];
  }
}

TwitchChannelSearchResult searchResult(String login, String name) =>
    TwitchChannelSearchResult(
      id: 'id-$login',
      login: login,
      displayName: name,
      gameName: '',
      isLive: false,
    );

void main() {
  test('candidates cover separator variants, lowercased, no @', () {
    expect(combinedMatchCandidates('@Ice_Poseidon'), [
      'ice_poseidon',
      'ice-poseidon',
      'iceposeidon',
    ]);
    expect(combinedMatchCandidates('xqc'), ['xqc']);
    expect(combinedMatchCandidates('  '), isEmpty);
  });

  test('finds one match per requested platform', () async {
    final kick = FakeKickChannelService();
    kick.channels['ice-poseidon'] = const KickChannelInfo(
      id: 1,
      userId: 2,
      slug: 'ice-poseidon',
      username: 'Ice_Poseidon',
      chatroom: KickChatroom(id: 3),
    );
    final finder = CombinedMatchFinder(
      kickService: kick,
      youTubeNamer: FakeNamer({'@iceposeidon': 'Ice Poseidon'}),
      twitchSearch: (query) async => [
        searchResult('ice_poseidon_fan', 'Fan'),
        searchResult('ice_poseidon', 'Ice_Poseidon'),
      ],
    );

    final matches = await finder.find(
      'Ice_Poseidon',
      platforms: {ChatType.Twitch, ChatType.YouTube, ChatType.Kick},
    );
    final byPlatform = {for (final m in matches) m.platform: m};

    expect(byPlatform[ChatType.Kick]!.value, 'ice-poseidon');
    expect(byPlatform[ChatType.YouTube]!.value, '@iceposeidon');
    expect(byPlatform[ChatType.YouTube]!.label, 'Ice Poseidon');

    /// Exact login only - the "_fan" result never matches.
    expect(byPlatform[ChatType.Twitch]!.value, 'id-ice_poseidon');
    expect(byPlatform[ChatType.Twitch]!.twitchLogin, 'ice_poseidon');
  });

  test('skips platforms not asked for, and Twitch without a login', () async {
    final namer = FakeNamer({'@xqc': 'xQc'});
    final finder = CombinedMatchFinder(
      kickService: FakeKickChannelService(),
      youTubeNamer: namer,
    );

    final matches = await finder.find(
      'xqc',
      platforms: {ChatType.Twitch, ChatType.Kick},
    );

    expect(matches, isEmpty);
    expect(namer.asked, isEmpty);
  });

  test('a failing lookup just yields no suggestion', () async {
    final kick = FakeKickChannelService()..resolveThrows = Exception('down');
    final finder = CombinedMatchFinder(
      kickService: kick,
      youTubeNamer: FakeNamer({'@xqc': 'xQc'}),
      twitchSearch: (_) async => throw Exception('401'),
    );

    final matches = await finder.find(
      'xqc',
      platforms: {ChatType.Twitch, ChatType.YouTube, ChatType.Kick},
    );

    expect(matches.map((m) => m.platform), [ChatType.YouTube]);
  });
}

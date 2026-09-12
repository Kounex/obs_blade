import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/redesign/chat/chat_access.dart';
import 'package:obs_blade/redesign/chat/chat_access_projection.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';

void main() {
  late ProStore pro;
  late _Twitch twitch;
  late _YouTube youtube;
  ChatAccess project({
    ChatType platform = ChatType.Twitch,
    ChatEngine engine = ChatEngine.native,
  }) => projectChatAccess(
    platform: platform,
    preferredEngine: engine,
    pro: pro,
    twitch: twitch,
    youtube: youtube,
  );
  setUp(() {
    pro = ProStore();
    twitch = _Twitch();
    youtube = _YouTube();
  });

  test('WebView and unsupported native preferences remain free', () {
    expect(project(engine: ChatEngine.webView).gate, ChatGate.embedded);
    expect(project(platform: ChatType.Owncast).engine, ChatEngine.webView);
  });

  test('Pro blocks native before exposing account or setup state', () {
    expect(project().gate, ChatGate.pro);
    expect(project(platform: ChatType.YouTube).gate, ChatGate.pro);
    pro.boughtPro = true;
    expect(project().gate, ChatGate.signIn);
    expect(project(platform: ChatType.YouTube).gate, ChatGate.setup);
  });

  test('Twitch read access does not imply write permission', () {
    pro.boughtPro = true;
    twitch.authState = TwitchAuthState.loggedIn;
    twitch.user = TwitchUser(id: 'owner', login: 'studio');
    twitch.chatConnection = TwitchChatConnectionState.live;
    expect(project().showsNativeConversation, true);
    expect(project().writeAccess, ChatWriteAccess.permissions);
    expect(project().canSend, false);
    twitch.write = true;
    expect(project().canSend, true);
    twitch.chatConnection = TwitchChatConnectionState.reconnecting;
    expect(project().canSend, false);
    expect(project().channelId, 'owner');
  });

  test('YouTube can read signed out and uses video identity, not label', () {
    pro.boughtPro = true;
    youtube.configured = true;
    expect(project(platform: ChatType.YouTube).gate, ChatGate.channel);
    youtube.channels.add(
      const YouTubeChatChannel(label: 'Studio', videoId: 'video-a'),
    );
    youtube.selectedChannelLabel = 'Studio';
    youtube.chatConnection = YouTubeChatConnectionState.connected;
    final state = project(platform: ChatType.YouTube);
    expect(state.showsNativeConversation, true);
    expect(state.channelId, 'video-a');
    expect(state.canSend, false);
    youtube.authState = YouTubeAuthState.awaitingAuthorization;
    expect(project(platform: ChatType.YouTube).showsNativeConversation, true);
    expect(
      project(platform: ChatType.YouTube).writeAccess,
      ChatWriteAccess.authorizing,
    );
    youtube.authState = YouTubeAuthState.signedOut;
    youtube.write = true;
    expect(project(platform: ChatType.YouTube).canSend, true);
    youtube.chatConnection = YouTubeChatConnectionState.offline;
    expect(project(platform: ChatType.YouTube).link, ChatLink.ended);
    expect(project(platform: ChatType.YouTube).canSend, false);
  });

  test(
    'live entitlement revocation changes projection without logging out',
    () {
      pro.boughtPro = true;
      twitch.authState = TwitchAuthState.loggedIn;
      twitch.user = TwitchUser(id: 'owner', login: 'studio');
      final gates = <ChatGate>[];
      final dispose = autorun((_) => gates.add(project().gate));
      pro.boughtPro = false;
      expect(gates, [ChatGate.open, ChatGate.pro]);
      expect(twitch.isLoggedIn, true);
      dispose();
    },
  );

  test('account authorization and quota failure stay distinct', () {
    pro.boughtPro = true;
    twitch.authState = TwitchAuthState.awaitingAuthorization;
    expect(project().gate, ChatGate.authorizing);
    youtube.configured = true;
    youtube.channels.add(
      const YouTubeChatChannel(label: 'Studio', videoId: 'video-a'),
    );
    youtube.selectedChannelLabel = 'Studio';
    youtube.chatConnection = YouTubeChatConnectionState.error;
    youtube.chatQuotaExhausted = true;
    expect(
      project(platform: ChatType.YouTube).statusLabel,
      'Chat quota reached',
    );
  });
}

// Real store state with I/O-dependent capability getters supplied by fixtures.
// No init, Hive, API calls or purchase services are started by the projection.
class _Twitch extends TwitchChatStore {
  bool write = false;
  @override
  bool get canWriteChat => write;
}

class _YouTube extends YouTubeChatStore {
  bool configured = false;
  bool write = false;
  @override
  bool get canRead => configured;
  @override
  bool get canWrite => write;
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/redesign/chat/chat_composer_controller.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';

const _message = ChatMessageEvent(
  broadcasterUserId: 'owner',
  chatterUserId: 'viewer',
  chatterUserLogin: 'viewer',
  chatterUserName: 'Viewer',
  messageId: 'message-1',
  message: ChatMessageText(text: 'Hello'),
);

void main() {
  late ProStore pro;
  late _Twitch twitch;
  late _YouTube youtube;
  late ChatComposerController controller;

  setUp(() {
    pro = ProStore()..boughtPro = true;
    twitch = _Twitch()
      ..authState = TwitchAuthState.loggedIn
      ..user = TwitchUser(id: 'owner', login: 'studio')
      ..chatConnection = TwitchChatConnectionState.live;
    twitch.messages.add(_message);
    twitch.channels.add(
      TwitchChannelRef(
        id: 'other',
        login: 'other',
        displayName: 'Other',
        addedAt: DateTime.utc(2026),
      ),
    );
    youtube = _YouTube()
      ..authState = YouTubeAuthState.signedOut
      ..chatConnection = YouTubeChatConnectionState.connected
      ..selectedChannelLabel = 'Studio';
    youtube.channels.add(
      const YouTubeChatChannel(label: 'Studio', videoId: 'video-a'),
    );
    controller = ChatComposerController(
      pro: pro,
      twitch: twitch,
      youtube: youtube,
      platform: ChatType.Twitch,
      engine: ChatEngine.native,
    );
  });

  tearDown(() => controller.dispose());

  test('draft and real reply ID survive channel round trip', () async {
    controller.setText('To the owner');
    expect(controller.setReply(_message), true);
    final own = controller.channels.first;
    expect(await controller.selectChannel(controller.channels.last), true);
    expect(controller.text, isEmpty);
    expect(controller.reply, isNull);
    controller.setText('To the other channel');
    expect(await controller.selectChannel(own), true);
    expect(controller.text, 'To the owner');
    expect(controller.reply?.messageId, 'message-1');
    expect(await controller.send(), true);
    expect(twitch.lastReply?.messageId, 'message-1');
    expect(twitch.lastDestination, 'owner');
    expect(controller.text, isEmpty);
  });

  test(
    'channel and presentation actions serialize against a pending send',
    () async {
      controller.setText('In flight');
      twitch.pending = Completer<bool>();
      final send = controller.send();
      expect(controller.sending, true);
      expect(await controller.selectChannel(controller.channels.last), false);
      expect(
        controller.setPresentation(ChatType.YouTube, ChatEngine.native),
        false,
      );
      expect(await controller.send(), false);
      expect(twitch.selectCalls, 0);
      expect(twitch.sendCalls, 1);
      twitch.pending!.complete(true);
      expect(await send, true);
    },
  );

  test(
    'external channel change cannot move completion into its draft',
    () async {
      controller.setText('For owner');
      twitch.pending = Completer<bool>();
      final send = controller.send();
      await twitch.selectChannel('other');
      controller.setText('For other');
      twitch.pending!.complete(true);
      await send;
      expect(controller.text, 'For other');
      await controller.selectChannel(controller.channels.first);
      expect(controller.text, isEmpty);
    },
  );

  test('edits made during send are not cleared by its completion', () async {
    controller.setText('First message');
    twitch.pending = Completer<bool>();
    final send = controller.send();
    controller.setText('Next message');
    twitch.pending!.complete(true);
    await send;
    expect(twitch.lastText, 'First message');
    expect(controller.text, 'Next message');
  });

  test(
    'failed send retains original draft and offers no automatic retry',
    () async {
      controller.setText('Keep this');
      twitch.pending = Completer<bool>();
      final send = controller.send();
      await twitch.selectChannel('other');
      controller.setText('Other draft');
      twitch.pending!.complete(false);
      expect(await send, false);
      expect(controller.error, isNull);
      await controller.selectChannel(controller.channels.first);
      expect(controller.text, 'Keep this');
      expect(controller.error, contains('not confirmed'));
      expect(twitch.sendCalls, 1);
    },
  );

  test(
    'Pro loss hides access and rejects send while retaining the draft',
    () async {
      controller.setText('Keep for later');
      expect(controller.timeline.entries, hasLength(1));
      pro.boughtPro = false;
      expect(controller.timeline.entries, isEmpty);
      expect(await controller.send(), false);
      expect(await controller.selectChannel(controller.channels.last), false);
      expect(controller.text, 'Keep for later');
      expect(twitch.sendCalls, 0);
      expect(twitch.selectCalls, 0);
      pro.boughtPro = true;
      expect(controller.timeline.entries, hasLength(1));
      expect(controller.canSend, true);
    },
  );

  test(
    'logout clears all account drafts and late completion cannot restore them',
    () async {
      controller.setText('Private draft');
      twitch.pending = Completer<bool>();
      final send = controller.send();
      twitch.authState = TwitchAuthState.loggedOut;
      twitch.pending!.complete(false);
      await send;
      twitch.authState = TwitchAuthState.loggedIn;
      expect(controller.text, isEmpty);
      expect(controller.error, isNull);
    },
  );

  test(
    'Twitch permission renewal keeps drafts, account replacement clears them',
    () {
      controller.setText('Finish after renewing permission');
      controller.setReply(_message);
      twitch.authState = TwitchAuthState.awaitingAuthorization;
      expect(controller.text, 'Finish after renewing permission');
      twitch.authState = TwitchAuthState.loggedIn;
      expect(controller.reply?.messageId, 'message-1');
      twitch.user = TwitchUser(id: 'replacement', login: 'replacement');
      expect(controller.text, isEmpty);
      expect(controller.reply, isNull);
    },
  );

  test(
    'platform switch retracks YouTube connection and channel changes',
    () async {
      controller.setPresentation(ChatType.YouTube, ChatEngine.native);
      controller.setText('YouTube draft');
      expect(controller.canSend, true);
      youtube.chatConnection = YouTubeChatConnectionState.offline;
      expect(controller.canSend, false);
      youtube.chatConnection = YouTubeChatConnectionState.connected;
      expect(controller.canSend, true);
      runInAction(() {
        youtube.channels[0] = const YouTubeChatChannel(
          label: 'Studio',
          videoId: 'video-b',
        );
      });
      expect(controller.conversation?.channel, 'video-b');
      expect(controller.text, isEmpty);
      controller.setText('New video');
      expect(await controller.send(), true);
      expect(youtube.lastText, 'New video');
    },
  );

  test(
    'YouTube sign-in lifetime separates drafts without a persisted account ID',
    () {
      controller.setPresentation(ChatType.YouTube, ChatEngine.native);
      controller.setText('Anonymous');
      youtube.authState = YouTubeAuthState.signedIn;
      final firstAccount = controller.conversation?.account;
      expect(firstAccount, isNotNull);
      expect(controller.text, isEmpty);
      controller.setText('Account draft');
      youtube.authState = YouTubeAuthState.signedOut;
      youtube.authState = YouTubeAuthState.signedIn;
      expect(controller.conversation?.account, isNot(firstAccount));
      expect(controller.text, isEmpty);
    },
  );

  test(
    'reply from another conversation and stale channel choice are rejected',
    () async {
      expect(
        controller.setReply(_message.copyWith(broadcasterUserId: 'other')),
        false,
      );
      controller.setPresentation(ChatType.YouTube, ChatEngine.native);
      final stale = controller.channels.single;
      youtube.channels[0] = const YouTubeChatChannel(
        label: 'Studio',
        videoId: 'video-b',
      );
      expect(await controller.selectChannel(stale), false);
      expect(youtube.selectCalls, 0);
    },
  );

  test('disposal owns no account or transport lifecycle', () async {
    controller.setText('Pending');
    twitch.pending = Completer<bool>();
    final send = controller.send();
    // Replace only the presentation owner, keeping the injected stores alive.
    controller.dispose();
    twitch.pending!.complete(true);
    expect(await send, true);
    controller = ChatComposerController(
      pro: pro,
      twitch: twitch,
      youtube: youtube,
      platform: ChatType.Twitch,
      engine: ChatEngine.native,
    );
    expect(twitch.isLoggedIn, true);
    expect(twitch.chatConnection, TwitchChatConnectionState.live);
    expect(controller.text, isEmpty);
  });
}

// Real observable store fields; only I/O capabilities and dispatch are replaced.
// Actual transport/send destination behavior is covered in test/chat/.
class _Twitch extends TwitchChatStore {
  Completer<bool>? pending;
  String? lastText;
  String? lastDestination;
  ChatMessageEvent? lastReply;
  int sendCalls = 0;
  int selectCalls = 0;
  @override
  bool get canWriteChat => true;
  @override
  Future<void> selectChannel(String? id) async {
    selectCalls++;
    runInAction(() {
      selectedChannelId = id;
      replyTarget = null;
    });
  }

  @override
  Future<bool> sendChatMessage(String text) async {
    sendCalls++;
    lastText = text;
    lastDestination = effectiveBroadcasterId;
    lastReply = replyTarget;
    return pending == null ? true : await pending!.future;
  }
}

class _YouTube extends YouTubeChatStore {
  String? lastText;
  int selectCalls = 0;
  @override
  bool get canRead => true;
  @override
  bool get canWrite => true;
  @override
  String? get selfChannelTitle => 'Display title only';
  @override
  Future<void> selectChannel(String? label) async {
    selectCalls++;
    selectedChannelLabel = label;
  }

  @override
  Future<bool> sendChatMessage(String text) async {
    lastText = text;
    return true;
  }
}

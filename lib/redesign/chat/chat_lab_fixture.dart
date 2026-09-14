import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../../stores/pro_store.dart';
import '../../stores/views/third_party_emotes.dart';
import '../../stores/views/twitch_badges.dart';
import '../../stores/views/twitch_chat.dart';
import '../../stores/views/youtube_chat.dart';
import '../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../types/classes/twitch/eventsub/channel_chat_notification.dart';
import '../../types/classes/twitch/twitch_channel_ref.dart';
import '../../types/classes/twitch/twitch_user.dart';
import '../../types/classes/youtube/youtube_chat_message.dart';
import 'chat_composer_controller.dart';
import 'workspace_chat_pane.dart';
import 'workspace_chat_timeline.dart';

/// Native-only lab. Uses a fresh temporary settings box and synthetic stores;
/// it never loads saved accounts, registers global services, or opens sockets.
class ChatLabFixture {
  ChatLabFixture._(this.directory, this.settings) {
    controller = ChatComposerController(
      pro: pro,
      twitch: twitch,
      youtube: youtube,
      platform: ChatType.Twitch,
      engine: ChatEngine.native,
    );
  }
  final Directory directory;
  final Box settings;
  final pro = ProStore()..boughtPro = true;
  final twitch = LabTwitchChatStore();
  final youtube = LabYouTubeChatStore();
  final badges = TwitchBadgeStore();
  final emotes = ThirdPartyEmoteStore();
  late final ChatComposerController controller;

  static Future<ChatLabFixture> create() async {
    final directory = await Directory.systemTemp.createTemp(
      'obs-workspace-chat-',
    );
    final box = await Hive.openBox<dynamic>(
      'workspace_chat_lab',
      path: directory.path,
    );
    return ChatLabFixture._(directory, box);
  }

  Widget buildPane(BuildContext context) => WorkspaceChatPane(
    controller: controller,
    timeline: WorkspaceChatTimeline(
      controller: controller,
      settings: settings,
      badges: badges,
      emotes: emotes,
    ),
    onAction: (action) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lab: ${action.label} host action is not connected yet.'),
      ),
    ),
  );

  Future<void> dispose() async {
    controller.dispose();
    await settings.close();
    await directory.delete(recursive: true);
  }
}

class LabTwitchChatStore extends TwitchChatStore {
  LabTwitchChatStore() {
    user = TwitchUser(
      id: 'studio',
      login: 'studio_chat',
      displayName: 'Studio chat',
    );
    authState = TwitchAuthState.loggedIn;
    chatConnection = TwitchChatConnectionState.live;
    channels.add(
      TwitchChannelRef(
        id: 'lounge',
        login: 'lounge',
        displayName: 'Community lounge',
        addedAt: DateTime.utc(2026),
      ),
    );
    _load('studio');
  }
  final writeAllowed = Observable(true);
  final _history = <String, List<ChatMessageEvent>>{};
  int _sent = 0;
  @override
  bool get canWriteChat => writeAllowed.value;

  static const _lines = [
    'Hi everyone!',
    'The room looks great today.',
    'Can you bring up the close-up?',
    'That camera angle works well.',
    'The audio is clear here.',
    'Yes, that makes it much easier to see.',
    'I missed the start — what are we building?',
    'A scene switcher for today’s demo.',
    'Could you show the before and after?',
    'Thanks for keeping the instructions on screen.',
    'The lighting is much warmer now.',
    'Do those settings work on tablet too?',
    'I use the side-by-side view when I’m moderating.',
    'That transition was smooth 🙌',
    'We’ll try the alternate angle next.',
    'Nice, I can finally read the labels.',
    'Welcome, raid!',
    'We just finished setting up the main camera.',
    'The microphone level sounds right here.',
    'Ready for the next part!',
    'Could you leave the chat a little larger?',
    'First time here — glad I caught this.',
    'We’re ready when you are.',
    'The new scene is ready.',
  ];

  void _load(String id) {
    final history = _history.putIfAbsent(
      id,
      () => List.generate(
        _lines.length,
        (index) => ChatMessageEvent(
          broadcasterUserId: id,
          chatterUserId: 'viewer-${index % 3}',
          chatterUserLogin: ['mira', 'jules', 'river'][index % 3],
          chatterUserName: ['Mira', 'Jules', 'River'][index % 3],
          messageId: '$id-$index',
          color: ['#B3CEFF', '#EDBE84', '#B6D4B9'][index % 3],
          isFirstMessage: index == 21,
          badges: index == 22
              ? const [ChatMessageBadge(setId: 'moderator', id: '1')]
              : const [],
          message: ChatMessageText(text: _lines[index]),
          reply: index == 23
              ? ChatMessageReply(
                  parentMessageId: '$id-22',
                  parentMessageBody: _lines[22],
                  parentUserId: 'viewer-1',
                  parentUserName: 'Jules',
                  parentUserLogin: 'jules',
                  threadMessageId: '$id-22',
                  threadUserId: 'viewer-1',
                  threadUserName: 'Jules',
                  threadUserLogin: 'jules',
                )
              : null,
        ),
      ),
    );
    messages
      ..clear()
      ..addAll(history);
    systemNotices.clear();
    chatNotifications
      ..clear()
      ..add(
        ChatNotificationNotice(
          afterSeq: 0,
          event: ChatNotificationEvent(
            broadcasterUserId: id,
            chatterUserId: 'guest',
            chatterUserLogin: 'guest',
            chatterUserName: 'Guest',
            messageId: '$id-raid',
            systemMessage: 'Guest raided with 12 viewers!',
            noticeType: 'raid',
            raid: const ChatNotificationRaid(viewerCount: 12),
          ),
        ),
      );
    lifecycleVersion++;
  }

  @override
  Future<void> selectChannel(String? id) async => runInAction(() {
    _history[effectiveBroadcasterId] = List.of(messages);
    selectedChannelId = id;
    replyTarget = null;
    _load(effectiveBroadcasterId);
  });

  @override
  Future<bool> sendChatMessage(String text) async {
    runInAction(
      () => messages.add(
        ChatMessageEvent(
          broadcasterUserId: effectiveBroadcasterId,
          chatterUserId: user!.id,
          chatterUserLogin: user!.login,
          chatterUserName: 'You',
          messageId: 'sent-${++_sent}',
          message: ChatMessageText(text: text.trim()),
        ),
      ),
    );
    return true;
  }
}

class LabYouTubeChatStore extends YouTubeChatStore {
  LabYouTubeChatStore() {
    authState = YouTubeAuthState.signedIn;
    chatConnection = YouTubeChatConnectionState.connected;
    selectedChannelLabel = 'Weekend stream';
    channels.add(
      const YouTubeChatChannel(label: 'Weekend stream', videoId: 'video-a-001'),
    );
    messages.add(
      YouTubeChatMessage(
        id: 'yt-1',
        snippet: YouTubeChatMessageSnippet(
          type: YouTubeChatMessageType.superChat,
          publishedAt: DateTime.utc(2026),
          displayMessage: 'Thanks for the stream!',
          superChatDetails: const YouTubeSuperChatDetails(
            currency: 'EUR',
            amountDisplayString: '€5.00',
            userComment: 'Thanks for the stream!',
            tier: 1,
          ),
        ),
        authorDetails: const YouTubeChatAuthorDetails(
          channelId: 'viewer',
          displayName: 'River',
          isChatSponsor: true,
        ),
      ),
    );
  }
  @override
  bool get canRead => true;
  @override
  bool get canWrite => isSignedInState;
  @override
  String? get selfChannelTitle => 'Studio';
  @override
  Future<void> selectChannel(String? label) async =>
      selectedChannelLabel = label;
  @override
  Future<bool> sendChatMessage(String text) async {
    runInAction(
      () => messages.add(
        YouTubeChatMessage(
          id: 'yt-${messages.length + 1}',
          snippet: YouTubeChatMessageSnippet(
            type: YouTubeChatMessageType.textMessage,
            publishedAt: DateTime.utc(2026),
            displayMessage: text.trim(),
          ),
          authorDetails: const YouTubeChatAuthorDetails(
            channelId: 'self',
            displayName: 'You',
          ),
        ),
      ),
    );
    return true;
  }
}

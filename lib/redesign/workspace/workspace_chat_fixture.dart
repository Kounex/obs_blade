import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../chat/chat_access.dart';

enum LabChatScenario {
  ready('Connected'),
  pro('Pro required'),
  signIn('Twitch signed out'),
  readOnly('Twitch read-only'),
  youtubeSetup('YouTube setup'),
  youtubeSignedOut('YouTube read-only'),
  reconnecting('Chat reconnecting'),
  ended('YouTube chat ended'),
  quota('YouTube quota reached');

  const LabChatScenario(this.label);
  final String label;
}

ChatAccess chatFixture(LabChatScenario scenario, {required bool sending}) {
  final youtube = {
    LabChatScenario.youtubeSetup,
    LabChatScenario.youtubeSignedOut,
    LabChatScenario.ended,
    LabChatScenario.quota,
  }.contains(scenario);
  return ChatAccess(
    platform: youtube ? ChatType.YouTube : ChatType.Twitch,
    engine: ChatEngine.native,
    gate: switch (scenario) {
      LabChatScenario.pro => ChatGate.pro,
      LabChatScenario.signIn => ChatGate.signIn,
      LabChatScenario.youtubeSetup => ChatGate.setup,
      _ => ChatGate.open,
    },
    link: switch (scenario) {
      LabChatScenario.reconnecting => ChatLink.reconnecting,
      LabChatScenario.ended => ChatLink.ended,
      LabChatScenario.quota => ChatLink.failed,
      _ => ChatLink.connected,
    },
    writeAccess: switch (scenario) {
      LabChatScenario.readOnly => ChatWriteAccess.permissions,
      LabChatScenario.youtubeSignedOut => ChatWriteAccess.signIn,
      _ => ChatWriteAccess.available,
    },
    channelId: youtube ? 'synthetic-video' : 'synthetic-channel',
    channelLabel: 'studio_chat',
    sending: sending,
    quotaExhausted: scenario == LabChatScenario.quota,
  );
}

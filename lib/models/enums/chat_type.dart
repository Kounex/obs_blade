import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/utils/icons/custom_flutter_icons.dart';
import '../../utils/build_flavor.dart';
import '../type_ids.dart';
import '../../utils/icons/jam_icons.dart';

part 'chat_type.g.dart';

@HiveType(typeId: TypeIDs.ChatType)
enum ChatType {
  @HiveField(0)
  Twitch,

  @HiveField(1)
  YouTube,

  @HiveField(2)
  Owncast,

  /// Append-only: Hive serializes the field index byte - never reorder,
  /// never reuse. Old builds decode an unknown index as Twitch (adapter
  /// default), a downgrade footgun we accept over a crash.
  @HiveField(3)
  Kick,

  /// Native-only merged timeline of the Twitch / YouTube / Kick engines
  /// (no WebView, no own username list) - see [isNativeOnly].
  @HiveField(4)
  Combined,
}

/// Chat types without a WebView engine: the native slot renders them
/// regardless of the persisted `SelectedChatEngine`, and the engine switch
/// hides for them.
bool isNativeOnly(ChatType chatType) => chatType == ChatType.Combined;

/// The chat types the chat type picker offers - the FOSS build ([kFoss])
/// has no native engine, so no native-only types.
List<ChatType> get selectableChatTypes => kFoss
    ? ChatType.values.where((type) => !isNativeOnly(type)).toList()
    : ChatType.values;

extension ChatTypeFunctions on ChatType {
  String get text => const {
    ChatType.Twitch: 'Twitch',
    ChatType.YouTube: 'YouTube',
    ChatType.Owncast: 'Owncast',
    ChatType.Kick: 'Kick',
    ChatType.Combined: 'Combined',
  }[this]!;

  IconData get icon => const {
    ChatType.Twitch: JamIcons.twitch,
    ChatType.YouTube: JamIcons.youtube,
    ChatType.Owncast: CustomFlutterIcons.owncast_logo,
    ChatType.Kick: CustomFlutterIcons.kick,

    /// Monochrome fallback only — Combined renders its multi-color
    /// `CombinedChatIcon` wherever the chat type is shown.
    ChatType.Combined: JamIcons.messages,
  }[this]!;
}

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/type_ids.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';

part 'chat_type.g.dart';

@HiveType(typeId: TypeIDs.ChatType)
enum ChatType {
  @HiveField(0)
  Twitch,

  @HiveField(1)
  YouTube,
}

extension ChatTypeFunctions on ChatType {
  String get text => const {
        ChatType.Twitch: 'Twitch',
        ChatType.YouTube: 'YouTube',
      }[this]!;

  IconData get icon => const {
        ChatType.Twitch: JamIcons.twitch,
        ChatType.YouTube: JamIcons.youtube,
      }[this]!;
}

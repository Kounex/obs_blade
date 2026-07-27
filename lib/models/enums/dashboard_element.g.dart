// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_element.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardElementAdapter extends TypeAdapter<DashboardElement> {
  @override
  final typeId = 12;

  @override
  DashboardElement read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DashboardElement.ExposedProfile;
      case 1:
        return DashboardElement.ExposedControls;
      case 2:
        return DashboardElement.SceneButtons;
      case 3:
        return DashboardElement.StudioModeTransition;
      case 4:
        return DashboardElement.StudioModeConfig;
      case 5:
        return DashboardElement.ScenePreview;
      case 6:
        return DashboardElement.SceneItems;
      case 7:
        return DashboardElement.SceneItemsAudio;
      case 8:
        return DashboardElement.StreamChat;
      case 9:
        return DashboardElement.OBSStats;
      default:
        return DashboardElement.ExposedProfile;
    }
  }

  @override
  void write(BinaryWriter writer, DashboardElement obj) {
    switch (obj) {
      case DashboardElement.ExposedProfile:
        writer.writeByte(0);
      case DashboardElement.ExposedControls:
        writer.writeByte(1);
      case DashboardElement.SceneButtons:
        writer.writeByte(2);
      case DashboardElement.StudioModeTransition:
        writer.writeByte(3);
      case DashboardElement.StudioModeConfig:
        writer.writeByte(4);
      case DashboardElement.ScenePreview:
        writer.writeByte(5);
      case DashboardElement.SceneItems:
        writer.writeByte(6);
      case DashboardElement.SceneItemsAudio:
        writer.writeByte(7);
      case DashboardElement.StreamChat:
        writer.writeByte(8);
      case DashboardElement.OBSStats:
        writer.writeByte(9);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

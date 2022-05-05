import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../type_ids.dart';

part 'log_level.g.dart';

@HiveType(typeId: TypeIDs.LogLevel)
enum LogLevel {
  @HiveField(0)
  Info,

  @HiveField(1)
  Warning,

  @HiveField(2)
  Error,
}

extension LogLevelFunctions on LogLevel {
  String get name => {
        LogLevel.Info: 'Info',
        LogLevel.Warning: 'Warning',
        LogLevel.Error: 'Error',
      }[this]!;

  String get prefix => {
        LogLevel.Info: '[INFO]',
        LogLevel.Warning: '[WARNING]',
        LogLevel.Error: '[ERROR]',
      }[this]!;

  Color get color => {
        LogLevel.Info: Colors.lightBlueAccent,
        LogLevel.Warning: Colors.orangeAccent,
        LogLevel.Error: Colors.redAccent,
      }[this]!;
}

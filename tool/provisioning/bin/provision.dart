import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:provisioning/src/commands.dart';

Future<void> main(List<String> args) async {
  final runner = buildRunner();
  int code;
  try {
    code = await runner.run(args) ?? 0;
  } on UsageException catch (e) {
    stderr.writeln(e);
    code = 64;
  }
  exitCode = code;
}

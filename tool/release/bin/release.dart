// OBS Blade store release tool - see tool/release/README.md.
//
//   dart run tool/release/bin/release.dart <command> [platform] [--yes]
//
// Commands that write to a store (beta, metadata, submit, promote, halt)
// print what they would do and stop unless --yes is given.

// ignore_for_file: avoid_print - CLI output is the product.

import 'dart:io';

import 'package:args/args.dart';
import 'package:release/src/commands.dart';
import 'package:release/src/project.dart';

const String usage = '''
Usage: release <command> [ios|android] [--yes]

  status                      what's live, in review and on each track
  preflight [ios|android]     checks without building (both when omitted)
  bump                        next build number (YYYYMMDDNN) in pubspec
  build ios|android           store build (+ preflight)
  beta ios|android            TestFlight internal / Play internal track
  metadata ios|android        listing text + screenshots
  submit ios                  attach the build (+ subscriptions), submit for review
  promote android [--rollout 1.0]   internal -> production
  halt android                halt the production rollout

  --yes    actually do it (store-writing commands dry-run without it)
''';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addFlag('yes', negatable: false)
    ..addOption('rollout', defaultsTo: '1')
    ..addFlag('help', abbr: 'h', negatable: false);
  final args = parser.parse(argv);
  final rest = args.rest;
  if (args['help'] as bool || rest.isEmpty) {
    print(usage);
    exit(rest.isEmpty ? 64 : 0);
  }

  final release = Release(Project.locate(), yes: args['yes'] as bool);
  final command = rest.first;
  final platform = rest.length > 1 ? rest[1] : null;

  String needPlatform(Set<String> allowed) {
    if (platform == null || !allowed.contains(platform)) {
      stderr.writeln('$command needs: ${allowed.join(' | ')}\n\n$usage');
      exit(64);
    }
    return platform;
  }

  final code = switch (command) {
    'status' => await release.status(),
    'preflight' =>
      await release.preflight(
            platform == null
                ? {'ios', 'android'}
                : {
                    needPlatform({'ios', 'android'}),
                  },
          )
          ? 0
          : 1,
    'bump' => release.bump(),
    'build' => await release.build(needPlatform({'ios', 'android'})),
    'beta' => await release.beta(needPlatform({'ios', 'android'})),
    'metadata' => await release.metadata(needPlatform({'ios', 'android'})),
    'submit' => (needPlatform({'ios'}), await release.submit()).$2,
    'promote' => (
      needPlatform({'android'}),
      await release.promote(args['rollout'] as String),
    ).$2,
    'halt' => (needPlatform({'android'}), await release.halt()).$2,
    _ => () {
      stderr.writeln('Unknown command: $command\n\n$usage');
      return 64;
    }(),
  };
  exit(code);
}

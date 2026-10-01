// test_gate.dart — full-suite test gate that absorbs the headless runner's
// flutter_tester load flake: since Flutter 3.47 some runs fail to LOAD a
// random test file with "Unable to connect to flutter_tester process:
// WebSocketException: Invalid WebSocket upgrade request". That is a
// runner/infrastructure failure, not a test failure — the fix is to
// re-run the file. This wrapper does that automatically.
//
// Run from the repo root:
//   dart tool/test_gate.dart [test targets...]     (default: test/)
//   dart tool/test_gate.dart --runs=3 test/websocket/
//
// It runs `flutter test -j 1 --reporter json` (always serial — this
// wrapper exists for the NAS), classifies every testDone event, re-runs
// files whose synthetic "loading <path>" test died with exactly the
// flutter_tester WebSocketException signature (up to 3 attempts per
// file) and exits 0 iff no REAL test failure remains. A compile error
// in a test file is a real failure and is never retried.
//
// Options:
//   --runs=N    repeat the whole gate N times, fail fast on the first
//               non-clean run
//   --verbose   stream the raw JSON reporter lines through
//   --selftest  run the classifier against a canned transcript (no
//               flutter invocation) and exit
//
// The flutter binary is ~/flutter/bin/flutter when present, otherwise
// `flutter` from PATH.

// ignore_for_file: avoid_print — this is a CLI tool; stdout is the product.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String kLoadTestPrefix = 'loading ';

/// Every fragment that must appear in the load error for it to count as
/// the runner flake - narrow on purpose so compile errors or genuine
/// load-time exceptions are reported as real failures
const List<String> kLoadFlakeSignature = [
  'Unable to connect to flutter_tester process',
  'WebSocketException',
];

/// Attempts per file before a persistent load flake is reported as a
/// failure (the initial run is attempt 1)
const int kMaxAttemptsPerFile = 3;

class _TestRecord {
  _TestRecord(this.name, this.suiteID);

  final String name;
  final int? suiteID;
  final List<String> errors = [];
}

class Failure {
  Failure(this.name, this.path, this.error);

  final String name;
  final String path;
  final String error;
}

/// Accumulates the JSON reporter events of one `flutter test` invocation
/// and classifies the outcome of every test
class GateRun {
  final Map<int, String> _suitePaths = {};
  final Map<int, _TestRecord> _tests = {};

  int passed = 0;
  int skipped = 0;
  bool sawDone = false;

  /// Tests that failed for real (assertion, compile error, unexpected
  /// load-time exception, ...)
  final List<Failure> realFailures = [];

  /// Files whose synthetic loading test died with the runner flake
  final Set<String> loadFlakeFiles = {};

  void handleEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'suite':
        final suite = event['suite'] as Map<String, dynamic>;
        _suitePaths[suite['id'] as int] = suite['path'] as String? ?? '';
      case 'testStart':
        final test = event['test'] as Map<String, dynamic>;
        _tests[test['id'] as int] = _TestRecord(
          test['name'] as String? ?? '',
          test['suiteID'] as int?,
        );
      case 'error':
        _tests[event['testID'] as int]?.errors.add(
          event['error'] as String? ?? '',
        );
      case 'testDone':
        final record = _tests[event['testID'] as int];
        if (record == null) return;
        if (event['skipped'] == true) {
          skipped++;
          return;
        }
        if (event['result'] == 'success') {
          passed++;
          return;
        }
        if (_isLoadFlake(record)) {
          loadFlakeFiles.add(_pathOf(record));
        } else {
          realFailures.add(
            Failure(record.name, _pathOf(record), record.errors.join('\n')),
          );
        }
      case 'done':
        sawDone = true;
    }
  }

  bool _isLoadFlake(_TestRecord record) {
    if (!record.name.startsWith(kLoadTestPrefix)) return false;
    final text = record.errors.join('\n');
    return kLoadFlakeSignature.every(text.contains);
  }

  String _pathOf(_TestRecord record) {
    if (record.name.startsWith(kLoadTestPrefix)) {
      return record.name.substring(kLoadTestPrefix.length);
    }
    return _suitePaths[record.suiteID] ?? record.name;
  }
}

String flutterBinary() {
  final home = Platform.environment['HOME'];
  if (home != null && File('$home/flutter/bin/flutter').existsSync()) {
    return '$home/flutter/bin/flutter';
  }
  return 'flutter';
}

/// One `flutter test -j 1 --reporter json` invocation, parsed live
Future<GateRun> runFlutterTest(
  List<String> targets, {
  bool verbose = false,
}) async {
  final run = GateRun();
  final process = await Process.start(flutterBinary(), [
    'test',
    '-j',
    '1',
    '--reporter',
    'json',
    ...targets,
  ]);

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
        if (verbose) print('  | $line');
        Object? decoded;
        try {
          decoded = jsonDecode(line);
        } catch (_) {
          return; // non-JSON noise (tool warnings etc.)
        }
        if (decoded is Map<String, dynamic>) {
          run.handleEvent(decoded);
        }
      });
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach(stderr.writeln);

  await Future.wait<Object?>([process.exitCode, stdoutDone, stderrDone]);
  return run;
}

/// Prints [failure] with a trimmed error body
void _printFailure(Failure failure) {
  print('  REAL FAILURE: ${failure.path}');
  print('    ${failure.name}');
  final lines = failure.error.split('\n');
  for (final line in lines.take(6)) {
    print('    $line');
  }
  if (lines.length > 6) print('    …');
}

/// One full gate pass: initial run + retries. Returns the exit code.
Future<int> gate(List<String> targets, {bool verbose = false}) async {
  print('▶ flutter test -j 1 ${targets.join(' ')}');
  var run = await runFlutterTest(targets, verbose: verbose);

  var passed = run.passed;
  var skipped = run.skipped;
  final realFailures = [...run.realFailures];
  final attempts = <String, int>{
    for (final file in run.loadFlakeFiles) file: 1,
  };
  var pendingFlakes = run.loadFlakeFiles.toSet();
  final recovered = <String>[];

  while (pendingFlakes.isNotEmpty) {
    final retryable = pendingFlakes
        .where((file) => attempts[file]! < kMaxAttemptsPerFile)
        .toList();
    final exhausted = pendingFlakes
        .where((file) => attempts[file]! >= kMaxAttemptsPerFile)
        .toList();
    for (final file in exhausted) {
      realFailures.add(
        Failure(
          'loading $file',
          file,
          'still fails to load after $kMaxAttemptsPerFile attempts '
              '(flutter_tester WebSocketException every time)',
        ),
      );
      pendingFlakes.remove(file);
    }
    if (retryable.isEmpty) break;

    print(
      '↻ runner load flake in ${retryable.length} file(s), re-running '
      '(attempt ${retryable.map((f) => attempts[f]! + 1).join(', ')}):',
    );
    for (final file in retryable) {
      print('    $file');
      attempts[file] = attempts[file]! + 1;
    }

    run = await runFlutterTest(retryable, verbose: verbose);
    passed += run.passed;
    skipped += run.skipped;
    realFailures.addAll(run.realFailures);
    for (final file in run.loadFlakeFiles) {
      attempts[file] = (attempts[file] ?? 1);
    }
    final flakedAgain = run.loadFlakeFiles.intersection(pendingFlakes);
    recovered.addAll(pendingFlakes.difference(flakedAgain));
    pendingFlakes = flakedAgain;
  }

  print('');
  print('═══ test gate summary ═══');
  print(
    '  passed: $passed   skipped: $skipped   '
    'real failures: ${realFailures.length}',
  );
  if (recovered.isNotEmpty) {
    print('  recovered on retry (runner load flake):');
    for (final file in recovered) {
      print('    $file');
    }
  }
  if (realFailures.isNotEmpty) {
    print('  failing:');
    for (final failure in realFailures) {
      _printFailure(failure);
    }
  }

  if (!run.sawDone && passed == 0 && realFailures.isEmpty) {
    print(
      '  the runner produced no reportable result - treating this as '
      'an infrastructure failure, not a clean gate',
    );
    return 2;
  }
  if (realFailures.isNotEmpty) {
    print('  gate: FAILED');
    return 1;
  }
  print('  gate: CLEAN');
  return 0;
}

void _check(bool condition, String description) {
  if (!condition) {
    print('selftest FAILED: $description');
    exit(1);
  }
  print('  ok: $description');
}

/// Feeds a canned reporter transcript through [GateRun] and asserts the
/// classification - proves the flake signature is retried while compile
/// errors and assertion failures are not
void selfTest() {
  Map<String, dynamic> event(Map<String, dynamic> json) => json;

  GateRun feed(List<Map<String, dynamic>> events) {
    final run = GateRun();
    for (final e in events) {
      run.handleEvent(e);
    }
    return run;
  }

  final flake = feed([
    event({
      'type': 'suite',
      'suite': {'id': 0, 'platform': 'vm', 'path': 'test/flaky_test.dart'},
    }),
    event({
      'type': 'testStart',
      'test': {'id': 1, 'name': 'loading test/flaky_test.dart', 'suiteID': 0},
    }),
    event({
      'type': 'error',
      'testID': 1,
      'error':
          'Unable to connect to flutter_tester process: '
          'WebSocketException: Invalid WebSocket upgrade request',
      'stackTrace': '',
      'isFailure': false,
    }),
    event({'type': 'testDone', 'testID': 1, 'result': 'error'}),
  ]);
  _check(
    flake.loadFlakeFiles.single == 'test/flaky_test.dart',
    'flutter_tester WebSocketException load error is a retryable flake',
  );
  _check(flake.realFailures.isEmpty, 'flake produces no real failure');

  final compileError = feed([
    event({
      'type': 'suite',
      'suite': {'id': 0, 'platform': 'vm', 'path': 'test/broken_test.dart'},
    }),
    event({
      'type': 'testStart',
      'test': {'id': 1, 'name': 'loading test/broken_test.dart', 'suiteID': 0},
    }),
    event({
      'type': 'error',
      'testID': 1,
      'error': "Error: Expected ';' after this.",
      'stackTrace': '',
      'isFailure': false,
    }),
    event({'type': 'testDone', 'testID': 1, 'result': 'error'}),
  ]);
  _check(
    compileError.loadFlakeFiles.isEmpty,
    'compile error on load is NOT a retryable flake',
  );
  _check(
    compileError.realFailures.single.path == 'test/broken_test.dart',
    'compile error on load is a real failure',
  );

  final assertion = feed([
    event({
      'type': 'suite',
      'suite': {'id': 0, 'platform': 'vm', 'path': 'test/real_test.dart'},
    }),
    event({
      'type': 'testStart',
      'test': {'id': 1, 'name': 'real thing works', 'suiteID': 0},
    }),
    event({'type': 'testDone', 'testID': 1, 'result': 'success'}),
    event({
      'type': 'testStart',
      'test': {'id': 2, 'name': 'real thing breaks', 'suiteID': 0},
    }),
    event({
      'type': 'error',
      'testID': 2,
      'error': 'Expected: <1> Actual: <2>',
      'stackTrace': '',
      'isFailure': true,
    }),
    event({'type': 'testDone', 'testID': 2, 'result': 'failure'}),
    event({'type': 'done', 'success': false}),
  ]);
  _check(assertion.passed == 1, 'passing test counted');
  _check(
    assertion.realFailures.single.name == 'real thing breaks' &&
        assertion.loadFlakeFiles.isEmpty,
    'assertion failure is a real failure, not a flake',
  );
  _check(assertion.sawDone, 'done event tracked');

  print('selftest: all classifier checks passed');
}

Future<void> main(List<String> args) async {
  final targets = <String>[];
  var runs = 1;
  var verbose = false;
  for (final arg in args) {
    if (arg == '--selftest') {
      selfTest();
      return;
    } else if (arg == '--verbose') {
      verbose = true;
    } else if (arg.startsWith('--runs=')) {
      runs = int.tryParse(arg.substring('--runs='.length)) ?? 1;
      if (runs < 1) runs = 1;
    } else if (arg == '-h' || arg == '--help') {
      print(
        'Usage: dart tool/test_gate.dart [--runs=N] [--verbose] '
        '[--selftest] [test targets...]',
      );
      print(
        '  default target: test/  (exit 0 iff no real failures remain '
        'after load-flake retries)',
      );
      return;
    } else {
      targets.add(arg);
    }
  }
  if (targets.isEmpty) targets.add('test/');

  for (var i = 1; i <= runs; i++) {
    if (runs > 1) print('── gate run $i/$runs ──');
    final code = await gate(targets, verbose: verbose);
    if (code != 0) {
      if (runs > 1) print('run $i/$runs was not clean - stopping');
      exitCode = code;
      return;
    }
  }
  if (runs > 1) print('$runs consecutive clean gate runs');
}

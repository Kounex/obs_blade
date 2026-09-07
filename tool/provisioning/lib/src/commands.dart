import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' show ArgParser;
import 'package:args/command_runner.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'api_client.dart';
import 'asc_jwt.dart';
import 'asc_provisioner.dart';
import 'gcp_youtube.dart';
import 'play_payloads.dart';
import 'play_provisioner.dart';

/// Resolves a credential/config value: explicit CLI flag wins, else the
/// environment variable (the maintainer keeps these in `~/.localrc`,
/// sourced into zsh). Pure so it is unit-testable.
String? argOrEnv(String? argValue, String? envValue) {
  if (argValue != null && argValue.isNotEmpty) return argValue;
  if (envValue != null && envValue.isNotEmpty) return envValue;
  return null;
}

/// `provision gcp-youtube` — GCP project + YouTube Data API v3 + restricted
/// API key for the youtube_spike quota measurement.
class GcpYoutubeCommand extends Command<int> {
  GcpYoutubeCommand() {
    argParser
      ..addOption('project-id',
          help: 'GCP project id to create or reuse. Falls back to '
              '\$GCP_PROJECT_ID, then the default.',
          defaultsTo: null)
      ..addOption('key-display-name',
          help: 'Display name of the API key (used to find it again on '
              're-runs).',
          defaultsTo: 'obs-blade-youtube')
      ..addOption('out-file',
          help: 'Write the API key to this file (chmod 600) instead of '
              'printing it to stdout.');
    addDryRunFlag(argParser);
  }

  @override
  final name = 'gcp-youtube';
  @override
  final description =
      'Create/reuse a GCP project, enable YouTube Data API v3 and create an '
      'API key restricted to it.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final dryRun = args['dry-run'] as bool;
    final projectId = argOrEnv(args['project-id'] as String?,
            Platform.environment['GCP_PROJECT_ID']) ??
        'obs-blade';

    if (!dryRun) {
      final which = await Process.run('which', ['gcloud']);
      if (which.exitCode != 0) {
        stderr.writeln('gcloud CLI not found on PATH. Install it first:');
        stderr.writeln('  https://cloud.google.com/sdk/docs/install');
        stderr.writeln('Then run: gcloud auth login');
        return 2;
      }
    }

    final provisioner = GcpYoutubeProvisioner(
      projectId: projectId,
      keyDisplayName: args['key-display-name'] as String,
      dryRun: dryRun,
      gcloud: realGcloudRunner,
    );

    String? key;
    try {
      key = await provisioner.run();
    } on GcpException catch (e) {
      stderr.writeln(e);
      return 1;
    }

    if (dryRun) {
      _printGcpManualSteps(projectId);
      return 0;
    }

    final outFile = args['out-file'] as String?;
    if (outFile != null) {
      final file = File(outFile);
      await file.parent.create(recursive: true);
      await file.writeAsString('$key\n');
      await Process.run('chmod', ['600', file.path]);
      print('API key written to ${file.path} (chmod 600).');
    } else {
      // Printed exactly once, nowhere else.
      print('API key: $key');
      print('(Shown once here — it is retrievable any time via '
          '`gcloud services api-keys list/get-key-string`.)');
    }
    _printGcpManualSteps(projectId);
    return 0;
  }

  void _printGcpManualSteps(String projectId) {
    print('');
    print('Manual remainder (console-only, cannot be scripted):');
    print('  1. OAuth consent screen: https://console.cloud.google.com/'
        'apis/credentials/consent?project=$projectId');
    print('  2. OAuth "TVs and limited input devices" client for the device '
        'flow: https://console.cloud.google.com/apis/credentials'
        '?project=$projectId');
    print('  See docs/youtube-native-chat-audit.md for why.');
  }
}

/// `provision asc-products` — Pro subscription group, pro_yearly/pro_monthly
/// subscriptions and the pro_lifetime non-consumable via the App Store
/// Connect API.
class AscProductsCommand extends Command<int> {
  AscProductsCommand() {
    argParser
      ..addOption('key-path',
          help: 'Path to the App Store Connect API .p8 private key. '
              'Falls back to \$ASC_KEY_PATH.')
      ..addOption('key-id',
          help: 'App Store Connect API key id. Falls back to \$ASC_KEY_ID.')
      ..addOption('issuer-id',
          help: 'App Store Connect API issuer id (UUID). Falls back to '
              '\$ASC_ISSUER_ID.')
      ..addOption('app-id',
          help: 'Numeric App Store Connect app id (App Information → '
              'Apple ID). Falls back to \$ASC_APP_ID.')
      ..addOption('yearly-price-usd',
          help: 'US price for pro_yearly.', defaultsTo: '49.99')
      ..addOption('monthly-price-usd',
          help: 'US price for pro_monthly.', defaultsTo: '4.99')
      ..addOption('lifetime-price-usd',
          help: 'US price for pro_lifetime.', defaultsTo: '99.99');
    addDryRunFlag(argParser);
  }

  @override
  final name = 'asc-products';
  @override
  final description =
      'Create/reuse the App Store Connect Pro subscription group, the '
      'pro_yearly/pro_monthly subscriptions and the pro_lifetime '
      'non-consumable, with en-US localizations (drift-reconciled) and '
      'nominal-parity pricing in every available territory.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final dryRun = args['dry-run'] as bool;

    final appId = argOrEnv(
        args['app-id'] as String?, Platform.environment['ASC_APP_ID']);
    if (appId == null) {
      stderr.writeln('Missing required --app-id (or \$ASC_APP_ID).');
      return 64;
    }

    ApiClient client;
    if (dryRun) {
      client = DryRunApiClient(serviceName: 'asc');
    } else {
      final env = Platform.environment;
      final keyPath =
          argOrEnv(args['key-path'] as String?, env['ASC_KEY_PATH']);
      final keyId = argOrEnv(args['key-id'] as String?, env['ASC_KEY_ID']);
      final issuerId =
          argOrEnv(args['issuer-id'] as String?, env['ASC_ISSUER_ID']);
      if (keyPath == null || keyId == null || issuerId == null) {
        stderr.writeln(
            'Missing credentials: --key-path, --key-id and --issuer-id are '
            'required (unless --dry-run). Set them via flags or the '
            'ASC_KEY_PATH / ASC_KEY_ID / ASC_ISSUER_ID env vars '
            '(e.g. exported from ~/.localrc).');
        return 64;
      }
      final pemFile = File(keyPath);
      if (!pemFile.existsSync()) {
        stderr.writeln('ASC key file not found: $keyPath');
        return 64;
      }
      final pem = await pemFile.readAsString();
      final token = buildAscJwt(
          privateKeyPem: pem, keyId: keyId, issuerId: issuerId);
      client = HttpApiClient(
          baseUrl: 'https://api.appstoreconnect.apple.com', token: token);
    }

    final provisioner = AscProvisioner(client: client, appId: appId);
    bool ok;
    try {
      ok = await provisioner.run(
        subscriptions: [
          SubscriptionSpec(
            productId: 'pro_yearly',
            name: 'Pro - Yearly',
            description: 'Yearly Pro Subscription',
            subscriptionPeriod: 'ONE_YEAR',
            priceUsd: args['yearly-price-usd'] as String,
          ),
          SubscriptionSpec(
            productId: 'pro_monthly',
            name: 'Pro - Monthly',
            description: 'Monthly Pro Subscription',
            subscriptionPeriod: 'ONE_MONTH',
            priceUsd: args['monthly-price-usd'] as String,
          ),
        ],
        lifetimePriceUsd: args['lifetime-price-usd'] as String,
      );
    } on ApiException catch (e) {
      stderr.writeln(e);
      return 1;
    }

    print('');
    print('Manual remainder (console-only):');
    print('  - Review + submit the new products with the next app version:');
    print('    https://appstoreconnect.apple.com/apps/$appId/distribution/'
        'subscriptionGroups');
    print('  - Attach all three products to the RevenueCat entitlement '
        '`pro` (see docs/revenuecat-setup.md §3).');
    return ok ? 0 : 1;
  }
}

/// `provision play-products` — Play subscription (pro_yearly/pro_monthly
/// base plans) + pro_lifetime one-time product via androidpublisher v3.
class PlayProductsCommand extends Command<int> {
  PlayProductsCommand() {
    argParser
      ..addOption('service-account-json',
          help: 'Path to the Play API service-account JSON key. Falls back '
              'to \$GOOGLE_APPLICATION_CREDENTIALS.')
      ..addOption('package-name',
          help: 'Android applicationId. Defaults to the one in '
              'android/app/build.gradle.')
      ..addOption('subscription-id',
          help: 'Subscription product id holding the base plans.',
          defaultsTo: 'pro')
      ..addOption('yearly-price-usd',
          help: 'US price for the yearly base plan.', defaultsTo: '49.99')
      ..addOption('monthly-price-usd',
          help: 'US price for the monthly base plan.', defaultsTo: '4.99')
      ..addOption('lifetime-price-usd',
          help: 'US price for the lifetime one-time product.',
          defaultsTo: '99.99')
      ..addFlag('activate',
          help: 'Activate base plans / the purchase option after creation.',
          defaultsTo: true);
    addDryRunFlag(argParser);
  }

  @override
  final name = 'play-products';
  @override
  final description =
      'Create/reuse the Play subscription product with pro_yearly/'
      'pro_monthly base plans and the pro_lifetime one-time product, with '
      'US pricing.';

  @override
  Future<int> run() async {
    final args = argResults!;
    final dryRun = args['dry-run'] as bool;

    String packageName;
    try {
      packageName = args['package-name'] as String? ?? readApplicationId();
    } on StateError catch (e) {
      stderr.writeln('${e.message} (or pass --package-name)');
      return 64;
    }

    ApiClient client;
    if (dryRun) {
      client = DryRunApiClient(serviceName: 'play');
    } else {
      final saPath = argOrEnv(args['service-account-json'] as String?,
          Platform.environment['GOOGLE_APPLICATION_CREDENTIALS']);
      if (saPath == null) {
        stderr.writeln('Missing --service-account-json (unless --dry-run). '
            'Or export GOOGLE_APPLICATION_CREDENTIALS (e.g. from ~/.localrc).');
        return 64;
      }
      final saFile = File(saPath);
      if (!saFile.existsSync()) {
        stderr.writeln('Service-account JSON not found: $saPath');
        return 64;
      }
      final credentials = ServiceAccountCredentials.fromJson(
          jsonDecode(await saFile.readAsString()));
      final authClient = await clientViaServiceAccount(
          credentials, ['https://www.googleapis.com/auth/androidpublisher']);
      client = HttpApiClient(
        baseUrl: 'https://androidpublisher.googleapis.com',
        client: authClient, // injects/refreshes the Authorization header
      );
    }

    final provisioner = PlayProvisioner(
      client: client,
      packageName: packageName,
      subscriptionProductId: args['subscription-id'] as String,
      activate: args['activate'] as bool,
    );
    bool ok;
    try {
      ok = await provisioner.run(
        basePlans: [
          BasePlanSpec(
            basePlanId: 'pro-yearly',
            billingPeriodDuration: 'P1Y',
            priceUsd: args['yearly-price-usd'] as String,
          ),
          BasePlanSpec(
            basePlanId: 'pro-monthly',
            billingPeriodDuration: 'P1M',
            priceUsd: args['monthly-price-usd'] as String,
          ),
        ],
        lifetimePriceUsd: args['lifetime-price-usd'] as String,
      );
    } on ApiException catch (e) {
      stderr.writeln(e);
      return 1;
    }

    print('');
    print('Manual remainder (console-only):');
    print('  - Review the products + prices in Play Console → Monetize → '
        'Products (other territories default off the US price — extend '
        'there if wanted).');
    print('  - Attach the products to the RevenueCat entitlement `pro` '
        '(Play store ids: `${args['subscription-id']}:pro-yearly`, '
        '`${args['subscription-id']}:pro-monthly`, `pro_lifetime` — see '
        'docs/revenuecat-setup.md §3).');
    return ok ? 0 : 1;
  }
}

void addDryRunFlag(ArgParser parser) {
  parser.addFlag('dry-run',
      help: 'Print every request/command without sending anything.');
}

/// Reads the applicationId from android/app/build.gradle, walking up from
/// the current directory until the repo root is found.
String readApplicationId() {
  var dir = Directory.current;
  while (true) {
    final gradle = File('${dir.path}/android/app/build.gradle');
    if (gradle.existsSync()) {
      final match = RegExp('''applicationId\\s+["']([^"']+)["']''')
          .firstMatch(gradle.readAsStringSync());
      if (match != null) return match.group(1)!;
      throw StateError(
          'No applicationId found in ${gradle.path}');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
          'Could not find android/app/build.gradle above ${Directory.current.path}');
    }
    dir = parent;
  }
}

CommandRunner<int> buildRunner() {
  final runner = CommandRunner<int>(
      'provision', 'OBS Blade store/GCP provisioning automation.')
    ..addCommand(GcpYoutubeCommand())
    ..addCommand(AscProductsCommand())
    ..addCommand(PlayProductsCommand());
  return runner;
}

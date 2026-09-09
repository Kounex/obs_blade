import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../../../../../../utils/youtube/youtube_live_chat_service.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'chat_type_brand.dart';
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';
import 'youtube_device_code_dialog.dart';

/// Any valid video id probes an API key — `videos.list` answers 200 for a
/// working key regardless of the video's live state, 400/403 for a bad one.
const String kYouTubeApiKeyProbeVideoId = 'dQw4w9WgXcQ';

/// Opens the native YouTube chat setup sheet — the single entry point for
/// the "unconfigured" CTAs (empty state, account control, options sheet).
Future<void> showYouTubeSetupSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.86,
      builder: (sheetContext) => YouTubeSetupSheet(hostContext: context),
    );

/// Configuration UX for the native YouTube chat: explains the (free) Google
/// Cloud API key requirement, validates a pasted key with a live
/// `videos.list` probe, holds the optional OAuth client credentials behind
/// an advanced section (sign-in enables writing/moderating), and links out
/// to the Google Cloud Console. Persisted to the YouTube settings keys on
/// save; the chat store is reloaded/re-initialized afterwards.
class YouTubeSetupSheet extends StatefulWidget {
  /// Context of the sheet's opener — the sign-in dialog needs a context
  /// that survives this sheet being popped.
  final BuildContext hostContext;

  /// Test seam — probes run through this service instead of a live one.
  final YouTubeLiveChatService? chatService;

  const YouTubeSetupSheet({
    super.key,
    required this.hostContext,
    this.chatService,
  });

  @override
  State<YouTubeSetupSheet> createState() => _YouTubeSetupSheetState();
}

class _YouTubeSetupSheetState extends State<YouTubeSetupSheet> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  late final YouTubeLiveChatService _chatService;

  bool _testing = false;

  /// Tri-state probe result: null = untested / edited since last test.
  bool? _keyValid;
  String? _keyError;

  bool get _storeRegistered => GetIt.instance.isRegistered<YouTubeChatStore>();

  YouTubeChatStore? get _store =>
      this._storeRegistered ? GetIt.instance<YouTubeChatStore>() : null;

  @override
  void initState() {
    super.initState();
    this._chatService = this.widget.chatService ?? YouTubeLiveChatService();

    String read(SettingsKeys key) {
      if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return '';
      final value = Hive.box(HiveKeys.Settings.name).get(key.name);
      return value is String ? value : '';
    }

    this._apiKeyController = TextEditingController(
      text: read(SettingsKeys.YouTubeApiKey),
    );
    this._clientIdController = TextEditingController(
      text: read(SettingsKeys.YouTubeOAuthClientId),
    );
    this._clientSecretController = TextEditingController(
      text: read(SettingsKeys.YouTubeOAuthClientSecret),
    );
  }

  @override
  void dispose() {
    this._apiKeyController.dispose();
    this._clientIdController.dispose();
    this._clientSecretController.dispose();
    super.dispose();
  }

  /// `videos.list` probe — a 200 means the key works (even when the probe
  /// video isn't live); typed API errors surface their message inline.
  Future<void> _testKey() async {
    final key = this._apiKeyController.text.trim();
    if (key.isEmpty || this._testing) return;
    this.setState(() {
      this._testing = true;
      this._keyValid = null;
      this._keyError = null;
    });
    try {
      await this._chatService.getActiveLiveChatId(
        kYouTubeApiKeyProbeVideoId,
        apiKey: key,
      );
      if (!this.mounted) return;
      this.setState(() => this._keyValid = true);
    } on YouTubeApiException catch (e) {
      if (!this.mounted) return;
      this.setState(() {
        this._keyValid = false;
        this._keyError = e.message;
      });
    } catch (_) {
      if (!this.mounted) return;
      this.setState(() {
        this._keyValid = false;
        this._keyError = 'Could not reach YouTube — check your connection';
      });
    } finally {
      if (this.mounted) this.setState(() => this._testing = false);
    }
  }

  /// Persist the three settings keys (empty fields delete their key) and
  /// re-initialize the store so the pane picks the configuration up.
  void _persist() {
    if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return;
    final settings = Hive.box(HiveKeys.Settings.name);
    void write(SettingsKeys key, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        settings.delete(key.name);
      } else {
        settings.put(key.name, trimmed);
      }
    }

    write(SettingsKeys.YouTubeApiKey, this._apiKeyController.text);
    write(SettingsKeys.YouTubeOAuthClientId, this._clientIdController.text);
    write(
      SettingsKeys.YouTubeOAuthClientSecret,
      this._clientSecretController.text,
    );

    final store = this._store;
    if (store != null) {
      store.reloadChannels();
      unawaited(store.init());
    }
  }

  void _save() {
    this._persist();
    if (this.mounted) Navigator.of(this.context).pop();
  }

  void _signIn() {
    /// Connect-without-Save must persist first — otherwise startLogin's
    /// !isConfigured guard bounces back to unconfigured and the
    /// device-code dialog spins forever.
    this._persist();
    Navigator.of(this.context).pop();
    startYouTubeLogin(this.widget.hostContext);
  }

  Widget _stepRow(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  /// Inline probe feedback under the key field.
  Widget _testStatus(BuildContext context) {
    if (this._testing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StylingHelper.isApple(context)
              ? const CupertinoActivityIndicator(radius: 8.0)
              : const SizedBox(
                  height: 14.0,
                  width: 14.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
          const SizedBox(width: AppSpacing.xs),
          Text('Testing key…', style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }
    if (this._keyValid == true) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 14.0,
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Text(
            'Key works — save it to enable native chat',
            key: const Key('youtube-setup-key-valid'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: CupertinoColors.activeGreen),
          ),
        ],
      );
    }
    if (this._keyValid == false) {
      final errorColor =
          (Theme.of(context).extension<AppStatusColors>() ??
                  AppStatusColors.standard)
              .unreachable;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 14.0,
            color: errorColor,
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Expanded(
            child: Text(
              this._keyError ?? 'YouTube rejected this key',
              key: const Key('youtube-setup-key-invalid'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: errorColor),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _pillButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
    Color? color,
    Key? key,
  }) {
    final effectiveColor =
        color ??
        ChatType.YouTube.brandColor ??
        Theme.of(context).colorScheme.secondary;
    return Pressable(
      key: key,
      haptic: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: onTap == null
              ? effectiveColor.withValues(alpha: 0.35)
              : effectiveColor,
          borderRadius: AppRadius.pill,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        ChatType.YouTube.brandColor ?? Theme.of(context).colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nativeChatSheetDragHandle(context),
            Text(
              'YouTube chat setup',
              style: nativeChatSheetTitleStyle(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Native YouTube chat reads through the official YouTube Data '
              'API, which needs a free Google Cloud API key:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            this._stepRow(
              context,
              '1',
              'Open the Google Cloud Console and create (or select) a project',
            ),
            this._stepRow(
              context,
              '2',
              'Enable the "YouTube Data API v3" for that project',
            ),
            this._stepRow(
              context,
              '3',
              'Create an API key (Credentials → Create credentials) and paste it below',
            ),
            Pressable(
              haptic: true,
              onTap: () async {
                final uri = Uri.parse('https://console.cloud.google.com');
                if (await launcher.canLaunchUrl(uri)) {
                  await launcher.launchUrl(
                    uri,
                    mode: launcher.LaunchMode.externalApplication,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.link,
                      size: 14.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Open console.cloud.google.com',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Heads up: chat entries are tied to a single video. When a '
              'streamer starts their next stream, its video id changes — '
              'update the entry (channel list → Add chat…, or edit the '
              'YouTube username) to reconnect.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'API key',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            NativeChatTextField(
              controller: this._apiKeyController,
              hintText: 'YouTube Data API key',
              focusBorderColor: accent,
              onChanged: (_) => this.setState(() => this._keyValid = null),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                this._pillButton(
                  context,
                  key: const Key('youtube-setup-test-key'),
                  label: 'Test key',
                  onTap:
                      this._apiKeyController.text.trim().isEmpty ||
                          this._testing
                      ? null
                      : this._testKey,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: this._testStatus(context)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CustomExpansionTile(
              headerText: 'Advanced: sign-in (optional)',
              headerTextStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              expandedBody: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading chat works with the API key alone. Sending '
                    'messages and moderating need a Google OAuth "TVs and '
                    'Limited Input" client — create one in the same console '
                    '(Credentials → Create credentials → OAuth client ID) '
                    'and paste its credentials here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NativeChatTextField(
                    controller: this._clientIdController,
                    hintText: 'OAuth client id',
                    focusBorderColor: accent,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  NativeChatTextField(
                    controller: this._clientSecretController,
                    hintText: 'OAuth client secret',
                    focusBorderColor: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                this._pillButton(
                  context,
                  key: const Key('youtube-setup-save'),
                  label: 'Save',
                  onTap: this._save,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (this._keyValid == true && this._storeRegistered)
                  Observer(
                    builder: (_) =>
                        this._store!.authState == YouTubeAuthState.signedIn
                        ? const SizedBox.shrink()
                        : this._pillButton(
                            context,
                            key: const Key('youtube-setup-sign-in'),
                            label: 'Connect YouTube',
                            onTap: this._signIn,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

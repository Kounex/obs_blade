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

/// YouTube Data API v3 in the Cloud Console library (the Enable button) -
/// the console opens it in the last used project
const String kYouTubeApiLibraryUrl =
    'https://console.cloud.google.com/apis/library/youtube.googleapis.com';

/// The API's own Credentials page (API keys and OAuth clients)
const String kYouTubeApiCredentialsUrl =
    'https://console.cloud.google.com/apis/api/youtube.googleapis.com/credentials';

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

/// Only the sign-in part of the setup sheet (OAuth client id + secret) -
/// for a read-only setup (API key, no client) that wants to write,
/// moderate and see its own chat. The full sheet stays in the chat
/// options ("Chat setup").
Future<void> showYouTubeSignInSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.86,
      builder: (sheetContext) =>
          YouTubeSetupSheet(hostContext: context, signInOnly: true),
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

  /// Just the OAuth client fields ([showYouTubeSignInSheet])
  final bool signInOnly;

  const YouTubeSetupSheet({
    super.key,
    required this.hostContext,
    this.chatService,
    this.signInOnly = false,
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

    /// "Save & connect" follows the client id field
    this._clientIdController.addListener(this._onClientIdChanged);
  }

  void _onClientIdChanged() {
    if (this.mounted) this.setState(() {});
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
        this._keyError = 'Could not reach YouTube - check your connection';
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

  /// Sign-in sheet: needs a client id; persists, then starts the device
  /// flow from the opener (this sheet is gone by then)
  void _saveAndConnect() {
    this._persist();
    Navigator.of(this.context).pop();
    startYouTubeLogin(this.widget.hostContext);
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
      final liveColor =
          (Theme.of(context).extension<AppStatusColors>() ??
                  AppStatusColors.standard)
              .live;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 14.0,
            color: liveColor,
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          Text(
            'Key works - save it to enable native chat',
            key: const Key('youtube-setup-key-valid'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: liveColor),
          ),
        ],
      );
    }
    if (this._keyValid == false) {
      final errorColor =
          (Theme.of(context).extension<AppStatusColors>() ??
                  AppStatusColors.standard)
              .destructive;
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
        Theme.of(context).buttonTheme.colorScheme?.secondary ??
        StylingHelper.accent_color;
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Link out to a Google Cloud Console page
  Widget _consoleLink(
    BuildContext context, {
    required String url,
    required String label,
  }) {
    return Pressable(
      haptic: true,
      onTap: () async {
        final uri = Uri.parse(url);
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
              color:
                  (Theme.of(context).extension<AppTextColors>() ??
                          AppTextColors.standard)
                      .highlightText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    (Theme.of(context).extension<AppTextColors>() ??
                            AppTextColors.standard)
                        .highlightText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The OAuth client fields (advanced section of the full sheet, the
  /// whole body of the sign-in sheet)
  Widget _clientFields(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  /// How to get an OAuth client - the Google Cloud Console path as it is
  /// laid out today (Credentials of the YouTube API, the consent screen in
  /// Google Auth Platform first, a test user, the TV client type)
  List<Widget> _signInSteps(BuildContext context) {
    return [
      this._stepRow(
        context,
        '1',
        'Open the Credentials page of the YouTube Data API v3 (link below) in the project of your API key',
      ),
      this._stepRow(
        context,
        '2',
        'Create credentials → OAuth client ID. Google asks for the consent screen first: "Configure consent screen" → Get started, any app name (e.g. OBS Blade), your email, audience "External", accept and Create',
      ),
      this._stepRow(
        context,
        '3',
        'Under Audience → Test users, add the Google account of your YouTube channel',
      ),
      this._stepRow(
        context,
        '4',
        'Back on Credentials: Create credentials → OAuth client ID, type "TVs and Limited Input devices", Create',
      ),
      this._stepRow(
        context,
        '5',
        'Copy the client ID and client secret into the fields below',
      ),
      this._consoleLink(
        context,
        url: kYouTubeApiCredentialsUrl,
        label: 'Open YouTube Data API credentials',
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Tip: while the app is in "Testing", Google signs you out after 7 '
        'days. "Publish app" under Audience keeps you signed in - Google '
        'then shows an "unverified app" note during sign-in that you can '
        'continue past.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  /// Sign-in sheet body: why, how, the two fields, Save / Save & connect
  List<Widget> _signInBody(BuildContext context, Color accent) {
    return [
      Text(
        'Reading chat works with your API key alone. To send messages, '
        'moderate and see your own chat as "You", sign in with your own '
        'Google OAuth client:',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      ...this._signInSteps(context),
      const SizedBox(height: AppSpacing.md),
      this._clientFields(context, accent),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          this._pillButton(
            context,
            key: const Key('youtube-sign-in-save'),
            label: 'Save',
            onTap: this._save,
          ),
          const SizedBox(width: AppSpacing.sm),
          this._pillButton(
            context,
            key: const Key('youtube-sign-in-connect'),
            label: 'Save & connect',
            onTap: this._clientIdController.text.trim().isEmpty
                ? null
                : this._saveAndConnect,
            color:
                Theme.of(context).buttonTheme.colorScheme?.secondary ??
                StylingHelper.accent_color,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        ChatType.YouTube.brandColor ??
        Theme.of(context).buttonTheme.colorScheme?.secondary ??
        StylingHelper.accent_color;

    /// Handle and title stay outside the scroll. The shared modal body
    /// caps the height and turns a pull past the top into a sheet drag.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nativeChatSheetDragHandle(context),
              Text(
                this.widget.signInOnly
                    ? 'YouTube sign-in'
                    : 'YouTube chat setup',
                style: nativeChatSheetTitleStyle(context),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0.0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: this.widget.signInOnly
                  ? this._signInBody(context, accent)
                  : [
                      Text(
                        'Native YouTube chat reads through the official YouTube Data '
                        'API, which needs a free Google Cloud API key:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      this._stepRow(
                        context,
                        '1',
                        'Open the YouTube Data API v3 page (link below), create or pick a project and press Enable',
                      ),
                      this._stepRow(
                        context,
                        '2',
                        'On that API page open Credentials → Create credentials → API key',
                      ),
                      this._stepRow(
                        context,
                        '3',
                        'Paste the key below and test it',
                      ),
                      this._consoleLink(
                        context,
                        url: kYouTubeApiLibraryUrl,
                        label: 'Open YouTube Data API v3',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tip: add a channel (@handle or channel link) instead of a '
                        'video - the chat then follows the channel\'s current '
                        'stream and switches to the next one on its own. A pasted '
                        'video id stays tied to that one stream.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'API key',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      NativeChatTextField(
                        controller: this._apiKeyController,
                        hintText: 'YouTube Data API key',
                        focusBorderColor: accent,
                        onChanged: (_) =>
                            this.setState(() => this._keyValid = null),
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
                        headerTextStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        expandedBody: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reading chat works with the API key alone. Sending '
                              'messages, moderating and your own chat as "You" '
                              'need a sign-in with your own Google OAuth client:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...this._signInSteps(context),
                            const SizedBox(height: AppSpacing.sm),
                            this._clientFields(context, accent),
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
                                  this._store!.authState ==
                                      YouTubeAuthState.signedIn
                                  ? const SizedBox.shrink()
                                  : this._pillButton(
                                      context,
                                      key: const Key('youtube-setup-sign-in'),
                                      label: 'Connect YouTube',
                                      onTap: this._signIn,
                                      color:
                                          Theme.of(context)
                                              .buttonTheme
                                              .colorScheme
                                              ?.secondary ??
                                          StylingHelper.accent_color,
                                    ),
                            ),
                        ],
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

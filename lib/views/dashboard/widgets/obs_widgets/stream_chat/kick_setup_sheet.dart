import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/kick/kick_auth_service.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'chat_type_brand.dart';
import 'native_chat_chrome.dart';
import 'native_chat_text_field.dart';

/// Opens the native Kick chat setup sheet — the single entry point for
/// the account CTAs (account control pill, read-only input strip).
Future<void> showKickSetupSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.86,
      builder: (sheetContext) => KickSetupSheet(hostContext: context),
    );

/// Configuration + sign-in UX for the native Kick chat account. Reading
/// chat is anonymous and needs nothing; sending and moderating need a
/// Kick sign-in. Kick has no device flow, so the user opens the PKCE
/// authorize URL in a browser and pastes the redirect URL back. When the
/// build has no app-owned client ([kKickOAuthClientId] empty), the sheet
/// also asks for a bring-your-own client id and secret. The signed-in
/// state shows the connected account and the sign-out action.
class KickSetupSheet extends StatefulWidget {
  /// Context of the sheet's opener — kept for parity with the YouTube
  /// sheet (its sign-in dialog needs a context that survives the sheet).
  final BuildContext hostContext;

  const KickSetupSheet({super.key, required this.hostContext});

  @override
  State<KickSetupSheet> createState() => _KickSetupSheetState();
}

class _KickSetupSheetState extends State<KickSetupSheet> {
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;
  late final TextEditingController _redirectController;

  bool _openingBrowser = false;
  bool _connecting = false;

  bool get _storeRegistered => GetIt.instance.isRegistered<KickChatStore>();

  KickChatStore? get _store =>
      this._storeRegistered ? GetIt.instance<KickChatStore>() : null;

  @override
  void initState() {
    super.initState();

    String read(SettingsKeys key) {
      if (!Hive.isBoxOpen(HiveKeys.Settings.name)) return '';
      final value = Hive.box(HiveKeys.Settings.name).get(key.name);
      return value is String ? value : '';
    }

    this._clientIdController = TextEditingController(
      text: read(SettingsKeys.KickOAuthClientId),
    );
    this._clientSecretController = TextEditingController(
      text: read(SettingsKeys.KickOAuthClientSecret),
    );
    this._redirectController = TextEditingController();
  }

  @override
  void dispose() {
    this._clientIdController.dispose();
    this._clientSecretController.dispose();
    this._redirectController.dispose();
    super.dispose();
  }

  /// Persist the two settings keys (empty fields delete their key).
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

    write(SettingsKeys.KickOAuthClientId, this._clientIdController.text);
    write(
      SettingsKeys.KickOAuthClientSecret,
      this._clientSecretController.text,
    );
  }

  /// "Open Kick login" — persist first (beginLogin resolves the client id
  /// from settings), then launch the authorize URL externally.
  Future<void> _openLogin() async {
    final store = this._store;
    if (store == null || this._openingBrowser) return;
    if (kKickOAuthClientId.isEmpty) this._persist();
    final uri = store.beginLogin();
    if (uri == null || !this.mounted) return;
    this.setState(() => this._openingBrowser = true);
    try {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } finally {
      if (this.mounted) this.setState(() => this._openingBrowser = false);
    }
  }

  /// "Connect" — the pasted redirect URL completes the login; on success
  /// the sheet closes (the account chip in the bar confirms the state).
  Future<void> _connect() async {
    final store = this._store;
    if (store == null || this._connecting) return;
    this._persist();
    this.setState(() => this._connecting = true);
    try {
      final ok = await store.completeLogin(this._redirectController.text);
      if (ok && this.mounted) Navigator.of(this.context).pop();
    } finally {
      if (this.mounted) this.setState(() => this._connecting = false);
    }
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

  Widget _pillButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
    Color? color,
    Key? key,
  }) {
    final effectiveColor =
        color ??
        ChatType.Kick.brandColor ??
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
            color: Colors.black,
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Inline auth-flow feedback (state mismatch, exchange failure, …).
  Widget _authError(BuildContext context, String error) {
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
            error,
            key: const Key('kick-setup-auth-error'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: errorColor),
          ),
        ),
      ],
    );
  }

  /// Signed-in section: avatar + username + sign-out (confirmation →
  /// revoke + wipe).
  Widget _signedInSection(BuildContext context, KickChatStore store) {
    final username = store.selfUsername;
    final profilePicture = store.selfProfilePicture;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: profilePicture != null && profilePicture.isNotEmpty
                  ? Image.network(
                      profilePicture,
                      width: 28.0,
                      height: 28.0,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(CupertinoIcons.person_fill, size: 20.0),
                    )
                  : const Icon(CupertinoIcons.person_fill, size: 20.0),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Signed in as ${username ?? 'your Kick account'}',
                key: const Key('kick-setup-signed-in'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        this._pillButton(
          context,
          key: const Key('kick-setup-sign-out'),
          label: 'Sign out',
          color:
              (Theme.of(context).extension<AppStatusColors>() ??
                      AppStatusColors.standard)
                  .destructive,
          onTap: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: ConfirmationDialog(
              title: 'Disconnect Kick?',
              body:
                  'Connected as ${username ?? 'your Kick account'}. You will be signed out of your Kick account — reading chat keeps working without an account.',
              okText: 'Disconnect',
              isYesDestructive: true,
              onOk: (_) => store.logout(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        ChatType.Kick.brandColor ??
        Theme.of(context).buttonTheme.colorScheme?.secondary ??
        StylingHelper.accent_color;

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
            Text('Kick chat setup', style: nativeChatSheetTitleStyle(context)),
            const SizedBox(height: AppSpacing.sm),
            if (this._storeRegistered)
              Observer(
                builder: (_) {
                  final store = this._store!;
                  if (store.isSignedInState) {
                    return this._signedInSection(context, store);
                  }
                  final appClient = kKickOAuthClientId.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appClient
                            ? 'Reading Kick chat needs no account. Sending '
                                  'messages and moderating sign you in with '
                                  'OBS Blade\'s Kick app. Kick has no device '
                                  'login, so the last step is pasting a URL.'
                            : 'Reading Kick chat needs no account. Sending '
                                  'messages and moderating need a Kick '
                                  'sign-in — and Kick has no device login, '
                                  'so bring your own (free) Kick app:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (appClient) ...[
                        this._stepRow(
                          context,
                          '1',
                          'Open the Kick login and approve OBS Blade',
                        ),
                        this._stepRow(
                          context,
                          '2',
                          'Paste the URL your browser lands on (it won\'t load — that\'s expected)',
                        ),
                      ] else ...[
                        this._stepRow(
                          context,
                          '1',
                          'Enable 2FA on your Kick account, then open kick.com/settings/developer and create an app',
                        ),
                        this._stepRow(
                          context,
                          '2',
                          'Register this redirect URL on the app:',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            bottom: AppSpacing.xs,
                          ),
                          child: Pressable(
                            haptic: true,
                            onTap: () async {
                              await Clipboard.setData(
                                const ClipboardData(
                                  text: kKickOAuthRedirectUri,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    kKickOAuthRedirectUri,
                                    key: const Key('kick-setup-redirect-uri'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              (Theme.of(context)
                                                          .extension<
                                                            AppTextColors
                                                          >() ??
                                                      AppTextColors.standard)
                                                  .highlightText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  CupertinoIcons.doc_on_doc,
                                  size: 14.0,
                                  color:
                                      (Theme.of(
                                                context,
                                              ).extension<AppTextColors>() ??
                                              AppTextColors.standard)
                                          .highlightText,
                                ),
                              ],
                            ),
                          ),
                        ),
                        this._stepRow(
                          context,
                          '3',
                          'Paste the app\'s client id and secret below',
                        ),
                        this._stepRow(
                          context,
                          '4',
                          'Open the Kick login, approve, and paste the URL your browser lands on (it won\'t load — that\'s expected)',
                        ),
                        Pressable(
                          haptic: true,
                          onTap: () async {
                            final uri = Uri.parse(
                              'https://kick.com/settings/developer',
                            );
                            if (await launcher.canLaunchUrl(uri)) {
                              await launcher.launchUrl(
                                uri,
                                mode: launcher.LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.link,
                                  size: 14.0,
                                  color:
                                      (Theme.of(
                                                context,
                                              ).extension<AppTextColors>() ??
                                              AppTextColors.standard)
                                          .highlightText,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Open kick.com/settings/developer',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color:
                                            (Theme.of(context)
                                                        .extension<
                                                          AppTextColors
                                                        >() ??
                                                    AppTextColors.standard)
                                                .highlightText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: AppSpacing.md),
                      this._pillButton(
                        context,
                        key: const Key('kick-setup-open-login'),
                        label: 'Open Kick login',
                        onTap: this._openingBrowser ? null : this._openLogin,
                      ),
                      if (store.authState == KickAuthState.awaitingRedirect ||
                          store.authState == KickAuthState.signingIn ||
                          store.authState == KickAuthState.error) ...[
                        const SizedBox(height: AppSpacing.md),
                        NativeChatTextField(
                          controller: this._redirectController,
                          hintText: 'Paste the redirect URL here',
                          focusBorderColor: accent,
                          key: const Key('kick-setup-redirect-field'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        this._pillButton(
                          context,
                          key: const Key('kick-setup-connect'),
                          label: store.authState == KickAuthState.signingIn
                              ? 'Connecting…'
                              : 'Connect',
                          onTap:
                              this._connecting ||
                                  store.authState == KickAuthState.signingIn
                              ? null
                              : this._connect,
                        ),
                      ],
                      if (store.authError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        this._authError(context, store.authError!),
                      ],
                    ],
                  );
                },
              )
            else
              Text(
                'Native Kick chat is not available in this build state.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.md),
            this._pillButton(
              context,
              key: const Key('kick-setup-save'),
              label: 'Save',
              onTap: () {
                this._persist();
                if (this.mounted) Navigator.of(this.context).pop();
              },
              color:
                  Theme.of(context).buttonTheme.colorScheme?.secondary ??
                  StylingHelper.accent_color,
            ),
          ],
        ),
      ),
    );
  }
}

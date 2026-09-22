import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.linear,
        reverseCurve: Curves.linear,
      ),
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

  /// Measures the whole sheet so an overscroll moves it 1:1 with the finger.
  final GlobalKey _sheetKey = GlobalKey();

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
            'Key works — save it to enable native chat',
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

  @override
  Widget build(BuildContext context) {
    final accent =
        ChatType.YouTube.brandColor ??
        Theme.of(context).buttonTheme.colorScheme?.secondary ??
        StylingHelper.accent_color;

    /// The modal column does not pass its max height down, so this
    /// scroll view would otherwise grow with the advanced section and
    /// overflow the sheet. Cap it to the same fraction the sheet uses,
    /// and to the space left above the keyboard.
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.bottom;
    final cap = math
        .min(media.size.height * 0.86 - media.padding.bottom, available)
        .clamp(0.0, double.infinity);

    return ConstrainedBox(
      key: this._sheetKey,
      constraints: BoxConstraints(maxHeight: cap),
      child: Column(
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
                  'YouTube chat setup',
                  style: nativeChatSheetTitleStyle(context),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          Flexible(
            child: _SheetOverscroll(
              sheetKey: this._sheetKey,
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
                  children: [
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
                        final uri = Uri.parse(
                          'https://console.cloud.google.com',
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
                              'Open console.cloud.google.com',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        (Theme.of(
                                                  context,
                                                ).extension<AppTextColors>() ??
                                                AppTextColors.standard)
                                            .highlightText,
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
                                this._store!.authState ==
                                    YouTubeAuthState.signedIn
                                ? const SizedBox.shrink()
                                : this._pillButton(
                                    context,
                                    key: const Key('youtube-setup-sign-in'),
                                    label: 'Connect YouTube',
                                    onTap: this._signIn,
                                    color:
                                        Theme.of(
                                          context,
                                        ).buttonTheme.colorScheme?.secondary ??
                                        StylingHelper.accent_color,
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulling past the top of a scrolling sheet moves the sheet 1:1 with the
/// finger. Releasing springs it shut or back open.
///
/// Same decision iOS interactive dismiss uses: a downward flick closes even
/// when the drag was short, and a slower drag closes once it has passed
/// half the sheet — unless that release is flicking back upward. Otherwise
/// a critically damped spring (SwiftUI `spring(bounce: 0)`) returns it.
class _SheetOverscroll extends StatefulWidget {
  final Widget child;
  final GlobalKey sheetKey;

  const _SheetOverscroll({required this.child, required this.sheetKey});

  @override
  State<_SheetOverscroll> createState() => _SheetOverscrollState();
}

class _SheetOverscrollState extends State<_SheetOverscroll> {
  /// Points per second. A flick at least this fast dismisses regardless of
  /// how far the sheet travelled. From the usual UIKit interactive-dismiss
  /// split (fast flick, or past halfway without flicking back).
  static const double _flickVelocity = 300.0;

  static const double _distanceThreshold = 0.5;

  /// Critically damped, so the release settles once and does not bounce.
  static final SpringDescription _spring =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0.0,
      );

  bool _pulled = false;
  bool _settled = true;

  double _sheetHeight(ScrollMetrics metrics) {
    final box =
        this.widget.sheetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height > 0) {
      return box.size.height;
    }
    return metrics.viewportDimension;
  }

  void _track(BuildContext context, OverscrollNotification notification) {
    final controller = ModalRoute.of(context)?.controller;
    if (controller == null) return;
    final height = this._sheetHeight(notification.metrics);
    if (height <= 0) return;

    /// Raw finger delta. The scroll view's own overscroll is friction-damped,
    /// which made the sheet lag the finger.
    final fingerDown = notification.dragDetails?.primaryDelta;
    final pixels = (fingerDown != null && fingerDown > 0)
        ? fingerDown
        : -notification.overscroll;
    if (pixels <= 0) return;

    this._pulled = true;
    this._settled = false;
    controller.stop();
    controller.value = (controller.value - pixels / height).clamp(0.0, 1.0);
  }

  void _settle(BuildContext context, double velocity) {
    if (this._settled || !this._pulled) return;
    final controller = ModalRoute.of(context)?.controller;
    if (controller == null || controller.value >= 1.0) {
      this._settled = true;
      this._pulled = false;
      return;
    }
    this._settled = true;
    this._pulled = false;

    final height = () {
      final box =
          this.widget.sheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.height > 0) {
        return box.size.height;
      }
      return 1.0;
    }();
    final travelled = 1.0 - controller.value;

    /// Fast downward flick closes on its own. A slower drag closes only
    /// after half the sheet, and not if the finger flicks back up.
    final dismiss =
        velocity > _flickVelocity ||
        (travelled > _distanceThreshold && velocity > -_flickVelocity);
    final target = dismiss ? 0.0 : 1.0;

    /// Spring velocity is in animation units per second (1 = one sheet
    /// height). Downward finger velocity continues the dismiss direction.
    final animationVelocity = -velocity / height;
    final simulation = SpringSimulation(
      _spring,
      controller.value,
      target,
      animationVelocity,
    );
    final done = controller.animateWith(simulation);
    if (dismiss) {
      done.whenComplete(() {
        if (!context.mounted) return;
        if (controller.value <= 0.01) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        final atTop =
            notification.metrics.pixels <= notification.metrics.minScrollExtent;
        if (notification is OverscrollNotification &&
            notification.overscroll < 0 &&
            atTop) {
          this._track(context, notification);
          return false;
        }
        if (notification is ScrollEndNotification) {
          final velocity = notification.dragDetails?.primaryVelocity ?? 0.0;
          this._settle(context, velocity);
        }
        return false;
      },
      child: Listener(
        onPointerUp: (_) => this._settle(context, 0.0),
        onPointerCancel: (_) => this._settle(context, 0.0),
        child: this.widget.child,
      ),
    );
  }
}

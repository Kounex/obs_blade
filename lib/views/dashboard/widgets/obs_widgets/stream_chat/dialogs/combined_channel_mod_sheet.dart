import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/combined_chat.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../utils/modal_handler.dart';
import '../chat_type_brand.dart';
import '../combined_sources_sheet.dart';
import '../native_chat_chrome.dart';
import '../native_combined_chat_view.dart';
import 'channel_mod_chrome.dart';
import 'channel_mod_sheet.dart';
import 'kick_channel_mod_sheet.dart';
import 'youtube_channel_mod_sheet.dart';

/// Opens the combined chat's channel mod sheet on [context].
void showCombinedChannelModSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.85,
      builder: (_) => CombinedChannelModSheet(
        hostContext: context,
        onToast: (message) => showChannelModToast(context, message),
      ),
    );

/// Why a combined source can't be moderated from here — null when it
/// can (its panel shows).
enum CombinedModBlock {
  /// YouTube without an API key.
  notSetUp,

  /// Not signed in (or signed in without write access).
  signedOut,

  /// Twitch: signed in, but the token lacks the moderation scopes.
  missingScopes,

  /// Twitch knows the account doesn't moderate this channel.
  notModerator,

  /// A saved combo's source the platform can't show right now.
  unavailable,
}

/// The block for [source], or null when its panel can show. Kick /
/// YouTube have no mod lookup — signed in with write access means
/// "try" (a refusal toasts); Twitch knows.
CombinedModBlock? combinedModBlock(CombinedSource source) {
  switch (source.platform) {
    case ChatType.Twitch:
      final twitch = GetIt.instance<TwitchChatStore>();
      if (!twitch.isLoggedIn) return CombinedModBlock.signedOut;
      if (source.unavailable) return CombinedModBlock.unavailable;
      if (!twitch.canModerateChats) return CombinedModBlock.missingScopes;
      return twitch.canModerateSelectedChannel
          ? null
          : CombinedModBlock.notModerator;
    case ChatType.YouTube:
      final youTube = GetIt.instance<YouTubeChatStore>();
      if (youTube.authState == YouTubeAuthState.unconfigured) {
        return CombinedModBlock.notSetUp;
      }
      if (!youTube.isSignedInState || !youTube.canWrite) {
        return CombinedModBlock.signedOut;
      }
      return source.unavailable ? CombinedModBlock.unavailable : null;
    case ChatType.Kick:
      final kick = GetIt.instance<KickChatStore>();
      if (!kick.isSignedInState || !kick.canWrite) {
        return CombinedModBlock.signedOut;
      }
      return source.unavailable ? CombinedModBlock.unavailable : null;
    case ChatType.Owncast:
    case ChatType.Combined:
      return CombinedModBlock.unavailable;
  }
}

/// Platforms the account may (try to) moderate in the shown combo.
List<ChatType> combinedModPlatforms(CombinedChatStore combined) => [
  for (final source in combined.activeSources)
    if (combinedModBlock(source) == null) source.platform,
];

/// What each platform's mods can do here at all (API limits) — shown on
/// a blocked tab so the user still learns what the tab would hold.
const Map<ChatType, String> kCombinedModCapabilities = {
  ChatType.Twitch:
      'Moderators can clear chat, switch chat modes, turn on Shield Mode, '
      'review AutoMod, handle bans and send announcements.',
  ChatType.YouTube:
      'Moderators can run polls and lift bans issued here; the channel '
      'owner also manages moderators. YouTube has no chat-mode or clear '
      'API.',
  ChatType.Kick:
      'Moderators can see and lift bans and unban by name. Kick\'s API '
      'can\'t change chat modes.',
};

/// One sheet, one tab per source of the combo — always, even when a
/// platform can't be moderated: its tab then says why (not set up, signed
/// out, not a moderator) with the fix, plus what that platform's mods
/// could do. Moderatable tabs show the platform's own channel mod panel
/// (the store already points at the combo's channel). The first
/// moderatable tab opens first.
class CombinedChannelModSheet extends StatefulWidget {
  final void Function(String message) onToast;

  /// The chat pane's context — sign-in / setup flows open on it after
  /// the sheet pops.
  final BuildContext? hostContext;

  const CombinedChannelModSheet({
    super.key,
    required this.onToast,
    this.hostContext,
  });

  @override
  State<CombinedChannelModSheet> createState() =>
      _CombinedChannelModSheetState();
}

class _CombinedChannelModSheetState extends State<CombinedChannelModSheet> {
  ChatType? _selected;

  Widget _blocked(
    BuildContext context,
    CombinedSource source,
    CombinedModBlock block,
  ) {
    final platform = source.platform;
    final (String reason, String? action) = switch (block) {
      CombinedModBlock.notSetUp => (
        '${platform.text} chat isn\'t set up yet - it needs an API key.',
        'Set up ${platform.text}',
      ),
      CombinedModBlock.signedOut => (
        'Sign in to ${platform.text} to moderate ${source.label}.',
        'Sign in to ${platform.text}',
      ),
      CombinedModBlock.missingScopes => (
        'Your ${platform.text} login predates the moderation permissions.',
        'Sign in again',
      ),
      CombinedModBlock.notModerator => (
        'You\'re not a moderator in ${source.label}\'s ${platform.text} '
            'chat.',
        null,
      ),
      CombinedModBlock.unavailable => (
        '${source.label} can\'t be shown on ${platform.text} right now.',
        null,
      ),
    };
    return Column(
      key: Key('combined-mod-blocked-${platform.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reason, style: Theme.of(context).textTheme.bodyMedium),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ChannelModActionRow(
            key: Key('combined-mod-fix-${platform.name}'),
            icon: CupertinoIcons.arrow_right_circle,
            label: action,
            onTap: () {
              final host = this.widget.hostContext ?? context;
              Navigator.of(context).pop();
              combinedSourceFix(host, platform, forMyChats: false);
            },
          ),
        ],
        if (kCombinedModCapabilities[platform] case final capabilities?)
          ChannelModNote(capabilities),
      ],
    );
  }

  Widget _panel(ChatType platform) => switch (platform) {
    ChatType.Twitch => ChannelModSheet(
      key: const ValueKey('combined-mod-Twitch'),
      embedded: true,
      onFailure: this.widget.onToast,
    ),
    ChatType.YouTube => YouTubeChannelModPanel(
      key: const ValueKey('combined-mod-YouTube'),
      showTitle: false,
      onToast: this.widget.onToast,
    ),
    ChatType.Kick => KickChannelModPanel(
      key: const ValueKey('combined-mod-Kick'),
      showTitle: false,
      onToast: this.widget.onToast,
    ),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final combined = GetIt.instance<CombinedChatStore>();
        final sources = combined.activeSources;
        final blocks = {
          for (final source in sources)
            source.platform: combinedModBlock(source),
        };
        final platforms = [for (final source in sources) source.platform];
        final labels = {
          for (final source in sources) source.platform: source.label,
        };

        /// Default: the first tab that can be moderated, else the first.
        final selected = platforms.contains(this._selected)
            ? this._selected!
            : platforms.firstWhere(
                (platform) => blocks[platform] == null,
                orElse: () =>
                    platforms.isEmpty ? ChatType.Combined : platforms.first,
              );
        final selectedSource = sources
            .where((source) => source.platform == selected)
            .firstOrNull;
        final selectedBlock = blocks[selected];

        return NativeChatSheetScaffold(
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Moderate', style: nativeChatSheetTitleStyle(context)),
              if (platforms.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final platform in platforms)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs / 2,
                          ),
                          child: _PlatformTab(
                            platform: platform,
                            label: labels[platform] ?? platform.text,
                            selected: platform == selected,
                            blocked: blocks[platform] != null,
                            onTap: () =>
                                this.setState(() => this._selected = platform),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          body: selectedSource == null
              ? const ChannelModNote('This combined chat has no sources yet.')
              : AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child: KeyedSubtree(
                    key: ValueKey((selected, selectedBlock)),
                    child: selectedBlock == null
                        ? this._panel(selected)
                        : this._blocked(context, selectedSource, selectedBlock),
                  ),
                ),
        );
      },
    );
  }
}

class _PlatformTab extends StatelessWidget {
  final ChatType platform;
  final String label;
  final bool selected;

  /// Can't be moderated from here — the tab dims and carries a lock.
  final bool blocked;
  final VoidCallback onTap;

  const _PlatformTab({
    required this.platform,
    required this.label,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand =
        this.platform.brandColor ?? Theme.of(context).colorScheme.secondary;
    return Pressable(
      key: Key('combined-mod-tab-${this.platform.name}'),
      haptic: true,
      onTap: this.onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: brand.withValues(alpha: this.selected ? 0.18 : 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: brand.withValues(alpha: this.selected ? 0.9 : 0.25),
            width: this.selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: this.blocked ? 0.5 : 1.0,
              child: CombinedPlatformBadge(platform: this.platform),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (this.blocked) ...[
              Icon(
                CupertinoIcons.lock_fill,
                size: 11.0,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: AppSpacing.xs / 2),
            ],
            Flexible(
              child: Text(
                this.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: this.selected ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

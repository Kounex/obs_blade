# First-class chat integration contract

D-003–004 establish independent chat availability and adjustable focus. This
contract preserves the native engines as specialized product capabilities. The
initial prototype's plain sample messages are not an acceptable production
replacement for emotes, roles, replies, tombstones, notices or moderation tools.

## Access and readiness

`lib/redesign/chat/chat_access.dart` is the first presentation seam.
`chat_access_projection.dart` reads existing Pro/Twitch/YouTube store state;
it does not initialize services or write settings. Observe the function inside a
MobX reaction, and supply current engine/platform settings. The development UI
currently uses matching synthetic snapshots, not real accounts.

- Honor `nativeChatAvailableFor`; unsupported native preferences resolve to the
  free WebView. Preserve the current default engine and saved choices.
- Native access reads `ProStore.isPro`, including its existing debug/offline rules.
  Entitlement takes precedence over native setup/sign-in prompts. Revocation
  replaces native content without signing the account out or discarding drafts.
- Twitch authorization and its read transport are separate from write scopes.
  Missing `user:write:chat` permits reading but offers permission renewal.
- YouTube requires configured API access for reading. A signed-out user can read
  the selected live video; sign-in is needed for writing. Missing configuration,
  absent selection, ended chat, transport error and exhausted quota stay distinct.
- Native sends require a known channel, current connection and write access;
  reading buffered history and preparing a draft remain possible while reconnecting.
  Never queue automatic message retries. A draft is not a delivered message.
- OBS readiness and workspace focus never participate in chat access decisions.

Evidence: `StreamChat._buildNativeChatSlot`, `TwitchChatStore.canWriteChat`,
`YouTubeChatStore.canRead/canWrite`, their auth/connection enums, and
`ProStore.isPro`. The projection has tests for the gate order, free fallback,
read-only states, video identity and reactive entitlement revocation.

## Conversation identity and action ownership

`ChatComposerController` now adapts real store actions and owns in-memory drafts
and replies above pane composition. Its host injects initialized stores; it never
initializes/disposes services or persists engine/platform preferences. It is tested
and bound to `WorkspaceChatPane` in the isolated native chat lab.

Use platform + account identity + Twitch broadcaster ID / YouTube video ID for
conversation-local state. Display names and YouTube configuration labels are not
sufficient identity: re-editing a saved label can replace its underlying video.
Preserve drafts and scroll state above pane composition, in memory only. Account
logout clears account-owned context; an OBS disconnect does not. A reply must
retain its platform message ID and channel, never just the displayed author.

The controller serializes destination changes against a pending send and rejects
stale picker choices. It reads entitlement/readiness again at action time. Capture identity before dispatch and apply completion only to that
conversation. Do not transfer a failed draft/reply to the next channel. Existing
stores already buffer channel history; do not duplicate that transport cache.

The store boundary now captures Twitch destination/reply before token refresh,
keeps newer replies intact, and scopes failures to the original conversation.
YouTube accepted sends update the original buffer, deduplicate an earlier poll
echo, and discard completion after logout or replacement of the saved video.
Nine regression cases cover these boundaries. UI-only disabled buttons cannot
protect against other owners changing stores; the workspace controller supplies independent
draft lifetime and action serialization.

Send-safety checkpoint (2026-09-12): **827 tests pass** across chat, WebSocket,
persistence, Pro and redesign. Broad analysis retains 0 errors / 8 warnings /
372 infos. An inherited Pro test emitted a stream update before subscription;
its separate test-only fix waits for the listener. Purchase behavior is unchanged.
YouTube settings reload now retires messages, cursors and liveChatId when a label
changes video or disappears. Three regression cases cover active/inactive video
replacement and removal/re-addition. The earlier replacement fixture used an
invalid-length video ID and exercised removal; it now uses a valid ID and asserts
the parsed replacement explicitly.

Twitch drafts survive permission renewal while the same user remains known.
Logout/account replacement clears account context. Twitch conversation identity also
contains an in-memory sign-in epoch, preventing old scroll/reveal state from
returning after a later login to the same account. YouTube's persisted auth has
no stable account ID: its composer uses an opaque in-memory sign-in lifetime, not
a title or token. An auth-state transition across signed-in status clears YouTube
drafts conservatively; retaining drafts through same-account reauthorization needs
a verified identity seam. No Hive schema change is introduced (D-007).

## Rich conversation and culture

`chat_timeline.dart` projects sealed message/notice entries and the active pin.
The controller observes messages and lifecycle changes, hides native rows behind
the Pro gate, and suppresses old Twitch rows during a channel buffer swap. It
keeps typed platform messages through the adapter. Preserve Twitch first/third-party
emotes, role badges and category settings, reply references, content-visible
tombstones, pause/return-live, channel notices and per-action moderation scopes.
YouTube capabilities must reflect its implementation; do not imply Twitch-only
features or infer moderator authority from OAuth sign-in alone. Free embedded chat
retains its own browser/account behavior.

The user's chosen focus controls allocate space to OBS, chat or both. Optional
recent activity changes emphasis within chat. The sample subscription/follow rows
are design fixtures, not verified new event coverage. Map implemented notices
first; new event subscriptions, retention and notification delivery require their
own evidence and scope. No new entitlement tier or business policy is introduced.

## Current review surface

The lab's **Demo chat state** control switches nine deterministic scenarios:
connected, Pro required, Twitch signed out/read-only, YouTube setup/read-only,
reconnecting, ended chat and exhausted quota. Gate actions expose typed intents;
the lab explicitly reports that login/setup/purchase navigation is not wired.
It never simulates a completed purchase or signs into an account.

Production integration still needs account/setup navigation, free WebView hosting,
moderation/user-card actions, emote picker and appearance controls, and lifecycle
validation against real accounts. The native lab binds channel/send actions, typed
message rows, and explicit badge/emote catalog dependencies. These are remaining work, not
features established by the access projection tests.

## Adapter checkpoint — 2026-09-12

**848 tests pass** across chat, WebSocket, persistence, Pro and redesign (98 redesign).
The 18 new controller/timeline tests cover conversation ownership, external channel
changes, pending completion, logout, permission renewal, reactive gating and typed
message/lifecycle preservation. Targeted redesign/lab analysis is clean. These are
store/contract checks; the following native-pane checkpoint adds UI evidence.

## Native checkpoint — 2026-09-12

Phone and tablet walkthroughs passed using synthetic chat access and a synthetic
OBS peer. Pro removes the native timeline; returning to read-only retains reply
and draft, with Send disabled. Native screenshots inspected:
[phone Pro](prototype-shots/phone-native-chat-pro.png),
[phone read-only](prototype-shots/phone-native-chat-readonly.png),
[tablet Pro](prototype-shots/tablet-native-chat-pro.png),
[tablet read-only](prototype-shots/tablet-native-chat-readonly.png).
Both temporary simulators were removed. This validates state composition, not real
sign-in, purchase or permission-upgrade flows. That visual checkpoint had 818 passing
tests (80 redesign), with clean targeted analysis and a successful web build.

The fake browser entry accepts `?chat=readOnly&focus=chat` (enum names) for
reproducible startup states. Browser semantics can leave an empty full-screen
pointer interceptor after menu use; capture also intermittently timed out. This
is an unresolved browser-preview limitation. Native interaction/visual evidence
and widget tests are the checkpoint authority; browser interaction is not declared
clean. Production targets remain iOS/Android, not web.


## Native rich chat lab

Run `flutter run -t lib/main_redesign_chat.dart` on a native device or simulator.
This entrypoint uses actual presentation/controller code with synthetic chat
stores and a temporary settings box. It does not initialize saved accounts,
production settings, global service registrations, purchases or chat APIs. OBS
controls in this entrypoint remain simulated; use the separate OBS lab for its
transport adapter.

`WorkspaceApp.chatPane` accepts the injected pane and preserves its subtree across
phone/tablet composition changes. `WorkspaceChatPane` binds channel selection,
per-conversation drafts, actual Twitch reply targets, guarded sends and local
readiness/Pro gates. `WorkspaceChatTimeline` reuses platform-specific rows, keeps
notice visibility/category settings, typed replies and tombstones, and displays
the current pin. Badge/emote catalogs are explicit dependencies; existing
production callers retain their original defaults. The fixture does not fetch
badge/emote artwork, so captures do not establish remote catalog rendering.

Scroll position and manual pause belong to the conversation. Following the latest
message responds to content and viewport metrics, including reply/keyboard size
changes; a paused reader keeps their position. Programmatic following must not
be mistaken for manual scrolling. Host actions for accounts, setup, free WebView,
channel management and purchases remain explicit unbound lab intents. Moderation,
user cards, pin actions, emote picking and appearance editing remain work ahead;
this pane is not ready to replace the production chat surface.


Visual refinement found and corrected two interaction defects: a stationary native
long press could claim scrolling without movement, and modal presentation could
leave a row's local hold wash active. Following now claims scroll ownership only
on movement; local hold ends when its callback fires, while explicit sheet
selection remains parent-owned. Native tests assert less than one logical pixel
after the timeline tail and transparent local wash after choosing Reply.

The YouTube tier-1 amount also failed text contrast in the workspace: `#1565C0`
over its 15% tint on `#141B24` gives RGB (20.15, 38.10, 59.40), only **2.66:1**.
Amounts now use the ordinary `#EDF2F7` text foreground (**13.58:1** here); tier
color remains on card tint/border. The pane regression computes relative
luminance against that alpha-composited background and requires at least 4.5:1.
This measurement covers the workspace fixture, not every user-defined theme.


Native phone and tablet walkthroughs passed on 2026-09-13. Captures inspected:
[phone reply](prototype-shots/phone-native-rich-reply.png),
[tablet reply](prototype-shots/tablet-native-rich-reply.png),
[tablet YouTube](prototype-shots/tablet-native-rich-youtube.png),
[phone Pro](prototype-shots/phone-native-rich-pro.png).
The ten pane tests cover channel drafts, actual reply identity and reparenting,
paused scroll, live viewport following, sending, Pro revocation, write-permission
loss, keyboard/large text and specialized YouTube rendering/amount contrast.
Buffer trimming during a hold is covered too: rows carry conversation + entry
identity so a recycled list position cannot open actions for another message.
The shared-row regression also verifies hold termination before pointer-up.
Targeted analysis is clean. Temporary simulators were removed. These fixtures
establish native presentation behavior, not real account/API integration.


Final native-pane gate (2026-09-14): **859 tests pass** across chat, WebSocket,
persistence, Pro and redesign (108 redesign). Targeted analysis is clean; broad
analysis retains 0 errors / 8 warnings / 372 infos. The final row-identity change
is covered by the full gate and does not change the captured composition.

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

## Conversation identity and action ownership — next adapter

Use platform + account identity + Twitch broadcaster ID / YouTube video ID for
conversation-local state. Display names and YouTube configuration labels are not
sufficient identity: re-editing a saved label can replace its underlying video.
Preserve drafts and scroll state above pane composition, in memory only. Account
logout clears account-owned context; an OBS disconnect does not. A reply must
retain its platform message ID and channel, never just the displayed author.

Serialize destination changes against a pending send in the workspace action
adapter. Capture identity before dispatch and apply completion only to that
conversation. Do not transfer a failed draft/reply to the next channel. Existing
stores already buffer channel history; do not duplicate that transport cache.

This boundary needs explicit regression tests before real send binding:
`TwitchChatStore.sendChatMessage` awaits token refresh before reading effective
broadcaster/reply; `YouTubeChatStore.sendChatMessage` captures its liveChatId but
appends the result to the then-active `messages` list. UI-only disabled buttons
cannot protect against other owners changing those stores. Adapt target capture
at the store seam if necessary, preserving existing caller behavior.

## Rich conversation and culture

Keep typed platform messages through the adapter. Preserve Twitch first/third-party
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
channel selection and guarded sends, typed message rendering, moderation, emote
and badge dependencies, and lifecycle validation. These are remaining work, not
features established by the access projection tests.

## Native checkpoint — 2026-09-12

Phone and tablet walkthroughs passed using synthetic chat access and a synthetic
OBS peer. Pro removes the native timeline; returning to read-only retains reply
and draft, with Send disabled. Native screenshots inspected:
[phone Pro](prototype-shots/phone-native-chat-pro.png),
[phone read-only](prototype-shots/phone-native-chat-readonly.png),
[tablet Pro](prototype-shots/tablet-native-chat-pro.png),
[tablet read-only](prototype-shots/tablet-native-chat-readonly.png).
Both temporary simulators were removed. This validates state composition, not real
sign-in, purchase or permission-upgrade flows. The latest full gate is 818 passing
tests (80 redesign), with clean targeted analysis and a successful web build.

The fake browser entry accepts `?chat=readOnly&focus=chat` (enum names) for
reproducible startup states. Browser semantics can leave an empty full-screen
pointer interceptor after menu use; capture also intermittently timed out. This
is an unresolved browser-preview limitation. Native interaction/visual evidence
and widget tests are the checkpoint authority; browser interaction is not declared
clean. Production targets remain iOS/Android, not web.

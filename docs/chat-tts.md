# Chat TTS — shipped state

Moved from `AGENTS.md` (2026-10 docs restructure).

**Chat TTS:** `ChatTtsStore` (startup singleton, Pro) reads the chat the
Chat tab shows (one native platform or every Combined source) via each
store's `liveMessages` stream (no backfill / switch restores) →
`chatTtsUtterance` (audience, skip rules, chat-wide ignore/mute) →
`ChatTtsQueue` (never drops on its own; "N waiting" + jump to latest;
stale skip opt-in; `speak` → false = audio taken (call) → the message
waits and retries; a voice preview `hold`s reading; switching chat type /
engine clears it, another channel's messages are skipped). It attaches
only to platform stores that already exist (GetIt `onCreated` in
`main.dart` for later ones) - never creates one. Foreground only (no background modes, by decision);
Wake Lock is app-wide now (default off). Speaker in the
`NativeChatWindow` header: tap toggles, long press = settings (also an
options-sheet page), one-off hint on first enable (a speech bubble
anchored to the speaker via `LayerLink` in a root-overlay `OverlayPortal`;
tap = open settings, 5 s auto-close). Speech runs on the
app's own `com.kounex.obsBlade/tts` channel (`PlatformTtsSpeaker` →
`ChatTts` in `AppDelegate.swift` / `MainActivity.kt`; iOS picks the
best installed voice + stops on audio interruptions, Android ducks via
transient audio focus + restarts a dead engine once, both answer `speak` false while a call /
interruption holds the audio; `voices` lists the
installed voices for the sheet; the Dart queue has a per-message
watchdog so a missing "finished" never stalls reading). Language: a
default (`ChatTtsLanguage`, null = phone) + opt-in per-message detection
(`ChatTtsDetectLanguage`; iOS `NLLanguageRecognizer`, Android 10+
`TextClassifier`, on the message body only, ≥3 words or ≥12 letters and
≥60% confidence, else the default) - both done natively, the Dart side
only sends `setLanguage` + `speak {text, detectionText}`. Spam: 3+
identical words collapse to "KEKW 5 times"; "Combine repeated messages"
(default on) reads identical short (≤3 words) messages already waiting
in the queue once - first author + notable (highlighted/mod/streamer)
names, max 3, rest counted (`chatTtsCombinedLine`), never holds a
message back; "Skip emote-only messages" (opt-in). Filler words come
from the built-in `ChatTtsPhrases` table (all 39 base languages iOS
ships voices for + old Android aliases, by the default TTS language,
English fallback) - no translation service on purpose. Voices: a
per-language pick (`ChatTtsVoices` JSON, tag → voice id, missing =
automatic) sent with `setLanguage`; both bridges honour it (exact tag;
another region's pick only for a tag without voices of its own) and
mark it `preferred`, plus `default` on the voice the default language
reads with (the sheet's voice row + filler-word language follow it -
Android reads in the engine's default language, not the phone's); `preview` reads a
per-language sample (`ChatTtsPhrases.sample`). Android adds
`openTtsSettings` / `installVoiceData` intents; iOS can only explain
the path (no public deep link).
No plugin:
`flutter_tts` is CocoaPods-only and iOS is SPM-only since `81a41a27`, so
check a new iOS plugin for SPM support before adding it. Feasibility +
decisions:
`docs/private/feature-requests-2026-10.md`.

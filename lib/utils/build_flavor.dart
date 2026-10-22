/// Buy Me a Coffee page - the FOSS build's Tip Jar (no in-app purchases
/// there), same link as the README and F-Droid's `Donate:` field.
final Uri kBuyMeACoffeeUri = Uri.parse('https://www.buymeacoffee.com/Kounex');

/// True for the FOSS build (GitHub APK + F-Droid). That build has no
/// store SDKs: `tool/foss/prepare.sh` removes `in_app_purchase` /
/// `purchases_flutter` and swaps this file for one where [kFoss] is a
/// plain `true`, so a FOSS build can't come out with Pro surfaces by a
/// forgotten define. Here it reads `--dart-define=OBS_BLADE_FOSS=true`,
/// which only exists for tests of the FOSS UI on the regular tree.
///
/// FOSS leaves Pro out entirely instead of locking it: `ProStore.isPro`
/// is false, no native chat engine / Combined chat, no activity feed or
/// TTS, no custom themes, no Pro or store tiles - nothing to buy, so no
/// upsell either. See `docs/foss-build.md`.
const bool kFoss = bool.fromEnvironment('OBS_BLADE_FOSS');

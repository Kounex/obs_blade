# provisioning

Standalone Dart CLI (no Flutter) that automates the store/cloud setup for
OBS Blade's Pro subscription and the YouTube native chat spike, shrinking the
maintainer's manual work to "provide creds, run three commands, click the few
console-only things".

Three subcommands of one entrypoint:

- **`gcp-youtube`** — GCP project + YouTube Data API v3 + a restricted API
  key for the `tool/youtube_spike/` quota measurement (shells out to the GA
  `gcloud services api-keys` surface).
- **`asc-products`** — App Store Connect: subscription group "Pro",
  subscriptions `pro_yearly` + `pro_monthly`, non-consumable `pro_lifetime`,
  en-US localizations (drift-reconciled via PATCH) and **reviewed-table
  subscription pricing in every available territory** (anchor currencies at
  the USD nominal, everything else at Google's converted table, snapped to
  the nearest App Store price point; US base price for the IAP, whose
  schedule auto-equalizes the other territories).
- **`play-products`** — Google Play: one subscription product (`pro`)
  containing the `pro-yearly` + `pro-monthly` base plans, plus the
  `pro_lifetime` one-time product, with **per-region pricing in all ~174
  Play regions** from the same reviewed table (`lib/src/pricing_targets.dart`
  — generated from Play's own `pricing:convertRegionPrices`, then
  hand-reviewed). Prices are pinned explicitly so they don't drift
  with FX rates;
  base plans / purchase option are activated after creation. Writes pass
  the table's `regionVersion` (currently 2026/01) — an older version gets
  rejected for regions whose currency changed (BG → EUR).

Product ids are final and match `lib/utils/pro_ids.dart`. All commands are
**idempotent**: they list/get first and only create what is missing, so
re-running after a partial failure just fills the gaps. Every command
supports **`--dry-run`**, which prints each request/command (with full JSON
bodies) without sending anything — no credentials needed for dry runs.

## Setup

```bash
dart pub get
```

Prerequisites: Dart SDK ≥ 3.8, and for `gcp-youtube` the `gcloud` CLI
(<https://cloud.google.com/sdk/docs/install>) with `gcloud auth login` done.
The tool checks for `gcloud` and exits with install instructions if absent.

## Credentials

Credentials are passed **by path only** and never echoed or logged. Keep them
outside the repo (e.g. `~/.config/obs-blade/…`, `chmod 600`); the `.gitignore`
here additionally covers `creds/`, `*.p8` and service-account JSON in case you
keep them locally anyway.

**Preferred: environment variables.** Every credential flag falls back to an
env var, so you can export them once from your shell init (the maintainer uses
`~/.localrc`, sourced into zsh) and run the commands flag-free. **Step-by-step
walkthrough for collecting each one: [`CREDENTIALS.md`](CREDENTIALS.md).**
The block to collect:

```bash
# ~/.localrc
export OBS_BLADE_ASC_KEY_PATH="$HOME/.config/obs-blade/asc-key.p8"
export OBS_BLADE_ASC_KEY_ID="…"
export OBS_BLADE_ASC_ISSUER_ID="…"
export OBS_BLADE_ASC_APP_ID="…"                         # numeric App Store Connect app id
export OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/obs-blade/play-svc.json"
export OBS_BLADE_GCP_PROJECT_ID="obs-blade"               # optional, has a sane default
```

An explicit flag always wins over the env var.

| Command | Credential | Env fallback | Where to get it |
|---|---|---|---|
| `gcp-youtube` | gcloud user login | `OBS_BLADE_GCP_PROJECT_ID` (project only; auth is gcloud's own) | `gcloud auth login` (needs permission to create projects, or pre-create the project in the console) |
| `asc-products` | `.p8` key + key id + issuer id | `OBS_BLADE_ASC_KEY_PATH` / `OBS_BLADE_ASC_KEY_ID` / `OBS_BLADE_ASC_ISSUER_ID` / `OBS_BLADE_ASC_APP_ID` | <https://appstoreconnect.apple.com/access/integrations/api> → "Generate API Key" (role: Admin or App Manager) — the `.p8` downloads once, the key id and team-level issuer id are shown on the same page |
| `play-products` | service-account JSON | `OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS` (path to the service-account JSON; deliberately *not* the Google-standard unprefixed var, so it can't collide with other GCP accounts on the machine) | GCP: enable the Google Play Developer API, create a service account + JSON key. Play Console → **Users and permissions** → "Invite new users" with the service-account email → grant the OBS Blade app **Admin** (or at least "Manage orders and subscriptions"). Details: [`CREDENTIALS.md`](CREDENTIALS.md) Track 2 |

## `gcp-youtube`

```bash
dart run bin/provision.dart gcp-youtube --dry-run
dart run bin/provision.dart gcp-youtube \
    --project-id obs-blade \
    --out-file ~/.config/obs-blade/youtube-api-key.txt
```

Creates-or-reuses the project (`--project-id`, default `obs-blade` — the
shared project the Play API setup also uses),
enables `youtube.googleapis.com`, and creates an API key restricted to the
YouTube Data API v3 (`--api-target=service=youtube.googleapis.com`). Re-runs
find the key by its display name and reuse it.

The key is printed to stdout **exactly once** unless `--out-file` is given —
then it is written there with `chmod 600` and only the path is printed. The
key stays retrievable via `gcloud services api-keys get-key-string`, so
nothing is lost either way. Use this key with `tool/youtube_spike/`.

**Manual afterwards (console-only):** the OAuth consent screen and the OAuth
"TVs and limited input devices" client for the device flow cannot be created
via CLI/API — links are printed at the end of the run. See
`docs/youtube-native-chat-audit.md`.

## `asc-products`

```bash
dart run bin/provision.dart asc-products --dry-run --app-id <numeric-id>
dart run bin/provision.dart asc-products \
    --key-path ~/.config/obs-blade/AuthKey_XXXXXXXXXX.p8 \
    --key-id XXXXXXXXXX \
    --issuer-id 69a6de7c-…-… \
    --app-id 1234567890
```

Creates, if missing: subscription group **"Pro"** (+ en-US localization),
subscriptions **pro_yearly** (`ONE_YEAR`, "Pro - Yearly" / "Yearly Pro
Subscription") and **pro_monthly** (`ONE_MONTH`, "Pro - Monthly" / "Monthly
Pro Subscription") (+ en-US localizations), and the non-consumable IAP
**pro_lifetime** ("Pro - Lifetime" / "Lifetime Pro Access", + en-US
localization). Existing localizations whose name or description drifted from
these canonical values are reconciled via `PATCH
/v1/subscriptionLocalizations/{id}` resp. `/v1/inAppPurchaseLocalizations/{id}`
— re-runs converge instead of fighting manual console edits.

**Subscription pricing is automated for EVERY available territory from the
reviewed pricing table** (`lib/src/pricing_targets.dart` — see "Pricing
table" below). With `--yearly-price-usd` / `--monthly-price-usd`
(defaults 49.99 / 4.99) the tool reads the territory list from
`GET /v1/subscriptionAvailabilities/{id}/availableTerritories` (the
availability resource shares the subscription's id) and each territory's
currency from `GET /v1/territories` (cached per run), looks up the table
target for that currency (CHF is split per territory: CHE/LIE), and sets
the price point whose `customerPrice` is the target — or the numerically
nearest point when no exact one exists — via
`POST /v1/subscriptionPrices`. Snap deviations beyond 2% are called out in
the run summary (Apple's point granularity is fine enough that anything
larger deserves a human look). Subscriptions get no auto-derived territory
prices, so this per-territory pass is what lifts them out of
`MISSING_METADATA`. A territory whose currency has no table target, or
with no usable price point at all, is skipped with a warning (it doesn't
fail the run). Re-runs skip every territory whose current price point is
already the one the tool would pick (point-id comparison — the snapped
point's price string need not equal the target), and create a price
change where the current point differs.

The **IAP** (`--lifetime-price-usd`, default 99.99) keeps a USA base price
via `POST /v1/inAppPurchasePriceSchedules` — its schedule auto-equalizes all
other territories, so no per-territory pass is needed there. Re-runs compare
the current price and create a price change / re-post the schedule when it
drifted, so adjusting prices is just a re-run with new flags. New
subscriptions are also made available in all current + future territories
(`POST /v1/subscriptionAvailabilities`) — a hard prerequisite for setting
any price via the API. If the IAP base price point can't be matched, the
product still gets created and the tool prints the console deep-link and
exits non-zero.

**Manual afterwards:** review the products in App Store Connect and submit
them with the next app version (API-created products start in
"ready to submit"), then attach all three to the RevenueCat entitlement
`pro` — see `docs/revenuecat-setup.md` §3 (don't forget `pro_lifetime`, it
carries the legacy-buyer migration).

## `play-products`

```bash
dart run bin/provision.dart play-products --dry-run
dart run bin/provision.dart play-products \
    --service-account-json ~/.config/obs-blade/play-service-account.json
```

`--package-name` defaults to the `applicationId` read from
`android/app/build.gradle` (found by walking up from the current directory).

Creates, if missing: subscription product **`pro`** (`--subscription-id`)
with base plans **pro-yearly** (`P1Y`) and **pro-monthly** (`P1M`), each with
a US regional price (`--yearly-price-usd` / `--monthly-price-usd`, defaults
49.99 / 4.99), plus one-time product **pro_lifetime** with purchase option
`pro-lifetime` at `--lifetime-price-usd` (default 99.99). Listings are sent
in en-GB (the app's default language — Play rejects creates without it) and
en-US. New base plans and
purchase options are created DRAFT by Play and then activated via the
dedicated activate endpoints (skip with `--no-activate`). Re-runs pick up
missing base plans on an existing subscription via PATCH
(`updateMask=basePlans`) and update drifted prices the same way (one-time
products via the same batchUpdate upsert).

> Play naming constraints: base plan and purchase option ids are RFC-1034
> (lowercase + hyphens — no underscores), so the Play side uses
> `pro:pro-yearly` / `pro:pro-monthly` / `pro_lifetime` (`pro-lifetime`
> purchase option). The app-facing ids stay `pro_yearly` etc. — the mapping
> happens in RevenueCat.

**Manual afterwards:** review products/prices in Play Console (Monetize →
Products; regional pricing is already pinned to the reviewed table per
region), then wire the
products into the RevenueCat entitlement `pro` with store ids
`pro:pro-yearly`, `pro:pro-monthly`, `pro_lifetime` — see
`docs/revenuecat-setup.md` §3.

## Pricing table

Both store commands price from one checked-in, hand-reviewed table:
`lib/src/pricing_targets.dart`. Anchor currencies (USD/EUR/GBP) stay at the
USD nominal (4.99 / 49.99 / 99.99); every other currency uses **Google's
`convertRegionPrices` table** (FX-current, tax-aware, market-rounded —
the same values Play would auto-convert to). Policy baked in: CNY keeps
Apple's mainland-China market pricing (no Play in China, so no Google
reference), and CHF is split per territory (CH and LI price differently on
Google). The iOS lifetime IAP is NOT driven by this table — its
auto-equalized price schedule is maintained by Apple and stays FX-current.

Why not Apple's own equalized tier matrix: it deviates from FX+tax reality
by >20% in ~30 currencies in BOTH directions (e.g. TRY at ~$0.90 for the
$4.99 tier, DKK at ~$153 for the $49.99 tier — found by auditing the live
products in 2026-10 after a Turkish monthly sub came through at ~€0.80).

The workflow when FX rates move (quarterly-ish, or after any suspicious
sale):

```bash
source ~/.localrc
# 1. Cross-check the live stores against the table + independent FX rates.
dart run bin/audit_prices.dart
# 2. Regenerate the table from Google's current convertRegionPrices data…
dart run bin/generate_pricing_targets.dart
# 3. …review the git diff of lib/src/pricing_targets.dart CAREFULLY
#    (this is the human pricing decision — the generator is just a fetch),
#    re-anchor CNY if the diff drops it, then commit.
# 4. Re-apply to both stores (idempotent; only drifted territories move).
dart run bin/provision.dart asc-products
dart run bin/provision.dart play-products
# 5. Verify.
dart run bin/audit_prices.dart
dart run bin/inspect_products.dart
```

`bin/audit_prices.dart` is read-only: it walks every ASC territory + Play
region × product and flags prices that deviate from the table, from Apple's
tier matrix, and from an independent FX rate (open.er-api.com) — outliers in
either direction (too cheap AND too expensive) get listed.

## Inspecting live state

```bash
source ~/.localrc   # OBS_BLADE_ASC_* + OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS
dart run bin/inspect_products.dart
```

Read-only verification tool: prints both subscriptions' and the IAP's
state + en-US localizations, **per-territory subscription price coverage**
(`territories priced: 175/175 — parity OK (reviewed PricingTargets)`,
listing missing or off-target territories), the IAP
base-price note, and the Play listings / base-plan prices. Note: the Play
endpoints are
`.../subscriptions` and `.../oneTimeProducts` — the old
`.../monetization/...` routes were removed server-side and answer with a
bare HTML 404 (no JSON error), which looks exactly like a permission
problem but isn't one.

## Safety notes

- `--dry-run` first. It prints every request with full bodies and needs no
  credentials.
- Nothing is ever deleted; existing resources are detected and skipped
  ("already exists — skipping"), and re-runs are no-ops.
- Secrets are read from paths, never echoed. The API key is the only secret
  the tool *produces*; it goes to stdout once or into a chmod-600 file.
- The tool performs no app-review/submission actions — products are created
  in draft/reviewable state only.

## Development

```bash
dart test      # unit tests (fake HTTP / fake gcloud, no live calls)
dart analyze
```

API field names were verified against Apple's official OpenAPI spec
(app-store-connect-openapi-specification v4.4.1) and the live
androidpublisher v3 discovery doc
(`https://androidpublisher.googleapis.com/$discovery/rest?version=v3`).

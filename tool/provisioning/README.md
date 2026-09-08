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
  en-US localizations (drift-reconciled via PATCH) and **nominal-parity
  subscription pricing in every available territory** (equalized-tier
  fallback where no nominal point exists; US base price for the IAP, whose
  schedule auto-equalizes the other territories).
- **`play-products`** — Google Play: one subscription product (`pro`)
  containing the `pro-yearly` + `pro-monthly` base plans, plus the
  `pro_lifetime` one-time product, with **per-region pricing in all 173
  Play regions** (Play's own `pricing:convertRegionPrices` table —
  conventionally rounded per market, e.g. ¥840 / ₹550 — with nominal
  parity for EUR/GBP/USD, pinned so prices don't drift with FX rates);
  base plans / purchase option are activated after creation. Writes pass
  the table's `regionVersion` (e.g. 2025/03) — an older version gets
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
export ASC_KEY_PATH="$HOME/.config/obs-blade/asc-key.p8"
export ASC_KEY_ID="…"
export ASC_ISSUER_ID="…"
export ASC_APP_ID="…"                         # numeric App Store Connect app id
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/obs-blade/play-svc.json"
export GCP_PROJECT_ID="obs-blade"               # optional, has a sane default
```

An explicit flag always wins over the env var.

| Command | Credential | Env fallback | Where to get it |
|---|---|---|---|
| `gcp-youtube` | gcloud user login | `GCP_PROJECT_ID` (project only; auth is gcloud's own) | `gcloud auth login` (needs permission to create projects, or pre-create the project in the console) |
| `asc-products` | `.p8` key + key id + issuer id | `ASC_KEY_PATH` / `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_APP_ID` | <https://appstoreconnect.apple.com/access/integrations/api> → "Generate API Key" (role: Admin or App Manager) — the `.p8` downloads once, the key id and team-level issuer id are shown on the same page |
| `play-products` | service-account JSON | `GOOGLE_APPLICATION_CREDENTIALS` (the Google-standard var) | GCP: enable the Google Play Developer API, create a service account + JSON key. Play Console → **Users and permissions** → "Invite new users" with the service-account email → grant the OBS Blade app **Admin** (or at least "Manage orders and subscriptions"). Details: [`CREDENTIALS.md`](CREDENTIALS.md) Track 2 |

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

**Subscription pricing is automated for EVERY available territory with
nominal parity.** With `--yearly-price-usd` / `--monthly-price-usd`
(defaults 49.99 / 4.99) the tool reads the territory list from
`GET /v1/subscriptionAvailabilities/{id}/availableTerritories` (the
availability resource shares the subscription's id) and, per territory,
compares the current price (the `GET /v1/subscriptions/{id}/prices` record
without a `startDate`) against the USD nominal string — then sets the price
point whose `customerPrice` equals it ('4.99' → 4.99 EUR in DEU, 4.99 GBP in
GBR, …) via `POST /v1/subscriptionPrices`. Subscriptions get no auto-derived
territory prices, so this per-territory pass is what lifts them out of
`MISSING_METADATA`. Territories without an exact nominal price point
(JPY, SEK, KRW, … have no 4.99/49.99) fall back to the point with the
**same Apple tier as the USA nominal point** — tiers are Apple's global
price matrix (the `p` field embedded in the base64url point id), so the
same tier is the equalized, locally conventional price in every storefront
($4.99 → ¥660 / 64 kr / ₹210 / …, verified live). Fallback territories are
summarized at the end. A territory whose scan finds neither an exact point
nor the reference tier is skipped with a warning (it doesn't fail the
run). Re-runs skip every territory already at the point the tool would
pick — for fallback territories that's a point-id comparison, since the
nominal string never matches there.

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
Products; extend regional pricing beyond US there if wanted), then wire the
products into the RevenueCat entitlement `pro` with store ids
`pro:pro-yearly`, `pro:pro-monthly`, `pro_lifetime` — see
`docs/revenuecat-setup.md` §3.

## Inspecting live state

```bash
source ~/.localrc   # ASC_* + GOOGLE_APPLICATION_CREDENTIALS
dart run bin/inspect_products.dart
```

Read-only verification tool: prints both subscriptions' and the IAP's
state + en-US localizations, **per-territory subscription price coverage**
(`territories priced: 175/175 — parity OK (nominal or equalized tier)`,
listing missing or off-parity territories), the IAP base-price note, and
the Play listings / base-plan prices. Note: the Play endpoints are
`.../subscriptions` and `.../oneTimeProducts` — the old
`.../monetization/...` routes were removed server-side and answer with a
bare HTML 404 (no JSON error), which looks exactly like a permission
problem but isn't one.

`bin/probe_tiers.dart` is a small diagnostic that prints, per product, the
Apple tier of the USA nominal price point and the local price of that same
tier in a handful of storefronts — handy when checking what the
equalized-tier fallback would pick before a run.

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

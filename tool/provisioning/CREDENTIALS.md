# Collecting the provisioning credentials

Step-by-step walkthrough for every env var the provisioning tool reads
(see `README.md` § Credentials for the reference table). Everything lands
in `~/.localrc` (sourced into zsh) or as a chmod-600 file under
`~/.config/obs-blade/`. **Nothing here goes into the repo.**

Estimated total: ~30–45 min, mostly waiting on console pages. You can do
the three tracks in any order.

```bash
# The full block you are collecting:
export ASC_KEY_PATH="$HOME/.config/obs-blade/asc-key.p8"
export ASC_KEY_ID="…"
export ASC_ISSUER_ID="…"
export ASC_APP_ID="…"
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/obs-blade/play-svc.json"
export GCP_PROJECT_ID="obs-blade-youtube"
```

Prep: `mkdir -p ~/.config/obs-blade` and make sure `~/.localrc` itself is
`chmod 600` (it holds tokens — treat it like a key file).

---

## Track 1 — App Store Connect (`ASC_*`)

Covers: the subscription group "Pro", `pro_yearly` / `pro_monthly`,
`pro_lifetime`, incl. US pricing.

1. Open <https://appstoreconnect.apple.com/access/integrations/api>
   (Users and Access → Integrations → App Store Connect API → Team Keys).
2. **Generate API Key** (or add under "Active"). Name: e.g.
   `provisioning`. Role: **App Manager** suffices (Admin also fine).
3. **Download the `.p8` immediately** — Apple shows the download exactly
   once. If you lose it, revoke and regenerate (same key id flow, no harm).
4. On that page, note:
   - **Key ID** — the 10-char id next to your new key → `ASC_KEY_ID`
   - **Issuer ID** — shown at the top of the Integrations page →
     `ASC_ISSUER_ID` (a UUID)
5. Move the key file and lock it down:

   ```bash
   mv ~/Downloads/AuthKey_<KEYID>.p8 ~/.config/obs-blade/asc-key.p8
   chmod 600 ~/.config/obs-blade/asc-key.p8
   ```

6. `ASC_APP_ID`: App Store Connect → Apps → **OBS Blade** → App
   Information → **Apple ID** (the numeric one, not the bundle id).

## Track 2 — Google Play (`GOOGLE_APPLICATION_CREDENTIALS`)

Covers: Play subscription `pro` (base plans `pro-yearly` / `pro-monthly`)
and one-time product `pro_lifetime`.

1. In the **GCP console**, pick or create a project (this is separate
   from the YouTube GCP project — reusing one is fine too) and enable
   the **Google Play Developer API** for it:
   <https://console.developers.google.com/apis/api/androidpublisher.googleapis.com>
2. GCP → **IAM & Admin → Service Accounts**:
   - Create service account, name e.g. `play-provisioning`. No GCP roles
     needed (Play authorizes it, not GCP IAM).
   - Open the service account → **Keys → Add key → Create new key →
     JSON**. The JSON downloads.
3. **Play Console → Users and permissions** (top-level left sidebar;
   the old "Setup → API access" page no longer exists) → **Invite new
   users** → paste the service account's `client_email` from the JSON →
   under **App permissions** add the OBS Blade app with **Admin** (or
   minimal: "Manage orders and subscriptions"). Send the invite — the
   service account activates itself on first API use.
5. Lock down the file:

   ```bash
   mv ~/Downloads/<project>-*.json ~/.config/obs-blade/play-svc.json
   chmod 600 ~/.config/obs-blade/play-svc.json
   ```

> **Propagation caveat:** Play service-account grants can take up to
> ~24 h to take effect (usually minutes). If `play-products` answers
> 401/403 right after setup, wait and retry — the tool is idempotent.

## Track 3 — GCP / YouTube (`GCP_PROJECT_ID`)

Covers: the YouTube Data API key for the quota spike + (later) the OAuth
client for native sign-in.

1. `gcloud auth login` (one time per machine).
2. Pick a project id — globally unique across all of GCP. Default
   `obs-blade-youtube` is fine if unclaimed; otherwise choose another and
   export it as `GCP_PROJECT_ID`.
3. Nothing else to collect: `provision gcp-youtube` creates the project,
   enables the API, and writes the restricted API key to a chmod-600 file
   (`--out-file`).
4. **Console-only afterwards** (no API exists): OAuth consent screen +
   an OAuth client of type **"TVs and Limited Input devices"** — the tool
   prints deep links at the end of its run. That client's id/secret are
   what the in-app YouTube sign-in uses
   (`docs/youtube-native-chat-audit.md`).

---

## Verify the setup

Without printing any secret:

```bash
source ~/.localrc
for v in ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID ASC_APP_ID \
         GOOGLE_APPLICATION_CREDENTIALS GCP_PROJECT_ID; do
  if [ -n "${(P)v}" ] 2>/dev/null || eval "[ -n \"\$$v\" ]"; then
    echo "$v: set"
  else
    echo "$v: MISSING"
  fi
done
ls -l "$ASC_KEY_PATH" "$GOOGLE_APPLICATION_CREDENTIALS"   # expect -rw-------
```

Then dry-run the tool (sends nothing, needs no creds) and, when ready,
the real runs — all idempotent:

```bash
cd tool/provisioning
dart run bin/provision.dart asc-products --dry-run
dart run bin/provision.dart asc-products
dart run bin/provision.dart play-products
dart run bin/provision.dart gcp-youtube \
    --out-file ~/.config/obs-blade/youtube-api-key.txt
```

Afterwards: the remaining manual steps (store agreements, product review
submission, RevenueCat dashboard) are in `docs/revenuecat-setup.md`.

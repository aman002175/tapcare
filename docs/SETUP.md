# Setup

## Local development

Requirements: Flutter 3.35.5+ (stable), Android Studio or a device/emulator.

```sh
flutter pub get
flutter analyze
flutter test
flutter run            # Android device/emulator
flutter run -d chrome  # web build (used by the Freebuff preview)
```

## Environment keys

All future service keys are listed in [`env.example.txt`](../env.example.txt)
(placeholders only — the app does not read them in this build):

| Key | Purpose | Where to get it |
|---|---|---|
| `SUPABASE_URL` | Postgres/Auth/Realtime base URL | Supabase dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Public client key | same page |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side key — **secret**, never ship in the app | same page |
| `KNOCK_API_KEY` | Trigger nudge notifications | Knock dashboard → Platform → API keys |
| `KNOCK_SIGNING_KEY` | Client auth for Knock SDK | same page |
| `RAZORPAY_KEY_ID` | ₹199 checkout | Razorpay dashboard → Settings → API Keys |
| `RAZORPAY_KEY_SECRET` | Payment signature verification — **secret** | same page |

Rules:

- Real values never go in git. Keep them in a local `.env` (git-ignored) or
  GitHub **Actions/Repo secrets**.
- Injection at build time:
  `flutter build apk --dart-define=SUPABASE_URL=... --dart-define=...`
- Push when keys arrive: implement the interfaces in
  `lib/services/backend_services.dart` (see `docs/API.md`).

## Push to GitHub (token only — no report/setup URL)

The **only** credential needed is a GitHub token with `repo`
(or fine-grained **Contents: Read and write**):

```sh
# 0) workflow triggers on `main` — make sure that is your branch
git branch -M main

# 1) commit everything
git add -A
git commit -m "NudgeBuddy: Flutter app + docs + APK workflow"

# 2) remote
git remote add origin https://github.com/<owner>/<repo>.git

# 3) push with the token ONLY (single line — no line-continuation backslashes,
#    and `-c` is a git-level option so it comes BEFORE the subcommand)
git -c "http.https://github.com/.extraheader=AUTHORIZATION: basic $(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 -w0)" push -u origin main
```

Simplest alternative (works in terminals that mangle multi-line pastes):

```sh
export GITHUB_TOKEN=ghp_xxxxxxxx
git remote set-url origin "https://x-access-token:$GITHUB_TOKEN@github.com/<owner>/<repo>.git"
git push -u origin main
git remote set-url origin https://github.com/<owner>/<repo>.git   # drop the token
unset GITHUB_TOKEN
```

- Never commit or echo the token; never put it in the workflow file.
- The Actions workflow uses the default `GITHUB_TOKEN` — no PAT required to
  build the APK.

## GitHub Actions APK build

Workflow: `.github/workflows/build-apk.yml`

- Triggers: push to `main`, or manual `workflow_dispatch`.
- Steps: checkout → Flutter 3.35.5 → `pub get` → `analyze` → `test` →
  `flutter build apk --debug` → upload artifact.
- Download: repo → **Actions** → run → **Artifacts** → `nudgebuddy-apk`.

## Repo secrets (optional, for later)

Settings → Secrets and variables → Actions → add `SUPABASE_URL`, etc., if
you later add a workflow that needs them.

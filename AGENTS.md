# AGENTS.md — TapCare onboarding brief

Read this first. It is the single source of scope for AI coding agents.

## What this is

A **native Flutter (Dart) Android app** — couples/friends send one-tap
caring nudges that appear as a full-screen animated overlay. No chat.
Hindi-first UI with an English switch.

## Stack (locked)

- Flutter 3.35.5 / Dart, Material 3, package `com.tapcare.app`
- State: `flutter_riverpod` (Notifier pattern) · routing: `go_router`
- Local storage: `shared_preferences` · fonts: `google_fonts`
- Home-screen widget: `home_widget` + native `TapCareWidgetProvider`
- CI: GitHub Actions → `flutter build apk --debug` → artifact `tapcare-apk`

## Layout

```text
lib/
  main.dart               # ProviderScope + router + theme
  config/                 # env.dart (placeholder keys), strings.dart (en/hi), presets.dart
  data/romance_content.dart  # quotes, care tips, moods, milestones (bilingual)
  design/romantic_tokens.dart # palette, gradients, radii, shadows, text styles
  models/                 # app_user, pairing, nudge, mood_entry, couple_stats (mirror future SQL)
  services/               # storage_service.dart (LocalStorage)
                          # backend_services.dart (NudgeService/PairService interfaces + demo impls)
                          # home_widget_service.dart (pushes care data to the Android widget)
  state/app_state.dart    # AppController (Riverpod Notifier) + providers + derived CoupleStats
  screens/                # onboarding, home, pair, send_nudge, overlay, settings,
                          # stats, share_card, widget_mode
  widgets/                # romance_motion (mesh bg, floating hearts, fade-in, heartbeat)
                          # heart_burst + shine button, romantic_scaffold,
                          # nudge_overlay (signature animation), splash_screen, theme_card
  themes/widget_themes.dart
android/app/src/main/kotlin/com/tapcare/app/
                          # MainActivity.kt, TapCareWidgetProvider.kt (RemoteViews widget)
android/app/src/main/res/  # widget layouts, widget_bg drawables, tapcare_widget_info.xml
scripts/verify.py         # static guard: imports resolve, hi/en keys, no stale ids
docs/                     # ARCHITECTURE, DATA_MODEL, API, SETUP, PRODUCT_SPEC, MOBILE_BUILD
env.example.txt           # all future keys (placeholders)
.github/workflows/build-apk.yml
```

## Conventions

- Screens consume state only through `appProvider`; never touch
  `SharedPreferences` directly.
- Strings go through `Strings(locale).t('key')` — add keys to
  `config/strings.dart` in **both** `hi` and `en`.
- UI copy: use the `Rom` tokens in `design/romantic_tokens.dart` — warm blush
  palette, gradient accents, radius 16–36, emoji-forward. Don't hardcode
  colours in screens.
- Screens sit inside `RomanticScaffold` (mesh background + floating hearts);
  ambient animations repeat forever, so widget tests must use `pump`
  (never `pumpAndSettle`).
- Models keep snake_case JSON keys matching the future Postgres schema
  (`docs/DATA_MODEL.md`).
- Env keys are read via `lib/config/env.dart` (`--dart-define`) only.

## Guardrails (hard rules)

1. **No Supabase, Knock or Razorpay code** until the owner provides keys.
   Placeholders live in `env.example.txt`; stubs are labeled "coming soon".
2. **Push to GitHub requires only `GITHUB_TOKEN` + repo name** (x-access-token
   method, `docs/SETUP.md`). No report/setup URL. Never commit or log a token.
3. **No features beyond spec** (`docs/PRODUCT_SPEC.md`): no chat, no groups,
   no admin, one active pair, last-20 nudges, local demo data only.
4. Do not convert to Capacitor/PWA — this stays a native Flutter project.
5. Keep `flutter analyze` clean and `flutter test` green before finishing.
   Also run `python3 scripts/verify.py` — it catches unresolved imports and
   missing hi/en string keys without needing a Flutter SDK.
6. Keep the GitHub Actions workflow pinned (Flutter version, action tags).

## Definition of done

- `flutter analyze` → no issues; `flutter test` → all tests pass.
- Cold start → onboarding → pair → send → overlay → seen → recent list works
  with zero network access.
- All 8 docs + `env.example.txt` + workflow present and consistent.
- Web preview loads without errors (APK itself is produced by Actions).

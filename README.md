# TapCare 💛

**बिना बोले, ख्याल** — a native Flutter Android app for couples and friends.
One tap sends a tiny caring reminder ("पानी पी लो", "दवाई खा ली?", "घर
पहुँचकर कॉल करना", "मुस्कुराओ") that appears on the other person's screen as
a beautiful animated overlay. **No chat — just "one tap and care".**

## Why native Flutter (not a web wrap)?

This is a real Flutter/Dart project — the same structure Android Studio
creates (`lib/`, `android/`, Gradle wrapper, `pubspec.yaml`). It is **not** a
Capacitor/PWA wrapper. The APK is built by GitHub Actions on every push.

## Demo mode (this build)

No backend is wired yet. Everything (profile, pair, nudges, seen state) is
stored **on-device** via `shared_preferences`. Supabase, Knock and Razorpay
are **deferred** — placeholders live in `env.example.txt`, and the adapter
interfaces in `lib/services/backend_services.dart` are ready for them.

## Features

**Care ritual**
- Onboarding: display name + avatar emoji (Hindi/English UI switch)
- Pairing: 6-character invite code → exactly two people, one active pair
- One-tap preset nudges (bilingual) + custom short messages
- **Time-aware care**: a "Right now" row suggests the nudge that fits the
  hour (morning water → evening *reach home* → night *rest*)
- **Favorites**: long-press any preset to pin it; favorites get their own row
- **Full-screen animated overlay** with floating hearts, heartbeat, glow card,
  haptics, and a heart-burst celebration on "Seen ❤️"
- Recent nudges: last 20 per pair, seen/unseen badges — no chat, no feed
- Long-press any recent nudge to replay the overlay
- **Branded launch screen**: splash + pulsing heart + animated loading dots
- **Real home-screen widget**: resizable (small ↔ large), animated reveal, and
  it shows the partner's latest nudge, love meter, streak and daily quote.
  Add it via *long-press home screen → Widgets → TapCare*.

**Love dashboard**
- **Love meter** (0–100%): care given + balance + rhythm + acknowledgement,
  animated bar, with a full **breakdown** of what the score is made of
- **This week in love**: rolling 7-day bar chart of who showed up
- **Streak counter**: consecutive days with a nudge 🔥
- **Together counter**: days/months since pairing
- **Mood check-in**: one-tap daily mood (😊 🥰 😌 😔 😤 🤒)
- **Quote of the day** + **care tip of the day** (bilingual)
- **Anniversary countdown** (set a date in Settings)
- **Stats screen**: sent/received/seen breakdown, love balance bar, milestones

**Pretty & playful**
- Animated mesh background + floating hearts ambience on every screen
- 5 accent gradient themes (Blush, Sunset, Lavender, Mint, Night)
- 6 widget themes: 3 free, 3 premium (locked, "Coming soon ₹199" stub)
- **Widget mode**: a mini/large love card you can keep on screen — the closest
  thing to a real home-screen widget in this build
- **Share card**: a gradient "our love" card with your stats, copy-to-share text
- Demo button: **Simulate incoming nudge** shows exactly what your partner sees

## Quick start (local)

```sh
flutter pub get
python3 scripts/verify.py   # imports + hi/en string keys + no stale ids
flutter analyze
flutter test
flutter run          # device/emulator
flutter run -d chrome  # web preview
```

## Download the APK (GitHub Actions)

1. Push this repo to GitHub (see `docs/SETUP.md` — only a `GITHUB_TOKEN`
   is needed, no other URL or credentials).
2. Open the repo → **Actions** → **Build Android APK**.
3. After the run finishes, open the run → **Artifacts** →
   **tapcare-apk** → download the `.apk`.

## Documentation

| File | What it covers |
|---|---|
| `docs/ARCHITECTURE.md` | Layers + how a nudge travels (current + planned) |
| `lib/design/romantic_tokens.dart` | Colours, gradients, radii, shadows, text styles |
| `docs/DATA_MODEL.md` | Local models ↔ future Postgres tables |
| `docs/API.md` | Adapter interfaces + future backend endpoints |
| `docs/SETUP.md` | Env keys, GitHub token push, dashboard setup |
| `docs/PRODUCT_SPEC.md` | Flows and scope boundaries |
| `docs/MOBILE_BUILD.md` | Gradle, versioning, APK artifacts, signing |
| `AGENTS.md` | AI-agent onboarding brief |

## Env template

All future service keys (Supabase, Knock, Razorpay) are listed as
placeholders in [`env.example.txt`](env.example.txt). The app does not read
them in this build.

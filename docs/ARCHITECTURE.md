# Architecture

## Current build (demo/local mode)

```mermaid
flowchart TD
    UI[Flutter screens<br/>home / pair / send / overlay / settings] --> S[app_state.dart<br/>AppController - Riverpod]
    S --> I[NudgeService / PairService<br/>adapter interfaces]
    I --> D[Demo impls<br/>DemoNudgeService / DemoPairService]
    D --> L[LocalStorage<br/>shared_preferences - on device]
    UI -.-> ENV[lib/config/env.dart<br/>placeholder keys - unused]
```

- **Presentation:** `lib/screens/*` + `lib/widgets/*` — Material 3, warm
  pastel theme, Hindi/English strings from `lib/config/strings.dart`.
- **State:** a single Riverpod `Notifier` (`AppController`) owns profile,
  pair, nudges, locale and theme. Screens never touch storage directly.
- **Service layer:** `NudgeService` / `PairService` interfaces in
  `lib/services/backend_services.dart`. Only demo (local) implementations
  exist; swapping in a backend never touches UI code.
- **Persistence:** `LocalStorage` wraps `shared_preferences` (JSON blobs).

## How a nudge travels today (demo)

1. Sender taps a preset (or writes a custom message) → `AppController.sendNudge()`.
2. `DemoNudgeService.sendNudge()` prepends the row and persists the capped
   list (max 20).
3. For the **incoming** demo, "Simulate incoming nudge" creates a row with
   `senderId = demo_incoming` and pushes `OverlayScreen`.
4. `NudgeOverlay` plays the float-in + drift animation; the sender chip and
   message are rendered from the nudge's theme + text.
5. Tapping **Seen ❤️** → `AppController.markSeen()` sets `seen_at`, the
   route pops, and the list shows the ✓ badge.

## Planned (not built — keys required)

```mermaid
flowchart TD
    A[Sender app] -->|Supabase insert| B[(Postgres<br/>nudges table)]
    B --> C[Supabase Realtime channel]
    C --> D[Receiver app - open<br/>OverlayScreen]
    B --> E[Backend function]
    E -->|Knock API| F[Knock → FCM push]
    F --> D2[Receiver app - closed<br/>notification → tap → overlay]
    A -->|Razorpay order| G[₹199 checkout]
    G -->|webhook verify| H[users.premium_unlocked = true]
```

- **Supabase** — Postgres, OTP/magic-link auth, Realtime for live delivery.
- **Knock → FCM** — push when the receiver's app is closed (Knock dashboard
  connects the FCM credentials; no second push provider).
- **Razorpay** — ₹199 one-time unlock; order created server-side, signature
  verified before setting `premium_unlocked`.

## CI/CD

`.github/workflows/build-apk.yml` runs on push to `main`:
checkout → Flutter 3.35.5 (pinned) → `pub get` → `analyze` → `test` →
`build apk --debug` → upload `nudgebuddy-apk` artifact (downloadable from
the Actions run page).

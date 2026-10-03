# API / interfaces

This build has **no network API**. Contract lives in Dart interfaces so a
real backend drops in without touching screens.

## Current: Dart adapter interfaces

`lib/services/backend_services.dart`

```dart
abstract class NudgeService {
  List<Nudge> recentNudges();
  Future<void> sendNudge(Nudge nudge);
  Future<void> markSeen(String nudgeId);
  Future<void> clearNudges();
}

abstract class PairService {
  Pairing? currentPair();
  Future<void> savePair(Pairing pair);
  Future<void> breakPair();
}
```

Demo implementations (`DemoNudgeService`, `DemoPairService`) persist through
`LocalStorage`. Swapping to Supabase = implement these two interfaces with
network calls and change the providers in `lib/state/app_state.dart`.

## Planned endpoints (placeholders — keys required)

### `POST /functions/v1/nudges` — send a nudge (Supabase Edge Function)

```jsonc
// request (Authorization: Bearer <supabase anon key>)
{ "pair_id": "p_...", "message": "पानी पी लो", "theme": "peach", "sound": "soft_chime" }

// 201 response
{ "id": "n_...", "created_at": "2026-10-03T12:00:00Z", "seen_at": null }
```

Side effect: insert into `nudges`, broadcast on the pair's Realtime channel,
then trigger Knock → FCM push if the receiver is offline.

### `POST /functions/v1/pairs/invite` — create invite code

```jsonc
// response
{ "code": "K7PXQ2" }
```

### `POST /functions/v1/pairs/accept` — accept a code

```jsonc
{ "code": "K7PXQ2" }
// → { "pair_id": "p_...", "partner_name": "...", "partner_emoji": "🦊" }
```

### `POST /functions/v1/push/register` — register device

```jsonc
{ "fcm_token": "..." }   // Knock recipient channel
```

### `POST /razorpay/order` — ₹199 premium unlock

```jsonc
// request
{ "amount_in_paise": 19900, "currency": "INR" }
// response
{ "order_id": "order_...", "key_id": "rzp_live_xxx" }
```

### `POST /razorpay/webhook` — verify and unlock

Verifies signature with `RAZORPAY_KEY_SECRET`, then sets
`users.premium_unlocked = true`. Never trust the client for this flag.

## Build-time config

`lib/config/env.dart` reads these via `--dart-define` (placeholders now):

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`KNOCK_API_KEY`, `KNOCK_SIGNING_KEY`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`

Full template: [`env.example.txt`](../env.example.txt).

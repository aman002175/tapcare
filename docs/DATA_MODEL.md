# Data model

Local JSON models mirror the future Postgres tables **1:1** (snake_case keys
already match), so wiring Supabase later is a storage swap, not a rewrite.

## users → `users`

| Field | Local (`lib/models/app_user.dart`) | Type | Notes |
|---|---|---|---|
| id | `id` | text | local: `u_<ts>_<rand>`; future: auth uid |
| display_name | `display_name` | text | required |
| avatar_emoji | `avatar_emoji` | text | single emoji |
| premium_unlocked | `premium_unlocked` | bool | always `false` in this build |
| created_at | `created_at` | ISO-8601 | set on onboarding |

## pairs → `pairs`

| Field | Local (`lib/models/pairing.dart`) | Type | Notes |
|---|---|---|---|
| id | `id` | text | `p_<ts>_<rand>` |
| user_a / user_b | `user_a` / `user_b` | text | exactly two participants |
| partner_name / partner_emoji | same | text | demo convenience fields |
| invite_code | `invite_code` | text(6) | unambiguous charset (no 0/O/1/I) |
| status | `status` | text | `active` |
| created_at | `created_at` | ISO-8601 | |

One active pair per user (scope boundary).

## nudges → `nudges`

| Field | Local (`lib/models/nudge.dart`) | Type | Notes |
|---|---|---|---|
| id | `id` | text | `n_<ts>_<rand>` |
| pair_id | `pair_id` | text? | may be null in unpaired demo |
| sender_id | `sender_id` | text | `demo_incoming` for simulated |
| message | `message` | text | ≤ 120 chars |
| theme | `theme` | text | widget theme id (peach/mint/…) |
| sound | `sound` | text | `soft_chime` |
| created_at | `created_at` | ISO-8601 | |
| seen_at | `seen_at` | ISO-8601? | null = unseen |

**Retention:** last 20 nudges per pair (`LocalStorage.maxNudges`).

## moods → `moods` (v1.1)

| Field | Local (`lib/models/mood_entry.dart`) | Type | Notes |
|---|---|---|---|
| emoji | `emoji` | text | 😊 🥰 😌 😔 😤 🤒 |
| at | `at` | ISO-8601 | newest first, last 30 kept |

## CoupleStats (derived, never stored)

`lib/models/couple_stats.dart` computes from `users + pairs + nudges + moods +
anniversary`: `togetherDays`, `totalNudges`, `mine`, `theirs`, `seenCount`,
`streakDays`, `loveMeter` (balance 0.4 + rhythm 0.3 + ack 0.3), `lastNudgeAt`,
`lastMoodEmoji`, `daysToAnniversary`.

## push_subscriptions (planned)

| Field | Type | Notes |
|---|---|---|
| user_id | text | FK → users |
| fcm_token | text | registered via Knock recipient |
| updated_at | ISO-8601 | |

## Storage keys (shared_preferences)

`profile_json`, `pair_json`, `nudges_json`, `moods_json`, `favorites_json`,
`locale`, `theme`, `accent`, `anniversary`.

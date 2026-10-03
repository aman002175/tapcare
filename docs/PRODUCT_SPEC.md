# Product spec

## Purpose

Couples and friends can send small caring reminders without the awkwardness
of saying them out loud. One tap → an animated overlay on the other screen.
No chat.

## Core flows

1. **Onboarding** — display name + avatar emoji, stored locally.
   Hindi/English switch available on this screen and in Settings.
2. **Pairing** — generate a 6-character invite code (unambiguous charset)
   or enter a partner's code + name + emoji → one active pair.
3. **Send nudge** — preset grid (6 bilingual presets: water, medicine,
   reach-home, smile, rest, eat) or a custom message (≤ 120 chars).
   One tap sends.
4. **Receive nudge** — full-screen animated overlay: sender chip, floating
   message card (drift animation), single **Seen ❤️** action.
   Demo trigger: **Simulate incoming nudge** on home.
5. **Recent nudges** — last 20 per pair with seen/unseen badges and a
   relative timestamp (`now` / `5m` / `3h` / `2d`).
6. **Premium stub** — Settings shows 3 premium themes locked with
   "Coming soon" and a ₹199 tag. **No payment flow in this build.**

## Love dashboard (v1.1)

- **Love meter** 0–100% = balance (40%) + rhythm/streak (30%) + acknowledgement
  (30%). Derived on the fly in `models/couple_stats.dart`, never stored.
- **Streak** — consecutive days ending today/yesterday with at least one nudge.
- **Together** — days since pairing (chips switch to months after 30 days).
- **Mood check-in** — one tap per day, last 30 moods kept locally.
- **Quote of the day / care tip of the day** — deterministic per-day pick from
  `data/romance_content.dart` (bilingual, no network).
- **Anniversary countdown** — next occurrence of a user-set date.
- **Share card** — gradient card + copyable summary text (no image export).
- **Widget mode** — small/large love card preview with one-tap nudge; this is
  the demo stand-in for a true home-screen widget.
- **Accent themes** — 5 gradients (Blush, Sunset, Lavender, Mint, Night) that
  drive cards, buttons and the overlay.
- **Favorites** — long-press a preset to pin/unpin it.

## Scope boundaries

- **No chat**, no message threads, no typing indicators.
- **One active pair per user**; breaking a pair clears recent nudges.
- **Last 20 nudges** retained locally.
- **No backend, no accounts, no push** in this build — local demo only.
- **No Razorpay code** until keys are provided (stub only).
- **No groups, no admin panel, no feeds, no discovery.**
- Single Android target (`com.nudgebuddy.app`); web build exists for the
  hosted preview only.

## Design language

Mobile-first; soft blush palette (`#FFF4F0` bg, rose `#FF6E91`, coral
`#FF8A5B`, lilac, mint), rounded cards (14–36 radius), playful emoji, warm
ink `#4A2F3A`. Animated mesh background + floating hearts on every screen;
entrance fades, heartbeat on the logo, heart burst on send/seen. No heavy
animation packages — pure Flutter implicit animations and transforms.

## Definition of done (v1)

- `flutter analyze` clean, `flutter test` green.
- Onboarding → pair → send → overlay → seen → recent list all work from a
  cold start with no network.
- Love meter, streak, mood check-in, stats and share card render without
  errors on a 360×640 viewport.
- All 8 docs + `env.example.txt` + workflow present and consistent.
- GitHub Actions produces a downloadable APK artifact on push to `main`.

# Milk & Mocha artwork

`lib/widgets/bear_pair.dart` + `lib/widgets/bear_rig.dart` render **these exact
files**. Nothing is re-drawn with Flutter shapes — a code-drawn bear looks
rough, and these two deserve their real artwork.

## 1. Flat artwork (required — 4 files)

Transparent background PNGs. These are what the characters show by default.

| File | What it is | Used for |
|---|---|---|
| `milk_mocha_kiss.png` | the couple hugging / kissing | "loving" mood, tap reaction 1 |
| `milk_mocha_hearts.png` | the couple under a pile of hearts | "happy"/"angry" mood, tap reaction 2 |
| `milk_mocha_gift.png` | one bear offering a heart | "calm"/"sulky" mood, tap reaction 3 |
| `mocha_peek.png` | the single bear peeking out | "sad"/waiting mood, tap reaction 4 |

With only these, the bears already walk their lane, breathe, glance at each
other, bob while walking and change posture with the mood.

## 2. Cut-out parts (optional — make them *live*)

Cut each character into parts and add them next to the flat art. Every part is
optional: whatever is missing simply drops out, so you can add them one by one
and see the difference immediately.

Per character, using the name prefix (`milk_` / `mocha_`):

| Part file | What it enables |
|---|---|
| `milk_body.png` / `mocha_body.png` | body without the head, so the head can turn independently |
| `milk_head.png` / `mocha_head.png` | head that rotates on the neck |
| `milk_eye_l.png` / `mocha_eye_l.png` | left eye |
| `milk_eye_r.png` / `mocha_eye_r.png` | right eye |
| `milk_lid_l.png` / `mocha_lid_l.png` | closed eyelid — **this is what makes them blink** |
| `milk_lid_r.png` / `mocha_lid_r.png` | closed eyelid (right) |
| `milk_mouth.png` / `mocha_mouth.png` | resting mouth |
| `milk_mouth_open.png` / `mocha_mouth_open.png` | open mouth, used while they "talk" back after a tap |
| `milk_arm.png` / `mocha_arm.png` | arm that swings while walking |

How to cut them: keep every part on the **same canvas size and position** as the
flat artwork (do not crop each part to its own bounding box) — the rig places
them by fraction of the character box, so only the silhouette has to be erased.

Where each piece is drawn is in `RigLayout` (`lib/widgets/bear_rig.dart`) —
`headTop`, `eyeTop`, `mouthTop`, `armTop` etc. If your cut is positioned
differently, nudging those numbers is a one-line change per piece.

## 3. Wiring

The folder is already declared in `pubspec.yaml`, so **dropping the files in is
all that is needed** — no code change, no asset-list edit:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/characters/
```

`BearArt.probe()` runs once at startup and records which files are really in
the bundle; anything missing falls back to the flat art (and, if that is missing
too, to a soft placeholder — it never throws).
# Milk & Mocha artwork

`lib/widgets/bear_pair.dart` renders **these exact files**. They are the only
characters in the app — nothing is re-drawn with Flutter shapes, because a
code-drawn bear looks rough and these two deserve their real artwork.

Drop the four PNGs here (transparent background, square-ish canvas):

| File | What it is | Used for |
|---|---|---|
| `milk_mocha_kiss.png` | the couple hugging / kissing | "loving" mood, tap reaction 1 |
| `milk_mocha_hearts.png` | the couple under a pile of hearts | "happy"/"angry" mood, tap reaction 2 |
| `milk_mocha_gift.png` | one bear offering a heart | "calm"/"sulky" mood, tap reaction 3 |
| `mocha_peek.png` | the single bear peeking out | "sad"/waiting mood, tap reaction 4 |

Then declare them once in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/characters/
```

Until the files are present the card renders a soft placeholder and never
throws — so the app still builds and runs.
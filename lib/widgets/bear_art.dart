import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Every artwork file the Milk & Mocha characters can use.
///
/// **Flat art** (the four files you already have) is enough to make the bears
/// walk, breathe, blink-by-posture and turn their heads around. **Cut-out
/// parts** are what let them really *live*: a separate head that rotates on the
/// neck, eyes that blink, a mouth that opens, an arm that swings.
///
/// Every part is optional. Whatever is missing simply drops out and the
/// character falls back to the flat artwork, so the art can be re-cut in
/// stages without touching code.
///
/// [probe] is awaited once at startup so the app never calls `Image.asset` on
/// a file that is not in the bundle — a missing file would otherwise throw an
/// image-stream error on every rebuild.
class BearArt {
  BearArt._();

  // ---- flat artwork (always used as the base layer) ----
  static const String kiss = 'assets/characters/milk_mocha_kiss.png';
  static const String hearts = 'assets/characters/milk_mocha_hearts.png';
  static const String gift = 'assets/characters/milk_mocha_gift.png';
  static const String peek = 'assets/characters/mocha_peek.png';

  /// Artwork cycle played on every tap.
  static const List<String> reactions = <String>[kiss, hearts, gift, peek];

  /// Emoji that pops out with each tap reaction, same order as [reactions].
  static const List<String> reactionEmojis = <String>['💗', '💕', '🎁', '🥺'];

  // ---- optional cut-out parts ----
  /// Two characters: Milk (you) and Mocha (your partner).
  static const Map<String, List<String>> parts = <String, List<String>>{
    'milk': <String>[
      'milk_body.png',
      'milk_head.png',
      'milk_eye_l.png',
      'milk_eye_r.png',
      'milk_lid_l.png',
      'milk_lid_r.png',
      'milk_mouth.png',
      'milk_mouth_open.png',
      'milk_arm.png',
    ],
    'mocha': <String>[
      'mocha_body.png',
      'mocha_head.png',
      'mocha_eye_l.png',
      'mocha_eye_r.png',
      'mocha_lid_l.png',
      'mocha_lid_r.png',
      'mocha_mouth.png',
      'mocha_mouth_open.png',
      'mocha_arm.png',
    ],
  };

  /// Full path of one optional part.
  static String part(String who, String file) => 'assets/characters/$file';

  static List<String> get _flatPaths => <String>[kiss, hearts, gift, peek];

  static final Set<String> _present = <String>{};
  static bool _probed = false;

  /// Flips to `true` once [probe] has finished.
  ///
  /// The probe runs *behind* the splash, never before `runApp()` — awaiting it
  /// first left the empty native launch window on screen for longer, which is
  /// exactly the blank flash we are trying to remove. Widgets that draw the
  /// artwork listen to this so they pick the pictures up the moment they are
  /// known, instead of being stuck on the placeholder.
  static final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  /// True only when [path] is really in the asset bundle.
  ///
  /// Before [probe] has run it returns `false`, so tests and the very first
  /// frame render the soft placeholder instead of firing a failed image load.
  static bool has(String path) => _probed && _present.contains(path);

  /// Resolves which artwork actually made it into the build.
  ///
  /// Cheap: one bundle lookup per file, all inside a try/catch. Never throws.
  static Future<void> probe() async {
    try {
      for (final String path in <String>[
        ..._flatPaths,
        for (final List<String> group in parts.values)
          for (final String file in group) part('x', file),
      ]) {
        try {
          await rootBundle.load(path);
          _present.add(path);
        } catch (_) {
          // Not in the bundle — this part simply does not exist.
        }
      }
    } finally {
      _probed = true;
      ready.value = true;
    }
  }

  /// True when the artwork has been cut into parts, so the rig can animate a
  /// neck, blink and a mouth. False = flat artwork only.
  static bool get layered =>
      _probed &&
      _present.contains(part('x', 'milk_head.png')) &&
      _present.contains(part('x', 'milk_body.png'));
}
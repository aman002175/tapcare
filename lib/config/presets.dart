/// Ready-made nudges — the heart of TapCare.
/// Every preset is available in Hindi and English, and each one is tagged
/// with the time of day it makes most sense in, so the app can surface the
/// care that actually fits *right now* (morning water, evening "reach home",
/// night "rest") instead of an undifferentiated grid.
class PresetNudge {
  const PresetNudge({
    required this.id,
    required this.emoji,
    required this.hi,
    required this.en,
    this.slots = const <TimeSlot>{},
  });

  final String id;
  final String emoji;
  final String hi;
  final String en;

  /// Time slots this nudge suits. Empty means "fits any time".
  final Set<TimeSlot> slots;

  String message(String lang) => lang == 'hi' ? hi : en;

  /// How strongly this nudge suits the given slot (0 = no, 2 = perfect).
  int fit(TimeSlot slot) {
    if (slots.isEmpty) return 1;
    return slots.contains(slot) ? 2 : 0;
  }
}

/// Time of day, used to make care contextual.
enum TimeSlot { morning, afternoon, evening, night }

extension TimeSlotLabel on TimeSlot {
  String key() => switch (this) {
        TimeSlot.morning => 'morning',
        TimeSlot.afternoon => 'afternoon',
        TimeSlot.evening => 'evening',
        TimeSlot.night => 'night',
      };

  String emoji() => switch (this) {
        TimeSlot.morning => '🌅',
        TimeSlot.afternoon => '☀️',
        TimeSlot.evening => '🌇',
        TimeSlot.night => '🌙',
      };
}

/// Which slot the user is in right now (24h local time).
TimeSlot currentSlot([DateTime? at]) {
  final d = at ?? DateTime.now();
  final h = d.hour;
  if (h >= 5 && h < 11) return TimeSlot.morning;
  if (h >= 11 && h < 17) return TimeSlot.afternoon;
  if (h >= 17 && h < 21) return TimeSlot.evening;
  return TimeSlot.night;
}

const List<PresetNudge> kPresets = <PresetNudge>[
  PresetNudge(
    id: 'water',
    emoji: '💧',
    hi: 'पानी पी लो',
    en: 'Drink water',
    slots: <TimeSlot>{TimeSlot.morning, TimeSlot.afternoon, TimeSlot.evening},
  ),
  PresetNudge(
    id: 'eat',
    emoji: '🍽️',
    hi: 'खाना खा लिया?',
    en: 'Did you eat?',
    slots: <TimeSlot>{TimeSlot.morning, TimeSlot.afternoon, TimeSlot.evening},
  ),
  PresetNudge(
    id: 'medicine',
    emoji: '💊',
    hi: 'दवाई खा ली?',
    en: 'Did you take your medicine?',
    slots: <TimeSlot>{TimeSlot.afternoon, TimeSlot.evening},
  ),
  PresetNudge(
    id: 'reach_home',
    emoji: '🏠',
    hi: 'घर पहुँचकर कॉल करना',
    en: 'Call me when you reach home',
    slots: <TimeSlot>{TimeSlot.evening, TimeSlot.night},
  ),
  PresetNudge(
    id: 'smile',
    emoji: '😊',
    hi: 'मुस्कुराओ',
    en: 'Smile',
  ),
  PresetNudge(
    id: 'rest',
    emoji: '🌙',
    hi: 'आराम कर लो',
    en: 'Take some rest',
    slots: <TimeSlot>{TimeSlot.night},
  ),
  PresetNudge(
    id: 'miss_you',
    emoji: '🥺',
    hi: 'मुझे तुम्हारी याद आ रही है',
    en: 'I miss you',
  ),
  PresetNudge(
    id: 'proud',
    emoji: '🌟',
    hi: 'तुम पर बहुत गर्व है',
    en: 'Proud of you today',
  ),
  PresetNudge(
    id: 'breathe',
    emoji: '🫧',
    hi: 'एक गहरी साँस ले, सब ठीक होगा',
    en: 'Take a deep breath — it gets better',
    slots: <TimeSlot>{TimeSlot.evening, TimeSlot.night},
  ),
];

/// The best care for [slot], strongest match first. Never empty.
List<PresetNudge> suggestedPresets([DateTime? at]) {
  final slot = currentSlot(at);
  final sorted = List<PresetNudge>.from(kPresets)
    ..sort((PresetNudge a, PresetNudge b) =>
        b.fit(slot).compareTo(a.fit(slot)));
  return sorted.take(4).toList(growable: false);
}

PresetNudge presetById(String id) => kPresets.firstWhere(
      (PresetNudge p) => p.id == id,
      orElse: () => kPresets.first,
    );

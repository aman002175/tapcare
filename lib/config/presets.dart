/// Ready-made nudges — the heart of NudgeBuddy.
/// Every preset is available in Hindi and English.
class PresetNudge {
  const PresetNudge({
    required this.id,
    required this.emoji,
    required this.hi,
    required this.en,
  });

  final String id;
  final String emoji;
  final String hi;
  final String en;

  String message(String lang) => lang == 'hi' ? hi : en;
}

const List<PresetNudge> kPresets = <PresetNudge>[
  PresetNudge(
    id: 'water',
    emoji: '💧',
    hi: 'पानी पी लो',
    en: 'Drink water',
  ),
  PresetNudge(
    id: 'medicine',
    emoji: '💊',
    hi: 'दवाई खा ली?',
    en: 'Did you take your medicine?',
  ),
  PresetNudge(
    id: 'reach_home',
    emoji: '🏠',
    hi: 'घर पहुँचकर कॉल करना',
    en: 'Call me when you reach home',
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
  ),
  PresetNudge(
    id: 'eat',
    emoji: '🍽️',
    hi: 'खाना खा लिया?',
    en: 'Did you eat?',
  ),
];

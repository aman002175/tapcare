/// Romantic content: quotes of the day, care tips, moods, celebration lines.
/// Bilingual (hi / en) — no network needed.
class RomanceContent {
  RomanceContent._();

  static const List<Map<String, String>> quotes = <Map<String, String>>[
    <String, String>{
      'hi': 'प्यार वह नहीं जो साथ हो, प्यार वह है जो याद रहे।',
      'en': 'Love is not being together, it is being remembered.',
    },
    <String, String>{
      'hi': 'एक छोटा "पानी पी लो" कभी-कभी किसी बड़ी बात से ज़्यादा कहता है।',
      'en': 'A tiny "drink water" can say more than a long conversation.',
    },
    <String, String>{
      'hi': 'आज कोई बात मत करो — बस एक नज़ भेज दो, मुस्कान बाकी है।',
      'en': 'Say nothing today — just send a nudge, the smile does the rest.',
    },
    <String, String>{
      'hi': 'जो लोग याद रखते हैं, वही लोग असली होते हैं।',
      'en': 'The ones who remember are the ones who are real.',
    },
    <String, String>{
      'hi': 'देखभाल सबसे खूबसूरत तुलहारी है।',
      'en': 'Care is the most beautiful love language.',
    },
    <String, String>{
      'hi': 'रोज़ एक नज़, ज़िंदगी पूरी।',
      'en': 'One nudge a day keeps the distance away.',
    },
  ];

  static const List<Map<String, String>> careTips = <Map<String, String>>[
    <String, String>{
      'hi': '💧 रोज़ 2 लीटर पानी — थोड़ा-थोड़ा करके, बीच-बीच में याद दिलाओ।',
      'en': '💧 2 litres a day — remind in small, frequent nudges.',
    },
    <String, String>{
      'hi': '😴 सोने से 30 मिनट पहले स्क्रीन बंद करो — अच्छी नींद ही अच्छा प्यार है।',
      'en': '😴 Screens off 30 min before sleep — good rest is love too.',
    },
    <String, String>{
      'hi': '🍽️ भोजन के साथ 10 मिनट बात — बिना फ़ोन, सिर्फ़ आप दोनों।',
      'en': '🍽️ 10 phone-free minutes at dinner — just the two of you.',
    },
    <String, String>{
      'hi': '🚶 रोज़ 15 मिनट साथ चलो — बातें नहीं, साथ चलना ही काफ़ी है।',
      'en': '🚶 Walk 15 minutes together — presence beats words.',
    },
    <String, String>{
      'hi': '🌸 छोटी-छोटी खुशियाँ मनाओ — birthday के अलावा भी।',
      'en': '🌸 Celebrate the tiny wins — not just birthdays.',
    },
    <String, String>{
      'hi': '💌 लंबे message की जगह एक warm nudge — याद रहेगा।',
      'en': '💌 One warm nudge beats a long text — it stays in memory.',
    },
  ];

  static const List<Map<String, String>> celebrations = <Map<String, String>>[
    <String, String>{
      'hi': 'पहली नज़ भेजी! 🎉',
      'en': 'First nudge sent! 🎉',
    },
    <String, String>{
      'hi': '7 दिन की लय बन गई 🔥',
      'en': 'A 7-day rhythm is forming 🔥',
    },
    <String, String>{
      'hi': 'आज दोनों ने एक-दूसरे को देखा 💗',
      'en': 'You both showed up for each other today 💗',
    },
    <String, String>{
      'hi': 'प्यार भरा दिन! 🌸',
      'en': 'A love-filled day! 🌸',
    },
  ];

  static const List<Map<String, String>> moods = <Map<String, String>>[
    <String, String>{'emoji': '😊', 'hi': 'खुश', 'en': 'Happy'},
    <String, String>{'emoji': '🥰', 'hi': 'प्यार में', 'en': 'Loved'},
    <String, String>{'emoji': '😌', 'hi': 'शांत', 'en': 'Calm'},
    <String, String>{'emoji': '😔', 'hi': 'उदास', 'en': 'Low'},
    <String, String>{'emoji': '😤', 'hi': 'गुस्सा', 'en': 'Grumpy'},
    <String, String>{'emoji': '🤒', 'hi': 'बीमार', 'en': 'Unwell'},
  ];

  static String quoteOfTheDay(String lang) {
    final now = DateTime.now();
    final index = (now.year * 1000 + now.month * 40 + now.day) % quotes.length;
    final q = quotes[index];
    return q[lang] ?? q['en'] ?? '';
  }

  static String tipOfTheDay(String lang) {
    final now = DateTime.now();
    final index = (now.year * 500 + now.month * 30 + now.day) % careTips.length;
    final t = careTips[index];
    return t[lang] ?? t['en'] ?? '';
  }
}

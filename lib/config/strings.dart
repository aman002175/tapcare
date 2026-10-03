/// Simple Hindi/English string map (no localization package needed).
/// Usage: `Strings(app.locale).t('key')`
class Strings {
  Strings(this.lang);

  final String lang;

  static const List<String> supported = <String>['hi', 'en'];

  String t(String key) =>
      _map[key]?[lang] ?? _map[key]?['en'] ?? key;

  static const Map<String, Map<String, String>> _map =
      <String, Map<String, String>>{
    'appTitle': {'hi': 'NudgeBuddy', 'en': 'NudgeBuddy'},
    'tagline': {'hi': 'बिना बोले, ख्याल 💛', 'en': 'Care without words 💛'},
    'onboardTitle': {
      'hi': 'नमस्ते! अपना नाम बताओ',
      'en': 'Hey! Tell us your name',
    },
    'nameHint': {'hi': 'तुम्हारा नाम', 'en': 'Your name'},
    'chooseEmoji': {'hi': 'अपना इमोजी चुनो', 'en': 'Pick your emoji'},
    'startBtn': {'hi': 'शुरू करें', 'en': 'Get started'},
    'nameRequired': {'hi': 'नाम ज़रूर लिखो', 'en': 'Please enter a name'},
    'settings': {'hi': 'सेटिंग्स', 'en': 'Settings'},
    'pairTitle': {'hi': 'अपना इंसान जोड़ो', 'en': 'Pair your person'},
    'pairSubtitle': {
      'hi': 'दो फ़ोन, एक जोड़ी — कोई चैट नहीं, सिर्फ़ ख्याल।',
      'en': 'Two phones, one pair — no chat, just care.',
    },
    'myCode': {'hi': 'तुम्हारा इनवाइट कोड', 'en': 'Your invite code'},
    'copy': {'hi': 'कॉपी', 'en': 'Copy'},
    'copied': {'hi': 'कोड कॉपी हो गया', 'en': 'Code copied'},
    'shareHint': {
      'hi': 'यह कोड अपने पार्टनर को भेजो',
      'en': 'Send this code to your partner',
    },
    'orDivider': {'hi': 'या', 'en': 'or'},
    'enterCode': {'hi': 'सामने वाले का कोड डालो', 'en': 'Enter their code'},
    'partnerName': {'hi': 'उनका नाम', 'en': 'Their name'},
    'acceptBtn': {'hi': 'जोड़ी बनाओ', 'en': 'Create pair'},
    'codeTooShort': {
      'hi': 'कोड कम से कम 4 अक्षर का हो',
      'en': 'Code must be at least 4 characters',
    },
    'pairedWith': {'hi': 'साथ में', 'en': 'Paired with'},
    'breakPair': {'hi': 'जोड़ी हटाओ', 'en': 'Break pair'},
    'breakPairConfirm': {
      'hi': 'जोड़ी हटा दें? हाल के नज़ भी हट जाएँगे।',
      'en': 'Remove the pair? Recent nudges will be cleared too.',
    },
    'unpaired': {'hi': 'अभी अकेले हो', 'en': 'Not paired yet'},
    'inviteCta': {'hi': 'इनवाइट बनाओ', 'en': 'Create invite'},
    'sendSection': {'hi': 'एक टैप और केयर', 'en': 'One tap and care'},
    'sendSectionSub': {
      'hi': 'दबाओ और ख्याल पहुँचाओ — बोलने की ज़रूरत नहीं।',
      'en': 'Tap to send care — no need to say it out loud.',
    },
    'writeOwn': {'hi': 'अपने शब्द लिखो', 'en': 'Write your own'},
    'simBtn': {
      'hi': 'आने वाला नज़ दिखाओ',
      'en': 'Simulate incoming nudge',
    },
    'simHint': {
      'hi': '(डेमो) सामने वाले को कैसा दिखेगा, वैसा ही',
      'en': '(Demo) exactly what your partner would see',
    },
    'recentTitle': {'hi': 'हाल के नज़', 'en': 'Recent nudges'},
    'emptyRecent': {
      'hi': 'अभी कोई नज़ नहीं — ऊपर से एक भेजो!',
      'en': 'No nudges yet — send one from above!',
    },
    'sentToast': {'hi': 'नज़ भेजा गया 💛', 'en': 'Nudge sent 💛'},
    'notSeenYet': {
      'hi': 'सामने वाले ने अभी नहीं देखा',
      'en': 'Not seen by them yet',
    },
    'seenLabel': {'hi': 'देख लिया', 'en': 'Seen'},
    'unseenLabel': {'hi': 'नया', 'en': 'New'},
    'mineLabel': {'hi': 'तुम', 'en': 'You'},
    'language': {'hi': 'भाषा', 'en': 'Language'},
    'yourName': {'hi': 'तुम्हारा नाम', 'en': 'Your name'},
    'save': {'hi': 'सहेजो', 'en': 'Save'},
    'cancel': {'hi': 'रद्द', 'en': 'Cancel'},
    'themes': {'hi': 'विजेट थीम', 'en': 'Widget themes'},
    'premium': {'hi': 'प्रीमियम', 'en': 'Premium'},
    'comingSoon': {'hi': 'जल्द आ रहा है', 'en': 'Coming soon'},
    'premiumTitle': {'hi': 'प्रीमियम अनलॉक', 'en': 'Premium unlock'},
    'premiumLine1': {
      'hi': 'कस्टम थीम, एनिमेटेड डेकोर और ख़ास साउंड्स।',
      'en': 'Custom themes, animated decor and special sounds.',
    },
    'premiumLine2': {
      'hi': '₹199 वन-टाइम — पेमेंट चाबियाँ मिलने पर जुड़ेगा।',
      'en': '₹199 one-time — activates once payment keys are added.',
    },
    'locked': {'hi': 'लॉक्ड', 'en': 'Locked'},
    'demoBadge': {'hi': 'डेमो मोड', 'en': 'Demo mode'},
    'demoNote': {
      'hi': 'सब कुछ इसी फ़ोन में सेव होता है — कोई सर्वर नहीं।',
      'en': 'Everything is stored on this phone — no server.',
    },
    'about': {'hi': 'बारे में', 'en': 'About'},
    'overlayFrom': {'hi': 'से नज़', 'en': 'nudge from'},
    'needPair': {'hi': 'पहले जोड़ी बनाओ', 'en': 'Create a pair first'},
    'pairToast': {'hi': 'जोड़ी बन गई! 💛', 'en': 'Paired up! 💛'},
    'unpairedToast': {'hi': 'जोड़ी हटा दी गई', 'en': 'Pair removed'},
    'overlaySeenBtn': {'hi': 'देख लिया ❤️', 'en': 'Seen ❤️'},
    'nudgeNotFound': {'hi': 'नज़ नहीं मिला', 'en': 'Nudge not found'},
    'backHome': {'hi': 'होम पर वापस', 'en': 'Back to home'},
    'partnerDefault': {'hi': 'पार्टनर', 'en': 'Partner'},
    'buddyDefault': {'hi': 'दोस्त', 'en': 'Buddy'},
    'sendBtn': {'hi': 'भेजो', 'en': 'Send'},
    'writeHint': {
      'hi': 'जैसे: कॉल करना मत भूलना…',
      'en': 'e.g. Do not forget to call…',
    },
    'pairEmptyHint': {
      'hi': 'कोड बनाकर सामने वाले को भेजो, या उसका कोड डालो।',
      'en': 'Share your code, or enter theirs to pair up.',
    },

    // ---- romance additions ----
    'quoteOfDay': {'hi': 'आज का प्यार', 'en': "Quote of the day"},
    'careTip': {'hi': 'आज की देखभाल', 'en': "Care tip"},
    'loveMeter': {'hi': 'प्यार का पैमाना', 'en': 'Love meter'},
    'streak': {'hi': 'लय', 'en': 'Streak'},
    'dayStreak': {'hi': 'दिन', 'en': 'days'},
    'together': {'hi': 'साथ में', 'en': 'Together'},
    'moodCheckIn': {'hi': 'आज कैसा है?', 'en': 'How are you today?'},
    'moodDone': {'hi': 'मूड सेव हो गया 💚', 'en': 'Mood saved 💚'},
    'favorites': {'hi': 'पसंदीदा', 'en': 'Favorites'},
    'yourStats': {'hi': 'तुम दोनों की कहानी', 'en': 'Your story'},
    'nudgesSent': {'hi': 'भेजे', 'en': 'sent'},
    'nudgesGot': {'hi': 'पाए', 'en': 'received'},
    'seenOnes': {'hi': 'देखे गए', 'en': 'seen'},
    'shareCard': {'hi': 'शेयर कार्ड', 'en': 'Share card'},
    'shareCardTitle': {'hi': 'हमारा प्यार 💗', 'en': 'Our love 💗'},
    'copiedToClipboard': {'hi': 'कॉपी हो गया 📋', 'en': 'Copied 📋'},
    'widgetMode': {'hi': 'विजेट मोड', 'en': 'Widget mode'},
    'widgetModeHint': {
      'hi': 'फ़ोन की स्क्रीन पर छोटा कार्ड — यही असली विजेट है',
      'en': 'A mini card on your phone screen — the real widget',
    },
    'anniversary': {'hi': 'ख़ास तारीख़', 'en': 'Anniversary'},
    'setAnniversary': {'hi': 'तारीख़ सेट करो', 'en': 'Set a date'},
    'daysToGo': {'hi': 'दिन बाक़ी', 'en': 'days to go'},
    'accent': {'hi': 'एक्सेंट रंग', 'en': 'Accent color'},
    'noHistory': {'hi': 'अभी कोई नज़ नहीं', 'en': 'No nudges yet'},
    'replay': {'hi': 'दोबारा देखो', 'en': 'Replay'},
    'longPressHint': {
      'hi': 'किसी भी नज़ को दबाकर दोबारा देख सकते हो',
      'en': 'Long-press any nudge to replay it',
    },
    'sendQuick': {'hi': 'तुरंत भेजो', 'en': 'Quick send'},
    'anniversarySet': {'hi': 'तारीख़ सेट हो गई 💐', 'en': 'Date saved 💐'},
  };
}

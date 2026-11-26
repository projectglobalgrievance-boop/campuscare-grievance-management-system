/// Featherweight localization for the student-facing core (home, tabs,
/// submit flow). English is the fallback; admin screens stay English.
/// Add keys here as screens get translated.
class L10n {
  L10n._();

  static String code = 'en'; // 'en' | 'kn' | 'hi'

  static const languages = {'en': 'English', 'kn': 'ಕನ್ನಡ', 'hi': 'हिन्दी'};

  static String t(String key) =>
      _s[code]?[key] ?? _s['en']![key] ?? key;

  static const Map<String, Map<String, String>> _s = {
    'en': {
      'hi': 'Hi',
      'spotted': 'Spotted something broken on campus?',
      'report_title': 'Report a problem',
      'report_subtitle': "Snap a photo — we'll handle the rest",
      'active': 'Active',
      'resolved': 'Resolved',
      'recent': 'RECENT ACTIVITY',
      'tab_home': 'Home',
      'tab_complaints': 'My Complaints',
      'tab_profile': 'Profile',
      'submit': 'Submit complaint',
      'describe':
          'Describe the problem (optional — the photo says a lot already)',
      'language': 'Language',
      'department': 'Department',
      'pick_department': 'Pick the department this complaint is for',
    },
    'kn': {
      'hi': 'ನಮಸ್ಕಾರ',
      'spotted': 'ಕ್ಯಾಂಪಸ್‌ನಲ್ಲಿ ಏನಾದರೂ ಹಾಳಾಗಿದ್ದು ಕಂಡಿತೆ?',
      'report_title': 'ಸಮಸ್ಯೆ ವರದಿ ಮಾಡಿ',
      'report_subtitle': 'ಫೋಟೋ ತೆಗೆಯಿರಿ — ಉಳಿದದ್ದು ನಾವು ನೋಡಿಕೊಳ್ಳುತ್ತೇವೆ',
      'active': 'ಸಕ್ರಿಯ',
      'resolved': 'ಬಗೆಹರಿದಿದೆ',
      'recent': 'ಇತ್ತೀಚಿನ ಚಟುವಟಿಕೆ',
      'tab_home': 'ಮುಖಪುಟ',
      'tab_complaints': 'ನನ್ನ ದೂರುಗಳು',
      'tab_profile': 'ಪ್ರೊಫೈಲ್',
      'submit': 'ದೂರು ಸಲ್ಲಿಸಿ',
      'describe': 'ಸಮಸ್ಯೆಯನ್ನು ವಿವರಿಸಿ (ಐಚ್ಛಿಕ — ಫೋಟೋ ಸಾಕಷ್ಟು ಹೇಳುತ್ತದೆ)',
      'language': 'ಭಾಷೆ',
      'department': 'ವಿಭಾಗ',
      'pick_department': 'ಈ ದೂರು ಯಾವ ವಿಭಾಗಕ್ಕೆ ಎಂದು ಆಯ್ಕೆ ಮಾಡಿ',
    },
    'hi': {
      'hi': 'नमस्ते',
      'spotted': 'कैंपस में कुछ टूटा-फूटा दिखा?',
      'report_title': 'समस्या दर्ज करें',
      'report_subtitle': 'फोटो खींचिए — बाकी हम संभाल लेंगे',
      'active': 'सक्रिय',
      'resolved': 'हल हुई',
      'recent': 'हाल की गतिविधि',
      'tab_home': 'होम',
      'tab_complaints': 'मेरी शिकायतें',
      'tab_profile': 'प्रोफ़ाइल',
      'submit': 'शिकायत दर्ज करें',
      'describe': 'समस्या का विवरण लिखें (वैकल्पिक — फोटो काफी कुछ कहती है)',
      'language': 'भाषा',
      'department': 'विभाग',
      'pick_department': 'यह शिकायत किस विभाग के लिए है, चुनें',
    },
  };
}

/// Phonetic Latin -> Indic transliteration (offline, rule-based).
///
/// Lets a student type "phone kelsa madtilla" on the ordinary English keyboard
/// and get ಫೋನ್ ಕೆಲಸ ಮಾಡ್ತಿಲ್ಲ. An app cannot switch the phone's keyboard
/// language (Android exposes no such API), so this is how non-English input
/// works on a device with only an English keyboard installed.
///
/// Both scripts are abugidas: a bare consonant already carries an inherent
/// 'a', a following vowel becomes a matra, and a consonant with no vowel takes
/// a virama. That is the whole algorithm.
library;

class Transliterate {
  Transliterate._();

  /// Scripts this supports. 'en' means "leave the text alone".
  static const supported = {'en', 'kn', 'hi'};

  static const _virama = {'kn': '್', 'hi': '्'};
  static const _anusvara = {'kn': 'ಂ', 'hi': 'ं'};

  // Independent vowels (word-initial, or after another vowel).
  static const _vowels = {
    'kn': {
      'a': 'ಅ', 'aa': 'ಆ', 'i': 'ಇ', 'ii': 'ಈ', 'ee': 'ಈ',
      'u': 'ಉ', 'uu': 'ಊ', 'oo': 'ಊ', 'e': 'ಎ', 'E': 'ಏ',
      'ai': 'ಐ', 'o': 'ಒ', 'O': 'ಓ', 'au': 'ಔ',
    },
    'hi': {
      'a': 'अ', 'aa': 'आ', 'i': 'इ', 'ii': 'ई', 'ee': 'ई',
      'u': 'उ', 'uu': 'ऊ', 'oo': 'ऊ', 'e': 'ए', 'E': 'ए',
      'ai': 'ऐ', 'o': 'ओ', 'O': 'ओ', 'au': 'औ',
    },
  };

  // Matras — the same vowels written onto a preceding consonant.
  // 'a' is the inherent vowel, so it adds nothing.
  static const _matras = {
    'kn': {
      'a': '', 'aa': 'ಾ', 'i': 'ಿ', 'ii': 'ೀ', 'ee': 'ೀ',
      'u': 'ು', 'uu': 'ೂ', 'oo': 'ೂ', 'e': 'ೆ', 'E': 'ೇ',
      'ai': 'ೈ', 'o': 'ೊ', 'O': 'ೋ', 'au': 'ೌ',
    },
    'hi': {
      'a': '', 'aa': 'ा', 'i': 'ि', 'ii': 'ी', 'ee': 'ी',
      'u': 'ु', 'uu': 'ू', 'oo': 'ू', 'e': 'े', 'E': 'े',
      'ai': 'ै', 'o': 'ो', 'O': 'ो', 'au': 'ौ',
    },
  };

  static const _consonants = {
    'kn': {
      'k': 'ಕ', 'kh': 'ಖ', 'g': 'ಗ', 'gh': 'ಘ', 'ng': 'ಂ',
      'ch': 'ಚ', 'chh': 'ಛ', 'c': 'ಕ', 'ck': 'ಕ', 'j': 'ಜ', 'jh': 'ಝ', 'ny': 'ಞ',
      'T': 'ಟ', 'Th': 'ಠ', 'D': 'ಡ', 'Dh': 'ಢ', 'N': 'ಣ',
      't': 'ತ', 'th': 'ಥ', 'd': 'ದ', 'dh': 'ಧ', 'n': 'ನ',
      'p': 'ಪ', 'ph': 'ಫ', 'f': 'ಫ', 'b': 'ಬ', 'bh': 'ಭ', 'm': 'ಮ',
      'y': 'ಯ', 'r': 'ರ', 'l': 'ಲ', 'L': 'ಳ', 'v': 'ವ', 'w': 'ವ',
      'sh': 'ಶ', 'shh': 'ಷ', 's': 'ಸ', 'h': 'ಹ', 'z': 'ಜ', 'q': 'ಕ',
    },
    'hi': {
      'k': 'क', 'kh': 'ख', 'g': 'ग', 'gh': 'घ', 'ng': 'ं',
      'ch': 'च', 'chh': 'छ', 'c': 'क', 'ck': 'क', 'j': 'ज', 'jh': 'झ', 'ny': 'ञ',
      'T': 'ट', 'Th': 'ठ', 'D': 'ड', 'Dh': 'ढ', 'N': 'ण',
      't': 'त', 'th': 'थ', 'd': 'द', 'dh': 'ध', 'n': 'न',
      'p': 'प', 'ph': 'फ', 'f': 'फ़', 'b': 'ब', 'bh': 'भ', 'm': 'म',
      'y': 'य', 'r': 'र', 'l': 'ल', 'L': 'ळ', 'v': 'व', 'w': 'व',
      'sh': 'श', 'shh': 'ष', 's': 'स', 'h': 'ह', 'z': 'ज़', 'q': 'क',
    },
  };

  /// Words students actually type. English orthography is not phonetic
  /// ("phone", "light", "block"), and casual romanisation drops the ITRANS
  /// capitals that mark retroflex consonants ("kannada", not "kannaDa"), so
  /// the highest-frequency campus vocabulary is spelled out here. The rules
  /// below handle everything else.
  static const _overrides = {
    'kn': {
      // English loanwords, ubiquitous in campus Kannada
      'fan': 'ಫ್ಯಾನ್', 'light': 'ಲೈಟ್', 'lights': 'ಲೈಟ್ಸ್', 'phone': 'ಫೋನ್',
      'toilet': 'ಟಾಯ್ಲೆಟ್', 'bathroom': 'ಬಾತ್‌ರೂಮ್', 'block': 'ಬ್ಲಾಕ್',
      'library': 'ಲೈಬ್ರರಿ', 'canteen': 'ಕ್ಯಾಂಟೀನ್', 'hostel': 'ಹಾಸ್ಟೆಲ್',
      'room': 'ರೂಮ್', 'class': 'ಕ್ಲಾಸ್', 'classroom': 'ಕ್ಲಾಸ್‌ರೂಮ್',
      'door': 'ಡೋರ್', 'window': 'ವಿಂಡೋ', 'table': 'ಟೇಬಲ್', 'chair': 'ಚೇರ್',
      'bench': 'ಬೆಂಚ್', 'wifi': 'ವೈಫೈ', 'internet': 'ಇಂಟರ್ನೆಟ್',
      'projector': 'ಪ್ರೊಜೆಕ್ಟರ್', 'board': 'ಬೋರ್ಡ್', 'lab': 'ಲ್ಯಾಬ್',
      'computer': 'ಕಂಪ್ಯೂಟರ್', 'printer': 'ಪ್ರಿಂಟರ್', 'dustbin': 'ಡಸ್ಟ್‌ಬಿನ್',
      'water': 'ವಾಟರ್', 'ac': 'ಎಸಿ', 'geyser': 'ಗೀಸರ್', 'lift': 'ಲಿಫ್ಟ್',
      'bus': 'ಬಸ್', 'parking': 'ಪಾರ್ಕಿಂಗ್', 'ground': 'ಗ್ರೌಂಡ್',
      'mess': 'ಮೆಸ್', 'food': 'ಫುಡ್', 'switch': 'ಸ್ವಿಚ್', 'wire': 'ವೈರ್',
      // Kannada
      'neeru': 'ನೀರು', 'bagilu': 'ಬಾಗಿಲು', 'baagilu': 'ಬಾಗಿಲು',
      'kitaki': 'ಕಿಟಕಿ', 'kittaki': 'ಕಿಟಕಿ', 'kelasa': 'ಕೆಲಸ',
      'kelsa': 'ಕೆಲಸ', 'madtilla': 'ಮಾಡ್ತಿಲ್ಲ', 'maadtilla': 'ಮಾಡ್ತಿಲ್ಲ',
      'illa': 'ಇಲ್ಲ', 'sari': 'ಸರಿ', 'madi': 'ಮಾಡಿ', 'maadi': 'ಮಾಡಿ',
      'dayavittu': 'ದಯವಿಟ್ಟು', 'muridide': 'ಮುರಿದಿದೆ', 'tumba': 'ತುಂಬಾ',
      'swalpa': 'ಸ್ವಲ್ಪ', 'kolaku': 'ಕೊಳಕು', 'kannada': 'ಕನ್ನಡ',
      'namaskara': 'ನಮಸ್ಕಾರ', 'gaajina': 'ಗಾಜಿನ', 'odedide': 'ಒಡೆದಿದೆ',
    },
    'hi': {
      'fan': 'फ़ैन', 'light': 'लाइट', 'lights': 'लाइट्स', 'phone': 'फ़ोन',
      'toilet': 'टॉयलेट', 'bathroom': 'बाथरूम', 'block': 'ब्लॉक',
      'library': 'लाइब्रेरी', 'canteen': 'कैंटीन', 'hostel': 'हॉस्टल',
      'room': 'रूम', 'class': 'क्लास', 'classroom': 'क्लासरूम',
      'door': 'डोर', 'window': 'विंडो', 'table': 'टेबल', 'chair': 'चेयर',
      'bench': 'बेंच', 'wifi': 'वाईफ़ाई', 'internet': 'इंटरनेट',
      'projector': 'प्रोजेक्टर', 'board': 'बोर्ड', 'lab': 'लैब',
      'computer': 'कंप्यूटर', 'printer': 'प्रिंटर', 'dustbin': 'डस्टबिन',
      'water': 'वाटर', 'ac': 'एसी', 'geyser': 'गीज़र', 'lift': 'लिफ़्ट',
      'bus': 'बस', 'parking': 'पार्किंग', 'ground': 'ग्राउंड',
      'mess': 'मेस', 'food': 'फ़ूड', 'switch': 'स्विच', 'wire': 'वायर',
      // Hindi
      'pankha': 'पंखा', 'paani': 'पानी', 'pani': 'पानी', 'kaam': 'काम',
      'kam': 'काम', 'nahi': 'नहीं', 'nahin': 'नहीं', 'kar': 'कर',
      'raha': 'रहा', 'rahi': 'रही', 'hai': 'है', 'tuta': 'टूटा',
      'toota': 'टूटा', 'ganda': 'गंदा', 'gandaa': 'गंदा',
      'darwaza': 'दरवाज़ा', 'khidki': 'खिड़की', 'kripya': 'कृपया',
      'bahut': 'बहुत', 'theek': 'ठीक', 'thik': 'ठीक', 'kaksha': 'कक्षा',
      'namaste': 'नमस्ते', 'hindi': 'हिन्दी', 'saaf': 'साफ़',
    },
  };

  static bool _isLatinLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
  }

  /// Longest-match lookup at [i]; returns (key, length) or null.
  static (String, int)? _match(Map<String, String> table, String s, int i) {
    for (var n = 3; n >= 1; n--) {
      if (i + n > s.length) continue;
      final slice = s.substring(i, i + n);
      if (table.containsKey(slice)) return (slice, n);
      final lower = slice.toLowerCase();
      if (table.containsKey(lower)) return (lower, n);
    }
    return null;
  }

  /// Transliterates one run of Latin letters into [lang]'s script.
  static String _word(String latin, String lang) {
    final fixed = _overrides[lang]?[latin.toLowerCase()];
    if (fixed != null) return fixed;
    final cons = _consonants[lang]!;
    final vow = _vowels[lang]!;
    final mat = _matras[lang]!;
    final virama = _virama[lang]!;

    final out = StringBuffer();
    var i = 0;
    var pendingConsonant = false; // a consonant is waiting for its vowel

    while (i < latin.length) {
      // Consonants win over vowels at the same position ('ai' vs 'a'+'i' is
      // handled because we only look for a vowel when no consonant matches).
      final c = _match(cons, latin, i);
      final v = _match(vow, latin, i);

      // Prefer whichever match is longer; on a tie prefer the consonant.
      if (c != null && (v == null || c.$2 >= v.$2)) {
        if (pendingConsonant) out.write(virama);
        out.write(cons[c.$1]!);
        // Anusvara is not a real consonant — it never takes a virama.
        pendingConsonant = cons[c.$1] != _anusvara[lang];
        i += c.$2;
        continue;
      }
      if (v != null) {
        if (pendingConsonant) {
          out.write(mat[v.$1]!);
          pendingConsonant = false;
        } else {
          out.write(vow[v.$1]!);
        }
        i += v.$2;
        continue;
      }
      // Anything we don't know passes straight through.
      if (pendingConsonant) {
        out.write(virama);
        pendingConsonant = false;
      }
      out.write(latin[i]);
      i++;
    }
    // Devanagari writes a word-final consonant bare (काम, not काम्) — schwa
    // deletion is implicit to the reader. Kannada does write it (ಫ್ಯಾನ್).
    if (pendingConsonant && lang != 'hi') out.write(virama);
    return out.toString();
  }

  /// Transliterates every run of Latin letters in [text]; anything already in
  /// an Indic script, plus digits, spaces and punctuation, is left untouched.
  /// Returns [text] unchanged when [lang] is 'en' or unknown.
  static String text(String input, String lang) {
    if (lang == 'en' || !_consonants.containsKey(lang)) return input;
    final out = StringBuffer();
    final run = StringBuffer();
    void flush() {
      if (run.isEmpty) return;
      final w = run.toString();
      run.clear();
      // A lone capital is a block/room label ("Block C"), not a syllable.
      if (w.length == 1 && w == w.toUpperCase() && w != w.toLowerCase()) {
        out.write(w);
        return;
      }
      out.write(_word(w, lang));
    }

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (_isLatinLetter(ch)) {
        run.write(ch);
      } else {
        flush();
        out.write(ch);
      }
    }
    flush();
    return out.toString();
  }
}

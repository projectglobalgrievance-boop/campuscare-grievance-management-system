import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/l10n/transliterate.dart';

void main() {
  group('Transliterate', () {
    test('English is passed through untouched', () {
      const s = 'Fan is not working in Block C';
      expect(Transliterate.text(s, 'en'), s);
    });

    test('unknown language codes are a no-op', () {
      expect(Transliterate.text('fan', 'zz'), 'fan');
    });

    test('common campus words map to correct Kannada', () {
      expect(Transliterate.text('fan', 'kn'), 'ಫ್ಯಾನ್');
      expect(Transliterate.text('neeru', 'kn'), 'ನೀರು');
      expect(Transliterate.text('kannada', 'kn'), 'ಕನ್ನಡ');
    });

    test('common words map to correct Hindi', () {
      expect(Transliterate.text('pankha', 'hi'), 'पंखा');
      expect(Transliterate.text('paani', 'hi'), 'पानी');
      expect(Transliterate.text('nahi', 'hi'), 'नहीं');
    });

    test('rule engine builds syllables for unlisted words', () {
      // consonant + vowel sign, and a cluster taking a virama
      expect(Transliterate.text('ka', 'kn'), 'ಕ');
      expect(Transliterate.text('ki', 'kn'), 'ಕಿ');
      expect(Transliterate.text('kii', 'kn'), 'ಕೀ');
      expect(Transliterate.text('kta', 'kn'), 'ಕ್ತ');
    });

    test('word-initial vowels use the independent form', () {
      expect(Transliterate.text('a', 'kn'), 'ಅ');
      expect(Transliterate.text('aa', 'kn'), 'ಆ');
      expect(Transliterate.text('i', 'hi'), 'इ');
    });

    test('Kannada keeps a word-final virama, Devanagari drops it', () {
      // ಫ್ಯಾನ್ vs काम — the scripts genuinely differ here.
      expect(Transliterate.text('fan', 'kn').endsWith('್'), isTrue);
      expect(Transliterate.text('kaam', 'hi'), 'काम');
    });

    test('digits, punctuation and lone block letters survive', () {
      expect(Transliterate.text('Block C', 'kn'), 'ಬ್ಲಾಕ್ C');
      expect(Transliterate.text('24x7', 'kn'), '24x7');
      expect(Transliterate.text('room 410,', 'kn'), 'ರೂಮ್ 410,');
    });

    test('already-converted script is left alone (idempotent)', () {
      final once = Transliterate.text('fan kelsa madtilla', 'kn');
      expect(Transliterate.text(once, 'kn'), once);
    });

    test('full sentences read correctly', () {
      expect(Transliterate.text('fan kelsa madtilla', 'kn'),
          'ಫ್ಯಾನ್ ಕೆಲಸ ಮಾಡ್ತಿಲ್ಲ');
      expect(Transliterate.text('pankha kaam nahi kar raha hai', 'hi'),
          'पंखा काम नहीं कर रहा है');
    });
  });
}

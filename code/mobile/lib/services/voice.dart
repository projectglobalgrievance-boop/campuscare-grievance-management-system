import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech in and speech out, both handled by the phone itself.
///
/// No API key and no account: this is Android's own `SpeechRecognizer` and
/// text-to-speech engine. A key baked into an APK is extractable by anyone
/// who downloads it, so avoiding one is a security property, not only a cost
/// saving — and there is nothing to expire after the students graduate.
///
/// Everything degrades quietly. A phone with no recogniser or no voice data
/// still gets a fully working typed assistant; the caller checks
/// [canListen] / [canSpeak] and hides the affordance rather than showing a
/// button that does nothing.
class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _ttsReady = false;
  String? _unavailableReason;

  bool get canListen => _sttReady;
  bool get canSpeak => _ttsReady;
  bool get isListening => _stt.isListening;

  /// Why the mic is unavailable, for showing the user something better than
  /// a disabled button with no explanation.
  String? get unavailableReason => _unavailableReason;

  Future<void> init() async {
    try {
      _sttReady = await _stt.initialize(
        onError: (e) => debugPrint('speech error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('speech status: $s'),
      );
      if (!_sttReady) {
        _unavailableReason =
            'Speech recognition is not available on this phone.';
      }
    } catch (e) {
      _sttReady = false;
      _unavailableReason = 'Speech recognition could not start.';
      debugPrint('speech init failed: $e');
    }

    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.48); // the default gabbles on Android
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (e) {
      _ttsReady = false;
      debugPrint('tts init failed: $e');
    }
  }

  /// Listens until the speaker stops, reporting partial text as it goes so
  /// the user can see they are being heard.
  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
  }) async {
    if (!_sttReady) return;
    await _stt.listen(
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        // Left false deliberately: forcing on-device recognition fails
        // outright on phones without the offline language pack, whereas the
        // default uses on-device when present and the system service
        // otherwise. Either way no key of ours is involved.
        onDevice: false,
        cancelOnError: true,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
        localeId: 'en_IN',
      ),
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> speak(String text) async {
    if (!_ttsReady) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    if (_ttsReady) await _tts.stop();
  }

  void dispose() {
    _stt.cancel();
    _tts.stop();
  }
}

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// Offline question answering over a fixed knowledge base.
///
/// No network, no API key, no model. Every answer is text a human wrote in
/// `assets/chatbot/knowledge.json`, so the assistant cannot invent facts about
/// the college — the worst it can do is fail to match and say so. That is the
/// right trade for a bot speaking on behalf of an institution, and it also
/// means there is no key to extract from the shipped APK.
///
/// Matching is IDF-weighted token overlap: rare words like "hostel" or
/// "geofence" carry far more weight than "the" or "is", so a question is
/// answered on its distinctive words rather than its length.
class ChatBot {
  ChatBot._(this._entries, this._idf, this._unknownIdf, this.fallback,
      this.suggestions);

  final List<_Entry> _entries;
  final Map<String, double> _idf;

  /// A word in no entry at all is maximally rare, so it gets the largest
  /// weight the corpus can produce. That is what keeps out-of-scope
  /// questions below the threshold: "write me a python program" is mostly
  /// unknown words, so one incidental hit on "program" cannot carry it.
  final double _unknownIdf;
  final String fallback;
  final List<String> suggestions;

  static const _asset = 'assets/chatbot/knowledge.json';

  /// Below this share of the *recognised* weight of a question, we admit we
  /// don't know instead of returning the least-bad entry.
  static const _threshold = 0.30;

  static ChatBot? _instance;

  /// Loaded once and reused; the knowledge base is small and immutable.
  static Future<ChatBot> load() async {
    if (_instance != null) return _instance!;
    final raw = json.decode(await rootBundle.loadString(_asset))
        as Map<String, dynamic>;
    return _instance = fromJson(raw);
  }

  /// Exposed so tests can build a bot without a Flutter asset bundle.
  static ChatBot fromJson(Map<String, dynamic> raw) {
    final entries = <_Entry>[];
    for (final e in (raw['entries'] as List).cast<Map<String, dynamic>>()) {
      final questions = (e['q'] as List).cast<String>();
      final answer = e['a'] as String;
      entries.add(_Entry(
        id: e['id'] as String,
        topic: e['topic'] as String,
        answer: answer,
        questionTokens: {for (final q in questions) ...tokenize(q)},
        answerTokens: tokenize(answer).toSet(),
        phrases: {for (final q in questions) tokenize(q).join(' ')},
        rawPhrases: {
          for (final q in questions) tokenize(q, keepStopWords: true).join(' ')
        },
        tokenReach: _reach(questions),
        phraseCount: questions.length,
      ));
    }

    // Document frequency across entries, over both fields.
    final df = <String, int>{};
    for (final entry in entries) {
      for (final t in {...entry.questionTokens, ...entry.answerTokens}) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    final n = entries.length;
    final idf = {
      for (final e in df.entries)
        e.key: math.log((n + 1) / (e.value + 0.5)),
    };

    final unknownIdf = math.log((n + 1) / 0.5);
    return ChatBot._(
      entries,
      idf,
      unknownIdf,
      raw['fallback'] as String,
      (raw['suggestions'] as List).cast<String>(),
    );
  }

  static Map<String, int> _reach(List<String> questions) {
    final reach = <String, int>{};
    for (final q in questions) {
      for (final t in tokenize(q).toSet()) {
        reach[t] = (reach[t] ?? 0) + 1;
      }
    }
    return reach;
  }

  /// Words too common to tell entries apart. Deliberately short: over-pruning
  /// hurts more than it helps on questions this brief.
  static const _stop = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'am',
    'do', 'does', 'did', 'to', 'of', 'in', 'on', 'at', 'for', 'and', 'or',
    'it', 'this', 'that', 'there', 'my', 'me', 'i', 'you', 'your', 'we',
    'can', 'could', 'would', 'should', 'will', 'shall', 'may', 'if',
    'what', 'whats', 'how', 'when', 'where', 'which', 'who', 'why',
    'please', 'tell', 'know', 'get', 'got', 'have', 'has', 'had', 'with',
    'about', 'from', 'any', 'some', 'so', 'but', 'not', 'no', 'yes',
    // Fillers that were being counted as real evidence. "by" in particular
    // appears in answer text, so "is gat approved by aicte" looked half
    // recognised when in fact only "gat" was.
    'by', 'as', 'than', 'then', 'also', 'just', 'only', 'very', 'really',
    'here', 'they', 'them', 'their', 'its', 'our', 'us', 'his', 'her', 'he',
    'she', 'these', 'those', 'too', 'much', 'else', 'being', 'own', 'more',
    // Generic adjectives carry no topic. Left in, they counted as words the
    // corpus had never seen, so "how good is the library" looked half
    // unrecognised and was refused despite matching the library entry.
    'good', 'bad', 'best', 'nice', 'great', 'fine', 'okay', 'ok', 'proper',
  };

  static List<String> tokenize(String s, {bool keepStopWords = false}) {
    final cleaned = s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9ऀ-ൿ]+"), ' ');
    return [
      for (final w in cleaned.split(' '))
        if (w.length > 1 && (keepStopWords || !_stop.contains(w))) _stem(w),
    ];
  }

  /// Crude suffix stripping — enough to tie "placements" to "placement",
  /// "hostels" to "hostel" and "started" to "start" without dragging in a
  /// stemming package.
  ///
  /// It strips repeatedly, then drops a trailing 'e'. Both matter: stripping
  /// once left "notifications" at "notification" while "notification" itself
  /// went to "notificat", and stopping before the 'e' left "located" at
  /// "locat" while "location" stayed whole. Either asymmetry means a word the
  /// corpus plainly contains reads as unknown, which is what made ordinary
  /// questions fall through to "I don't know".
  static String _stem(String w) {
    var s = w;
    for (var pass = 0; pass < 4; pass++) {
      var stripped = false;
      for (final suffix in const ['ing', 'ies', 'ion', 'ed', 'es', 's']) {
        if (s.length > suffix.length + 2 && s.endsWith(suffix)) {
          s = suffix == 'ies'
              ? '${s.substring(0, s.length - 3)}y'
              : s.substring(0, s.length - suffix.length);
          stripped = true;
          break;
        }
      }
      if (!stripped) break;
    }
    if (s.length > 3 && s.endsWith('e')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Answers [question], or returns the fallback when nothing matches well.
  ChatAnswer ask(String question) {
    final tokens = tokenize(question);
    final normalised = tokens.join(' ');
    // "what can you do" is every-word-a-stopword, so it normalises to
    // nothing. Fall back to the raw wording and match that against the raw
    // phrasings rather than calling it empty input.
    final raw = tokenize(question, keepStopWords: true).join(' ');
    if (tokens.isEmpty && raw.isNotEmpty) {
      for (final entry in _entries) {
        if (entry.rawPhrases.contains(raw)) {
          return ChatAnswer(entry.answer,
              matchedId: entry.id, confidence: 1, topic: entry.topic);
        }
      }
    }
    if (tokens.isEmpty) {
      return ChatAnswer(fallback, matchedId: null, confidence: 0);
    }

    // Split the question into words the corpus has seen and words it has
    // never seen. Only the first kind can ever match an entry, so only the
    // first kind belongs in the confidence ratio; the second kind is the
    // out-of-scope signal, applied separately below.
    final known = [for (final t in tokens) if (_idf.containsKey(t)) t];

    // Scope gate: more than half the question has to be words the corpus
    // knows. This — not the score — is what keeps out-of-scope questions out.
    // Strictly more than half, because "book me a cab" is two words, one of
    // which ("book") the library entry legitimately owns, and half recognised
    // is not recognised enough to answer on behalf of a college.
    final enoughKnown = known.length * 2 > tokens.length;
    final knownTotal = known.fold<double>(0, (s, t) => s + _idf[t]!);
    if (knownTotal == 0) {
      return ChatAnswer(fallback, matchedId: null, confidence: 0);
    }

    _Entry? best;
    var bestScore = 0.0;
    var bestCentrality = 0.0;
    for (final entry in _entries) {
      var score = 0.0;
      for (final t in known) {
        final weight = _idf[t]!;
        if (entry.questionTokens.contains(t)) {
          score += weight;

        } else if (entry.answerTokens.contains(t)) {
          // The answer text is supporting evidence, not the label. Kept low
          // so a word mentioned in passing cannot outrank the entry that is
          // actually about it.
          score += weight * 0.2;
        }
      }
      // Bag-of-words cannot tell "placements" (the placements entry) from
      // "mba placements" (the MBA entry) — both contain the word. An exact
      // hit on a whole phrasing is far stronger evidence than overlap, so it
      // outranks any partial match.
      if (entry.phrases.contains(normalised)) {
        score += _unknownIdf * tokens.length;
      }

      // Tie-break on how *central* the matched words are to this entry: the
      // share of its phrasings that use them. "hostel" runs through most of
      // the hostel entry's phrasings but only one of the fees entry's, so
      // bare "hostel" lands on the hostel entry. Counting matched tokens
      // instead would just reward entries with fewer phrasings, punishing
      // the well-covered ones.
      var centrality = 0.0;
      if (entry.phraseCount > 0) {
        for (final t in known) {
          centrality += (entry.tokenReach[t] ?? 0) / entry.phraseCount;
        }
      }

      final better = score > bestScore + 1e-9 ||
          ((score - bestScore).abs() <= 1e-9 && centrality > bestCentrality);
      if (better && score > 0) {
        bestScore = score;
        bestCentrality = centrality;
        best = entry;
      }
    }

    final confidence = bestScore / knownTotal;
    if (best == null || !enoughKnown || confidence < _threshold) {
      return ChatAnswer(fallback, matchedId: null, confidence: confidence);
    }
    return ChatAnswer(best.answer,
        matchedId: best.id, confidence: confidence, topic: best.topic);
  }

}

class ChatAnswer {
  const ChatAnswer(this.text,
      {required this.matchedId, required this.confidence, this.topic});

  final String text;

  /// Null when the bot fell back to "I don't know".
  final String? matchedId;
  final double confidence;
  final String? topic;

  bool get matched => matchedId != null;
}

class _Entry {
  _Entry({
    required this.id,
    required this.topic,
    required this.answer,
    required this.questionTokens,
    required this.answerTokens,
    required this.phrases,
    required this.rawPhrases,
    required this.tokenReach,
    required this.phraseCount,
  });

  final String id;
  final String topic;
  final String answer;
  final Set<String> questionTokens;
  final Set<String> answerTokens;

  /// Each phrasing reduced to its normalised token string, for exact match.
  final Set<String> phrases;

  /// The same, keeping stop words, so a question made entirely of them
  /// ("what can you do") can still match exactly.
  final Set<String> rawPhrases;

  /// How many of this entry's phrasings each token appears in.
  final Map<String, int> tokenReach;
  final int phraseCount;
}

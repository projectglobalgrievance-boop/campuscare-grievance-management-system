import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/services/chatbot.dart';

void main() {
  late ChatBot bot;

  setUpAll(() {
    // Read the shipped knowledge base straight off disk so these tests
    // exercise the real content, not a fixture that can drift from it.
    final raw = json.decode(
            File('assets/chatbot/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    bot = ChatBot.fromJson(raw);
  });

  group('answers questions it should know', () {
    // Phrased the way a student would, not the way the entries are written.
    const cases = {
      'how do i report a broken fan': 'app-report',
      'will the admin know my name': 'app-privacy',
      'can i type in kannada': 'app-language',
      'it says i am outside campus': 'app-geofence',
      'where can i see my complaint status': 'app-track',
      'how many complaints per day': 'app-limit',
      'what branches can i study': 'gat-ug-programs',
      'does the college have a hostel': 'gat-hostel',
      'how many books in the library': 'gat-library',
      'what is the phone number': 'gat-contact',
      'which entrance exam do i need': 'gat-entrance',
      'who is the principal': 'gat-principal',
      'when was the college started': 'gat-established',
      'tell me about placements': 'gat-placements',
    };

    cases.forEach((question, expectedId) {
      test('"$question" -> $expectedId', () {
        final a = bot.ask(question);
        expect(a.matched, isTrue, reason: 'fell back on "$question"');
        expect(a.matchedId, expectedId);
      });
    });
  });

  group('refuses what is out of scope', () {
    // The whole point of the fixed knowledge base: it must not bluff.
    const outOfScope = [
      'what is the weather tomorrow',
      'write me a python program',
      'who won the cricket match',
      'what is the capital of france',
      'tell me a joke',
    ];

    for (final q in outOfScope) {
      test('"$q" falls back', () {
        final a = bot.ask(q);
        expect(a.matched, isFalse,
            reason: 'answered "$q" with ${a.matchedId} — it should decline');
      });
    }
  });

  test('empty and punctuation-only input falls back cleanly', () {
    for (final q in ['', '   ', '???', '...']) {
      final a = bot.ask(q);
      expect(a.matched, isFalse);
      expect(a.text, bot.fallback);
    }
  });

  test('knowledge base is well formed', () {
    final raw = json.decode(
            File('assets/chatbot/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    final entries = (raw['entries'] as List).cast<Map<String, dynamic>>();

    expect(entries.length, greaterThanOrEqualTo(40));
    expect(raw['suggestions'], isNotEmpty);
    expect((raw['fallback'] as String).length, greaterThan(40));

    final ids = <String>{};
    for (final e in entries) {
      expect(ids.add(e['id'] as String), isTrue,
          reason: 'duplicate id ${e['id']}');
      expect(e['topic'], anyOf('college', 'app'));
      expect((e['q'] as List), isNotEmpty);
      expect((e['a'] as String).trim(), isNotEmpty);
    }

    // Both halves of the promised scope are actually covered.
    final topics = entries.map((e) => e['topic']).toSet();
    expect(topics, containsAll(<String>['college', 'app']));
  });

  test('every entry is reachable by its own first phrasing', () {
    // Guards against an entry being permanently shadowed by another.
    final raw = json.decode(
            File('assets/chatbot/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    final entries = (raw['entries'] as List).cast<Map<String, dynamic>>();

    final unreachable = <String>[];
    for (final e in entries) {
      final probe = (e['q'] as List).first as String;
      if (bot.ask(probe).matchedId != e['id']) {
        unreachable.add('${e['id']} (probe: "$probe" -> '
            '${bot.ask(probe).matchedId})');
      }
    }
    expect(unreachable, isEmpty);
  });
}

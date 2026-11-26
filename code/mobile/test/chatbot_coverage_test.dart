// Coverage net for the assistant's matcher.
//
// The bot's whole value is that it answers college and app questions and
// refuses everything else. Both halves are easy to break with a single stray
// phrasing: a generic word like "use" or "good" added to one entry quietly
// hijacks questions meant for another, and a stray unknown word used to be
// enough to refuse a question the corpus plainly answers. So both halves are
// pinned here, against the real shipped knowledge file.
//
// Each question maps to the entry ids that count as a right answer.
// 'FALLBACK' means the honest "I don't know" is the correct outcome.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/services/chatbot.dart';

const cases = <String, List<String>>{
  // ---- natural phrasings ----
  // --- college -------------------------------------------------------
  'what is the fee for the hostel per year': ['gat-fees', 'gat-hostel'],
  'does gat have a hostel for girls': ['gat-hostel'],
  'tell me about the placement record of the college': ['gat-placements'],
  'what is the highest package offered in gat': ['gat-placements'],
  'which companies come for placement': ['gat-placements'],
  'is gat a good college for computer science': [
    'gat-ug-programs', 'gat-about', 'gat-accreditation'
  ],
  'how many seats are there in information science': [
    'FALLBACK', 'gat-ug-programs'
  ],
  'what is the last date to apply for admission': ['gat-admission-apply'],
  'can i get admission through comedk': ['gat-entrance'],
  'where exactly is the college located': ['gat-contact'],
  'what is the phone number of the college office': ['gat-contact'],
  'how do i reach the campus': ['gat-contact'],
  'is gat approved by aicte': ['FALLBACK', 'gat-accreditation'],
  'does the college have wifi': ['FALLBACK', 'gat-campus-life', 'gat-hostel'],
  'what facilities are available in the library': ['gat-library'],
  'who is the principal of gat': ['gat-principal'],
  'how many years is the be course': ['gat-duration'],
  'can i do mtech after be here': ['gat-pg-programs', 'gat-pg-eligibility'],
  'are there any scholarships for meritorious students': ['gat-scholarship'],
  'when was the college started': ['gat-established'],
  'what sports can i play here': ['gat-sports'],
  'is gat affiliated to vtu': ['gat-accreditation'],
  'what clubs are there in college': ['gat-campus-life'],
  'tell me the vision of gat': ['gat-vision'],

  // --- the app -------------------------------------------------------
  'how do i raise a complaint in this app': ['app-report'],
  'why is my submit button not working': ['app-geofence', 'app-report'],
  'can i complain about a broken bench in the canteen': ['app-report'],
  'will anyone know that i reported the issue': ['app-privacy'],
  'how long does it take to resolve a complaint': [
    'app-statuses', 'app-track', 'FALLBACK'
  ],
  'can i upload a photo from my gallery': ['app-photo-required'],
  'i am outside the college can i still report': ['app-geofence'],
  'how do i check the status of my complaint': ['app-track'],
  'can i write my complaint in kannada': ['app-language'],
  'what happens if i submit the same problem twice': ['app-duplicate'],
  'how many complaints can i file in one day': ['app-limit'],
  'my complaint was rejected what do i do': ['app-rejected'],
  'can i cancel a complaint after submitting': ['app-edit-cancel'],
  'it is still broken after they closed it': ['app-reopen'],
  'do i need internet to use the app': ['app-offline'],
  'can i reply to the admin': ['app-comments'],
  'how do i create an account': ['app-account'],
  'what is campuscare': ['app-what-is'],
  'will i get a notification when it is fixed': ['app-notifications'],
  'who actually fixes the problem': ['app-who-sees'],
  'what can you do': ['bot-scope'],

  'what are the fees for be': ['gat-fees'],
  'is there a girls hostel': ['gat-hostel'],
  'what documents are needed for admission': ['gat-admission-apply', 'FALLBACK'],

  // --- must stay refused ---------------------------------------------
  'who won the cricket world cup': ['FALLBACK'],
  'write me a python program': ['FALLBACK'],
  'what is the capital of france': ['FALLBACK'],
  'tell me a joke': ['FALLBACK'],
  'how do i cook biryani': ['FALLBACK'],
  'what is the weather today': ['FALLBACK'],
  'who is the prime minister of india': ['FALLBACK'],
  'solve 2x plus 5 equals 15': ['FALLBACK'],

  // ---- unseen phrasings ----
  // college, unseen phrasings
  'which university is gat affiliated with': ['gat-accreditation'],
  'do you have a canteen or mess': ['gat-campus-life', 'gat-hostel', 'FALLBACK'],
  'what is the admission procedure for be': ['gat-admission-apply', 'gat-ug-eligibility'],
  'tell me the email id of the college': ['gat-contact'],
  'how good is the library': ['gat-library'],
  'do you offer artificial intelligence branch': ['gat-ug-programs'],
  'what is the eligibility criteria for mtech': ['gat-pg-eligibility'],
  'can students from kerala join gat': ['gat-other-states'],
  'i want to join in second year directly': ['gat-lateral'],
  'is there any fee concession': ['gat-scholarship', 'gat-fees'],
  'what does gat stand for': ['gat-about'],
  'which companies recruit from gat': ['gat-placements'],
  'what after mba': ['gat-mba-career'],
  'how long is the mtech course': ['gat-duration', 'gat-pg-programs'],
  'kcet cutoff': ['gat-entrance', 'FALLBACK'],

  // app, unseen phrasings
  'the tap in the washroom is leaking': ['app-report'],
  'someone should clean the classroom': ['app-report'],
  'is my identity hidden from staff': ['app-privacy'],
  'do i have to take the picture myself': ['app-photo-required'],
  'app says i am not inside campus': ['app-geofence'],
  'i want to change what i wrote': ['app-edit-cancel'],
  'how do i give a rating': ['app-feedback'],
  'why is my complaint marked critical': ['app-priority'],
  'someone already reported this same issue': ['app-duplicate'],
  'i typed in hindi will it work': ['app-language'],
  'my photo is not visible': ['app-photo-missing'],
  'which zone should i pick': ['app-zones'],
  'do i get alerts': ['app-notifications'],
  'i forgot my password': ['app-account', 'FALLBACK'],

  // out of scope, including words the corpus knows
  'how do i report a bug in whatsapp': ['FALLBACK', 'app-report'],
  'what is the fee for iit bombay': ['FALLBACK', 'gat-fees'],
  'write a complaint letter to the bank': ['FALLBACK'],
  'who is the president of india': ['FALLBACK'],
  'best restaurants near me': ['FALLBACK'],
  'explain quantum physics': ['FALLBACK'],
  'convert 100 usd to rupees': ['FALLBACK'],
  'sing me a song': ['FALLBACK'],

  // ---- written after tuning, never used to adjust anything ----
  'is gat autonomous or affiliated': ['gat-accreditation'],
  'what are the timings of the library': ['gat-library', 'FALLBACK'],
  'do you have an aeronautical branch': ['gat-ug-programs'],
  'i am from andhra can i apply': ['gat-other-states'],
  'diploma holders direct second year': ['gat-lateral'],
  'give me the admission office number': ['gat-contact'],
  'what is the motto of the institution': ['gat-vision', 'gat-about'],
  'in which year did gat open': ['gat-established'],
  'are there cultural fests': ['gat-campus-life'],
  'what is the duration of mba': ['gat-duration', 'gat-pg-programs'],
  'do i need kcet rank': ['gat-entrance'],
  'any fee waiver for toppers': ['gat-scholarship', 'gat-fees'],
  'boys hostel available or not': ['gat-hostel'],
  'name of the head of the institution': ['gat-principal'],
  'which sports ground do you have': ['gat-sports'],
  'average salary after placement': ['gat-placements'],
  'what jobs after mba': ['gat-mba-career'],
  'minimum marks for be admission': ['gat-ug-eligibility'],

  'the fan in my classroom is not working': ['app-report'],
  'garbage is not being collected': ['app-report'],
  'can the admin find out my name': ['app-privacy'],
  'must the photo be taken now': ['app-photo-required'],
  'it refuses to let me submit from home': ['app-geofence'],
  'where do i see updates on my complaint': ['app-track'],
  'what does in progress mean': ['app-statuses'],
  'they turned down my complaint': ['app-rejected'],
  'how does it decide what is urgent': ['app-priority'],
  'i made a mistake in my complaint': ['app-edit-cancel'],
  'the issue is back again': ['app-reopen'],
  'how do i rate the resolution': ['app-feedback'],
  'is there a daily limit': ['app-limit'],
  'can i type in my own language': ['app-language'],
  'works without network': ['app-offline'],
  'can i send a message to the department': ['app-comments'],
  'someone else reported this already': ['app-duplicate'],
  'will my phone buzz when it updates': ['app-notifications'],
  'i need to register': ['app-account'],
  'which area do i choose': ['app-zones'],
  'what is this app for': ['app-what-is', 'bot-scope'],

  'who invented the telephone': ['FALLBACK'],
  'what is 15 percent of 200': ['FALLBACK'],
  'recommend a movie': ['FALLBACK'],
  'how to lose weight fast': ['FALLBACK'],
  'latest cricket score': ['FALLBACK'],
  'write an essay on global warming': ['FALLBACK'],
  'book me a cab': ['FALLBACK'],
  'what is the population of bengaluru': ['FALLBACK'],
};

void main() {
  late ChatBot bot;

  setUpAll(() {
    final raw = json
            .decode(File('assets/chatbot/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    bot = ChatBot.fromJson(raw);
  });

  test('every question lands on an acceptable answer', () {
    final misses = <String>[];
    cases.forEach((q, want) {
      final got = bot.ask(q).matchedId ?? 'FALLBACK';
      if (!want.contains(got)) {
        misses.add('  "$q" -> $got (wanted ${want.join(" or ")})');
      }
    });
    expect(misses, isEmpty,
        reason: 'matcher regressed on:\n${misses.join("\n")}');
  });

  test('nothing out of scope is ever answered', () {
    final leaked = <String>[];
    cases.forEach((q, want) {
      if (want.length == 1 && want.first == 'FALLBACK') {
        final a = bot.ask(q);
        if (a.matched) leaked.add('  "$q" -> ${a.matchedId}');
      }
    });
    expect(leaked, isEmpty,
        reason: 'answered questions it should have refused:\n'
            '${leaked.join("\n")}');
  });

  test('no phrasing is claimed by two entries', () {
    final raw = json
            .decode(File('assets/chatbot/knowledge.json').readAsStringSync())
        as Map<String, dynamic>;
    final owner = <String, String>{};
    final clashes = <String>[];
    for (final e in (raw['entries'] as List).cast<Map<String, dynamic>>()) {
      for (final q in (e['q'] as List).cast<String>()) {
        final key = q.toLowerCase().trim();
        if (owner.containsKey(key)) {
          clashes.add('  "$q" on ${owner[key]} and ${e['id']}');
        }
        owner[key] = e['id'] as String;
      }
    }
    expect(clashes, isEmpty, reason: 'ambiguous phrasings:\n${clashes.join("\n")}');
  });
}

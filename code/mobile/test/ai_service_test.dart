import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/services/ai_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<Map<String, dynamic>?> _run(MockClient client) => AiService(client)
    .analyze(
      complaintId: 'c1',
      description: 'Water leaking near the canteen',
      lat: 12.92665,
      lng: 77.52640,
      capturedAt: DateTime.utc(2026, 8, 16),
    );

void main() {
  test('retries transient non-200 responses instead of giving up', () async {
    var calls = 0;
    final result = await _run(MockClient((_) async {
      calls++;
      // Render's edge returns these while an instance wakes or redeploys.
      if (calls < 3) return http.Response('Not Found', 404);
      return http.Response(jsonEncode({'aliasName': 'Golden Stapler'}), 200);
    }));
    expect(calls, 3);
    expect(result?['aliasName'], 'Golden Stapler');
  });

  test('outside_campus is surfaced, not retried', () async {
    var calls = 0;
    expect(
      () => _run(MockClient((_) async {
        calls++;
        return http.Response(
            jsonEncode({
              'detail': {'code': 'outside_campus', 'message': 'nope'}
            }),
            422);
      })),
      throwsA(isA<AiAnalysisException>()),
    );
    await Future.delayed(Duration.zero);
    expect(calls, 1);
  });

  test('gives up after the attempt budget and returns null', () async {
    var calls = 0;
    final result = await _run(MockClient((_) async {
      calls++;
      return http.Response('boom', 503);
    }));
    expect(calls, 3);
    expect(result, isNull);
  });
}

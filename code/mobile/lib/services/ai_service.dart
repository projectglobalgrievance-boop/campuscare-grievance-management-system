import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AiAnalysisException implements Exception {
  final String code;
  final String message;
  AiAnalysisException(this.code, this.message);
}

class AiService {
  final http.Client _client;
  AiService([http.Client? client]) : _client = client ?? http.Client();

  Uri get _analyzeUri => Uri.parse('${AppConfig.aiServiceUrl}/analyze');

  /// Calls the AI service. Returns the enrichment map, or null when the
  /// service is unreachable (complaint stays 'submitted'; a retry worker or
  /// the service's Firestore write-back finishes the job later).
  Future<Map<String, dynamic>?> analyze({
    required String complaintId,
    required String description,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    bool bypassGeofence = false,
    String? department,
  }) async {
    // A free-plan Render instance sleeps after ~15 min idle and holds the
    // first request open for 30-60 s while it wakes, so one attempt must be
    // allowed to run longer than that. The deadline caps the whole thing so
    // the "Analyzing with AI…" spinner can't hang forever.
    const attempts = 3;
    final deadline = DateTime.now().add(const Duration(seconds: 75));
    for (var i = 0; i < attempts; i++) {
      try {
        final resp = await _client
            .post(
              _analyzeUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'complaintId': complaintId,
                'description': description,
                'lat': lat,
                'lng': lng,
                'capturedAt': capturedAt.toUtc().toIso8601String(),
                'bypassGeofence': bypassGeofence,
                if (department != null) 'department': department,
              }),
            )
            .timeout(const Duration(seconds: 45));
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
        if (resp.statusCode == 422) {
          final detail =
              (jsonDecode(resp.body) as Map<String, dynamic>)['detail'];
          if (detail is Map && detail['code'] == 'outside_campus') {
            throw AiAnalysisException(
                'outside_campus', detail['message'] as String? ?? '');
          }
          return null;
        }
        // Any other status (502/503/504 while waking, 404 from the edge
        // during a redeploy) is transient — fall through to the backoff.
      } on AiAnalysisException {
        rethrow;
      } catch (_) {
        // network hiccup — fall through to the backoff
      }
      if (DateTime.now().isAfter(deadline)) break;
      await Future.delayed(Duration(seconds: i + 1));
    }
    // ponytail: complaint stays unenriched (status 'submitted', ai: null).
    // Add a background retry worker if this shows up in practice.
    return null;
  }
}

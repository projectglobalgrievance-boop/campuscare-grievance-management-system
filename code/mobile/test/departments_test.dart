import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/config/departments.dart';
import 'package:grievance_app/services/ai_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // The app, the AI service and firestore.rules each list the departments;
  // a department missing from any one of them silently loses its complaints.
  test('departments match the AI service and the security rules', () {
    final py = File('../ai-service/app/categories.py').readAsStringSync();
    final rules = File('../firebase/firestore.rules').readAsStringSync();
    for (final d in Department.all) {
      expect(py, contains('"${d.category}": "${d.id}"'), reason: d.id);
      expect(py, contains('"${d.id}": "${d.name}"'), reason: d.id);
      expect(rules, contains("'${d.id}'"), reason: d.id);
    }
    expect(Department.all.map((d) => d.id).toSet().length, 7);
  });

  test('unknown department ids read as Unassigned', () {
    expect(Department.nameOf('housekeeping'), 'Facilities');
    expect(Department.nameOf(null), 'Unassigned');
    expect(Department.nameOf('nope'), 'Unassigned');
  });

  test('the chosen department is sent to the AI service', () async {
    Map<String, dynamic>? body;
    await AiService(MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{}', 200);
    })).analyze(
      complaintId: 'c1',
      description: 'fan broken',
      lat: 12.92665,
      lng: 77.52640,
      capturedAt: DateTime.utc(2026, 9, 29),
      department: 'electrical_maintenance',
    );
    expect(body?['department'], 'electrical_maintenance');
  });
}

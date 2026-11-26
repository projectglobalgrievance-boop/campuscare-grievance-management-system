import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/models/complaint.dart';
import 'package:grievance_app/screens/admin/admin_queue_screen.dart';

Complaint make({
  String id = 'x',
  String category = 'Cleanliness',
  String zone = 'Canteen',
  String priority = 'High',
  String status = 'submitted',
  int daysAgo = 0,
}) {
  final at = DateTime(2026, 8, 4).subtract(Duration(days: daysAgo));
  return Complaint(
    id: id,
    aliasName: 'Turbo Idli',
    studentUid: 'u1',
    description: 'test',
    photoUrl: null,
    location: ComplaintLocation(
        lat: 12.899, lng: 77.512, accuracy: 10, zoneName: zone),
    capturedAt: at,
    submittedAt: at,
    ai: AiResult(
      category: category,
      sentiment: 'calm',
      priority: priority,
      department: 'housekeeping',
      departmentName: 'Housekeeping',
      tagline: 'In the $zone area, an issue was reported. Please look into it!',
    ),
    status: status,
    statusHistory: const [],
  );
}

void main() {
  final now = DateTime(2026, 8, 4);
  final items = [
    make(id: 'a', category: 'Cleanliness', zone: 'Canteen', priority: 'High'),
    make(id: 'b', category: 'Electrical', zone: 'Block A', priority: 'Critical'),
    make(id: 'c', category: 'Cleanliness', zone: 'Hostel', status: 'resolved'),
    make(id: 'd', category: 'Plumbing', zone: 'Canteen', daysAgo: 45),
  ];

  group('admin queue filters', () {
    test('no filters returns everything', () {
      expect(AdminQueueScreenState.applyFilters(items, now: now).length, 4);
    });

    test('category filter', () {
      final r = AdminQueueScreenState.applyFilters(items,
          category: 'Cleanliness', now: now);
      expect(r.map((c) => c.id), ['a', 'c']);
    });

    test('zone + category combine (AND)', () {
      final r = AdminQueueScreenState.applyFilters(items,
          category: 'Cleanliness', zone: 'Canteen', now: now);
      expect(r.map((c) => c.id), ['a']);
    });

    test('priority filter', () {
      final r = AdminQueueScreenState.applyFilters(items,
          priority: 'Critical', now: now);
      expect(r.single.id, 'b');
    });

    test('status filter', () {
      final r = AdminQueueScreenState.applyFilters(items,
          status: 'resolved', now: now);
      expect(r.single.id, 'c');
    });

    test('date window drops stale complaints', () {
      final r =
          AdminQueueScreenState.applyFilters(items, lastDays: 30, now: now);
      expect(r.map((c) => c.id), isNot(contains('d')));
    });

    test('text search matches zone, alias and tagline (case-insensitive)', () {
      expect(
          AdminQueueScreenState.applyFilters(items, query: 'hostel', now: now)
              .single
              .id,
          'c');
      expect(
          AdminQueueScreenState.applyFilters(items,
              query: 'turbo idli', now: now).length,
          4);
      expect(
          AdminQueueScreenState.applyFilters(items,
              query: 'no-such-thing', now: now),
          isEmpty);
    });

    test('search combines with other filters', () {
      final r = AdminQueueScreenState.applyFilters(items,
          query: 'canteen', category: 'Plumbing', now: now);
      expect(r.single.id, 'd');
    });
  });
}

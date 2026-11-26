import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/models/complaint.dart';
import 'package:grievance_app/widgets/badges.dart';
import 'package:grievance_app/widgets/complaint_card.dart';
import 'package:grievance_app/widgets/feedback_states.dart';
import 'package:grievance_app/widgets/status_timeline.dart';

Complaint _complaint({String status = 'submitted'}) => Complaint(
      id: 'c1',
      aliasName: 'Captain Samosa',
      studentUid: 'u1',
      description: 'dustbin overflowing near canteen',
      photoUrl: null,
      location: const ComplaintLocation(
          lat: 12.899, lng: 77.512, accuracy: 8, zoneName: 'Canteen'),
      capturedAt: DateTime(2026, 8, 4, 10),
      submittedAt: DateTime(2026, 8, 4, 10),
      ai: const AiResult(
        category: 'Cleanliness',
        sentiment: 'annoyed',
        priority: 'High',
        department: 'housekeeping',
        departmentName: 'Housekeeping',
        tagline:
            'In the Canteen area, a dustbin is overflowing. Please clean up this mess!',
      ),
      status: status,
      statusHistory: [
        StatusEntry(
            status: 'submitted',
            byRole: 'student',
            at: DateTime(2026, 8, 4, 10)),
        StatusEntry(
            status: 'assigned',
            byRole: 'admin',
            at: DateTime(2026, 8, 4, 14),
            note: 'Sent to housekeeping'),
      ],
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('admin card shows alias and tagline, never a real name',
      (tester) async {
    await tester.pumpWidget(_wrap(ComplaintCard(
        complaint: _complaint(), adminView: true, onTap: () {})));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Captain Samosa'), findsOneWidget);
    expect(find.textContaining('dustbin is overflowing'), findsOneWidget);
    expect(find.textContaining('You'), findsNothing);
  });

  testWidgets('student card shows You instead of the alias', (tester) async {
    await tester.pumpWidget(_wrap(ComplaintCard(
        complaint: _complaint(), adminView: false, onTap: () {})));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('You ·'), findsOneWidget);
    expect(find.textContaining('Captain Samosa'), findsNothing);
  });

  testWidgets('status timeline renders every history entry with notes',
      (tester) async {
    await tester.pumpWidget(
        _wrap(StatusTimeline(history: _complaint().statusHistory)));
    await tester.pumpAndSettle();

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Sent to housekeeping'), findsOneWidget);
  });

  testWidgets('priority chip and status badge use semantic labels',
      (tester) async {
    await tester.pumpWidget(_wrap(const Row(
        children: [PriorityChip('Critical'), StatusBadge('in_progress')])));
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('empty state shows title, message and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.inbox_rounded,
      title: 'Nothing here',
      message: 'Come back later.',
      action: FilledButton(
          onPressed: () => tapped = true, child: const Text('Do it')),
    )));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Nothing here'), findsOneWidget);
    await tester.tap(find.text('Do it'));
    expect(tapped, isTrue);
  });
}

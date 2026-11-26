import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/departments.dart';

class ComplaintLocation {
  final double lat;
  final double lng;
  final double accuracy;
  final String zoneName;

  const ComplaintLocation({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.zoneName,
  });

  Map<String, dynamic> toMap() =>
      {'lat': lat, 'lng': lng, 'accuracy': accuracy, 'zoneName': zoneName};

  factory ComplaintLocation.fromMap(Map<String, dynamic>? m) =>
      ComplaintLocation(
        lat: ((m?['lat'] ?? 0) as num).toDouble(),
        lng: ((m?['lng'] ?? 0) as num).toDouble(),
        accuracy: ((m?['accuracy'] ?? 0) as num).toDouble(),
        zoneName: (m?['zoneName'] ?? 'Campus') as String,
      );
}

class AiResult {
  final String category;
  final String sentiment;
  final String priority;
  final String department;
  final String departmentName;
  final String tagline;
  final String? duplicateOf;
  final bool flagged; // profanity screen hit — admin-visible only

  /// The model's own reading of the text. Differs from [category] when the
  /// student picked a department the model would not have — a hint for the
  /// admin, not a verdict. null on complaints analysed before the picker.
  final String? predictedCategory;

  const AiResult({
    required this.category,
    required this.sentiment,
    required this.priority,
    required this.department,
    required this.departmentName,
    required this.tagline,
    this.duplicateOf,
    this.flagged = false,
    this.predictedCategory,
  });

  factory AiResult.fromMap(Map<String, dynamic> m) => AiResult(
        category: (m['category'] ?? 'Other') as String,
        sentiment: (m['sentiment'] ?? 'calm') as String,
        priority: (m['priority'] ?? 'Low') as String,
        department: (m['department'] ?? 'general_administration') as String,
        departmentName:
            (m['departmentName'] ?? 'General Administration') as String,
        tagline: (m['tagline'] ?? '') as String,
        duplicateOf: m['duplicateOf'] as String?,
        flagged: (m['flagged'] ?? false) as bool,
        predictedCategory: m['predictedCategory'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'category': category,
        'sentiment': sentiment,
        'priority': priority,
        'department': department,
        'departmentName': departmentName,
        'tagline': tagline,
        'duplicateOf': duplicateOf,
        'flagged': flagged,
        'predictedCategory': predictedCategory,
      };
}

class ComplaintComment {
  final String id;
  final String byRole; // 'student' | 'admin'
  final String text;
  final DateTime at;

  const ComplaintComment(
      {required this.id, required this.byRole, required this.text,
       required this.at});

  factory ComplaintComment.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      ComplaintComment(
        id: doc.id,
        byRole: (doc.data()?['byRole'] ?? 'student') as String,
        text: (doc.data()?['text'] ?? '') as String,
        at: _toDate(doc.data()?['at']),
      );
}

class StatusEntry {
  final String status;
  final String byRole;
  final DateTime at;
  final String? note;

  const StatusEntry(
      {required this.status, required this.byRole, required this.at, this.note});

  factory StatusEntry.fromMap(Map<String, dynamic> m) => StatusEntry(
        status: (m['status'] ?? 'submitted') as String,
        byRole: (m['byRole'] ?? 'student') as String,
        at: _toDate(m['at']),
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap() =>
      {'status': status, 'byRole': byRole, 'at': at, 'note': note};
}

class ComplaintFeedback {
  final int rating;
  final String? comment;

  const ComplaintFeedback({required this.rating, this.comment});

  factory ComplaintFeedback.fromMap(Map<String, dynamic> m) => ComplaintFeedback(
      rating: (m['rating'] ?? 0) as int, comment: m['comment'] as String?);
}

class Complaint {
  final String id;
  final String aliasName;
  final String? studentUid;
  final String description;
  final String? photoUrl;
  final List<String> photoUrls; // all photos; photoUrl stays = first
  final bool escalated; // SLA sweep bumped this one

  /// Department id the student picked (older complaints: set by the AI).
  final String? department;

  /// Photo proofs stored in the `photos` subcollection.
  final int photoCount;
  final ComplaintLocation location;
  final DateTime capturedAt;
  final DateTime submittedAt;
  final AiResult? ai;
  final String status;
  final List<StatusEntry> statusHistory;
  final ComplaintFeedback? feedback;

  const Complaint({
    required this.id,
    required this.aliasName,
    required this.studentUid,
    required this.description,
    required this.photoUrl,
    this.photoUrls = const [],
    this.escalated = false,
    this.department,
    this.photoCount = 0,
    required this.location,
    required this.capturedAt,
    required this.submittedAt,
    required this.ai,
    required this.status,
    required this.statusHistory,
    this.feedback,
  });

  bool get isOpen =>
      status == 'submitted' || status == 'assigned' || status == 'in_progress';

  /// Where this complaint is routed, whichever source set it.
  String? get deptId => department ?? ai?.department;
  String get deptName => Department.nameOf(deptId);

  /// Every photo, oldest first — tolerates docs that predate `photoUrls`.
  List<String> get allPhotos => photoUrls.isNotEmpty
      ? photoUrls
      : [if (photoUrl != null) photoUrl!];

  factory Complaint.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Complaint(
      id: doc.id,
      aliasName: (d['aliasName'] ?? 'Anonymous Sparrow') as String,
      studentUid: d['studentUid'] as String?,
      description: (d['description'] ?? '') as String,
      photoUrl: d['photoUrl'] as String?,
      photoUrls: ((d['photoUrls'] ?? []) as List).cast<String>(),
      escalated: (d['escalated'] ?? false) as bool,
      department: d['department'] as String?,
      photoCount: ((d['photoCount'] ?? 0) as num).toInt(),
      location:
          ComplaintLocation.fromMap(d['location'] as Map<String, dynamic>?),
      capturedAt: _toDate(d['capturedAt']),
      submittedAt: _toDate(d['submittedAt']),
      ai: d['ai'] == null
          ? null
          : AiResult.fromMap(Map<String, dynamic>.from(d['ai'] as Map)),
      status: (d['status'] ?? 'submitted') as String,
      statusHistory: ((d['statusHistory'] ?? []) as List)
          .map((e) => StatusEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      feedback: d['feedback'] == null
          ? null
          : ComplaintFeedback.fromMap(Map<String, dynamic>.from(d['feedback'] as Map)),
    );
  }
}

String statusLabel(String status) => switch (status) {
      'submitted' => 'Submitted',
      'assigned' => 'Assigned',
      'in_progress' => 'In Progress',
      'resolved' => 'Resolved',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      _ => status,
    };

DateTime _toDate(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return DateTime.now();
}

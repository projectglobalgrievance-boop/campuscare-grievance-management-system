import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String collegeEmail;
  final String role; // 'student' | 'admin'
  final String dept;

  /// Demo/test account: geofence is bypassed so the flow can be shown from
  /// anywhere. Set by the seed only — clients can never grant it (rules).
  final bool demoTester;

  /// For admins only: department id this admin is scoped to (null = all).
  /// Set by seed/make_admin.py; mirrored in the auth token's `dept` claim.
  final String? adminDept;

  const AppUser({
    required this.uid,
    required this.name,
    required this.collegeEmail,
    required this.role,
    required this.dept,
    this.demoTester = false,
    this.adminDept,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (d['name'] ?? '') as String,
      collegeEmail: (d['collegeEmail'] ?? '') as String,
      role: (d['role'] ?? 'student') as String,
      dept: (d['dept'] ?? '') as String,
      demoTester: (d['demoTester'] ?? false) as bool,
      adminDept: d['adminDept'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'collegeEmail': collegeEmail,
        'role': role,
        'dept': dept,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// One entry in the admin's "new registrations" feed. Keyed by email and
/// deliberately without the uid, so it cannot be matched to a complaint.
class Registration {
  final String email;
  final String name;
  final String role;
  final String dept;
  final DateTime createdAt;
  final bool seen;

  const Registration({
    required this.email,
    required this.name,
    required this.role,
    required this.dept,
    required this.createdAt,
    required this.seen,
  });

  factory Registration.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final at = d['createdAt'];
    return Registration(
      email: doc.id,
      name: (d['name'] ?? '') as String,
      role: (d['role'] ?? 'student') as String,
      dept: (d['dept'] ?? '') as String,
      // A just-written serverTimestamp reads back as null for a moment.
      createdAt: at is Timestamp ? at.toDate() : DateTime.now(),
      seen: (d['seen'] ?? false) as bool,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> profileStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  /// Roles a campus member can pick at signup. Admin is deliberately absent —
  /// it is granted server-side only (custom claim via seed/Admin SDK).
  static const selfServiceRoles = ['student', 'faculty', 'staff'];

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String dept,
    String role = 'student',
  }) async {
    final domain = AppConfig.allowedDomain;
    if (domain != null && !email.toLowerCase().endsWith('@$domain')) {
      return 'Please use your @$domain college email.';
    }
    if (!selfServiceRoles.contains(role)) return 'Pick a valid role.';
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = AppUser(
        uid: cred.user!.uid,
        name: name.trim(),
        collegeEmail: email.trim(),
        role: role,
        dept: dept.trim(),
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      // Tell the admin someone joined. Best-effort: the account is already
      // made, and a missed notice must never turn into a failed signup.
      final regEmail = cred.user!.email ?? email.trim();
      try {
        await _db.collection('registrations').doc(regEmail).set({
          'name': user.name,
          'email': regEmail,
          'role': role,
          'dept': user.dept,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      } catch (_) {
        // ignore: avoid_print
        print('CampusCare: registration notice failed');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'email-already-in-use' =>
          'This email is already registered — try logging in instead.',
        'weak-password' => 'Password is too weak — use at least 6 characters.',
        'invalid-email' => 'That email address doesn\'t look right.',
        _ => 'Could not create the account (${e.code}). Please try again.',
      };
    }
  }

  // ---------- admin: new registrations (college-wide admin only) ----------

  Stream<List<Registration>> registrations({int limit = 200}) => _db
      .collection('registrations')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Registration.fromDoc).toList());

  Stream<int> unseenRegistrationCount() => _db
      .collection('registrations')
      .where('seen', isEqualTo: false)
      .snapshots()
      .map((s) => s.size);

  Future<void> markRegistrationSeen(String email) => _db
      .collection('registrations')
      .doc(email)
      .update({'seen': true});

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Email or password is incorrect.',
        'invalid-email' => 'That email address doesn\'t look right.',
        'too-many-requests' =>
          'Too many attempts — wait a moment and try again.',
        _ => 'Could not sign in (${e.code}). Please try again.',
      };
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code == 'user-not-found'
          ? 'No account found for that email.'
          : 'Could not send reset email (${e.code}).';
    }
  }

  Future<void> signOut() => _auth.signOut();
}

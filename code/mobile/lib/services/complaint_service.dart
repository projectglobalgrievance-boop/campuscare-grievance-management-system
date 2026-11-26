import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/app_config.dart';
import '../models/complaint.dart';
import 'ai_service.dart';

class ComplaintService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _ai = AiService();

  CollectionReference<Map<String, dynamic>> get _complaints =>
      _db.collection('complaints');

  // ---------- student ----------

  Stream<List<Complaint>> myComplaints(String uid) => _complaints
      .where('studentUid', isEqualTo: uid)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Complaint.fromDoc).toList());

  Stream<Complaint?> watch(String id) => _complaints
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Complaint.fromDoc(d) : null);

  /// Complaints this user submitted since local midnight (spam guard).
  Future<int> todaysComplaintCount(String uid) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final agg = await _complaints
        .where('studentUid', isEqualTo: uid)
        .where('submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Firestore caps a document at 1 MiB; the rules allow a proof up to this.
  static const maxProofBytes = 900 * 1024;

  /// A photo ready to store in Firestore, or null if it cannot be made small
  /// enough. The camera shoots at ResolutionPreset.medium (a 720x480 JPEG of
  /// roughly 50-150 KB), so this normally returns the file untouched; an
  /// oversized one is re-encoded smaller as PNG, the only format dart:ui
  /// can write.
  static Future<({Uint8List bytes, String type})?> proofBytes(File f) async {
    final raw = await f.readAsBytes();
    if (raw.length <= maxProofBytes) return (bytes: raw, type: 'image/jpeg');
    for (final width in [640, 480]) {
      final codec = await ui.instantiateImageCodec(raw, targetWidth: width);
      final frame = await codec.getNextFrame();
      final png =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (png != null && png.lengthInBytes <= maxProofBytes) {
        return (bytes: png.buffer.asUint8List(), type: 'image/png');
      }
    }
    return null;
  }

  /// A complaint's photo proofs, in the order they were taken.
  Stream<List<Uint8List>> photos(String complaintId) => _complaints
      .doc(complaintId)
      .collection('photos')
      .snapshots()
      .map((s) => (s.docs.toList()..sort((a, b) => a.id.compareTo(b.id)))
          .map((d) => (d.data()['bytes'] as Blob).bytes)
          .toList());

  /// Creates the complaint doc + its photo proofs + triggers AI enrichment.
  /// Returns the complaint id.
  Future<String> submit({
    required String uid,
    required String description,
    String? department,
    required File photo,
    List<File> extraPhotos = const [],
    required double lat,
    required double lng,
    required double accuracy,
    required String zoneName,
    required DateTime capturedAt,
    bool bypassGeofence = false,
  }) async {
    final ref = _complaints.doc();
    final photos = [photo, ...extraPhotos];

    // Without Cloud Storage (Spark plan) the proofs live in Firestore, one
    // per document under complaints/{id}/photos. They go in the same batch
    // as the complaint, so it is saved with all its photos or not at all.
    final proofs = <({Uint8List bytes, String type})>[];
    if (!AppConfig.uploadPhotos) {
      for (final f in photos) {
        final p = await proofBytes(f);
        if (p != null) proofs.add(p);
      }
    }

    final batch = _db.batch();
    batch.set(ref, {
      'aliasName': 'Assigning…',
      'studentUid': uid,
      'description': description,
      if (department != null) 'department': department,
      'photoUrl': null,
      'photoUrls': [],
      'photoCount': proofs.length,
      'location': ComplaintLocation(
              lat: lat, lng: lng, accuracy: accuracy, zoneName: zoneName)
          .toMap(),
      'capturedAt': Timestamp.fromDate(capturedAt),
      'submittedAt': FieldValue.serverTimestamp(),
      'ai': null,
      'status': 'submitted',
      'statusHistory': [
        {
          'status': 'submitted',
          'byRole': 'student',
          'at': Timestamp.fromDate(DateTime.now()),
          'note': null,
        }
      ],
    });
    for (var i = 0; i < proofs.length; i++) {
      batch.set(ref.collection('photos').doc('$i'), {
        'bytes': Blob(proofs[i].bytes),
        'contentType': proofs[i].type,
      });
    }
    await batch.commit();

    // Cloud Storage path, for a project on the Blaze plan: resumable uploads
    // that survive flaky mobile data. Off while AppConfig.uploadPhotos is
    // false, which stores the proofs in Firestore above instead.
    if (AppConfig.uploadPhotos) {
      final urls = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final name = i == 0 ? '${ref.id}.jpg' : '${ref.id}_$i.jpg';
        final task = await _storage
            .ref('complaints/$name')
            .putFile(photos[i], SettableMetadata(contentType: 'image/jpeg'));
        urls.add(await task.ref.getDownloadURL());
      }
      await ref.update({'photoUrl': urls.first, 'photoUrls': urls});
    }

    // AI enrichment. The service writes back to Firestore itself when it can;
    // if that fails, apply the returned enrichment from the client.
    final result = await _ai.analyze(
      complaintId: ref.id,
      description: description,
      lat: lat,
      lng: lng,
      capturedAt: capturedAt,
      bypassGeofence: bypassGeofence,
      department: department,
    );
    if (result != null && result['writtenToFirestore'] != true) {
      await ref.update({
        'aliasName': result['aliasName'],
        'ai': result['ai'],
      });
    }
    return ref.id;
  }

  Future<void> submitFeedback(String id, int rating, String? comment) =>
      _complaints.doc(id).update({
        'feedback': {
          'rating': rating,
          'comment': comment,
          'at': Timestamp.now(),
        }
      });

  /// Owner-only while the complaint is still 'submitted' (rules-enforced).
  Future<void> editDescription(String id, String description) =>
      _complaints.doc(id).update({'description': description});

  Future<void> cancelComplaint(String id) => _complaints.doc(id).update({
        'status': 'cancelled',
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'byRole': 'student',
            'at': Timestamp.now(),
            'note': 'Cancelled by the reporter',
          }
        ]),
      });

  /// Resolved-but-not-actually-fixed: back into the queue.
  Future<void> reopen(String id) => _complaints.doc(id).update({
        'status': 'submitted',
        'escalated': false,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'submitted',
            'byRole': 'student',
            'at': Timestamp.now(),
            'note': 'Reopened — the problem is not fixed',
          }
        ]),
      });

  // ---------- comments (student <-> admin thread) ----------

  Stream<List<ComplaintComment>> comments(String complaintId) => _complaints
      .doc(complaintId)
      .collection('comments')
      .orderBy('at')
      .snapshots()
      .map((s) => s.docs.map(ComplaintComment.fromDoc).toList());

  Future<void> addComment(String complaintId,
          {required String byRole, required String text}) =>
      _complaints.doc(complaintId).collection('comments').add({
        'byRole': byRole,
        'text': text,
        'at': FieldValue.serverTimestamp(),
      });

  // ---------- admin ----------

  /// All complaints, or just one department's for dept-scoped admins.
  Stream<List<Complaint>> allComplaints({int limit = 300, String? dept}) {
    Query<Map<String, dynamic>> q = _complaints;
    if (dept != null) q = q.where('department', isEqualTo: dept);
    return q
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Complaint.fromDoc).toList());
  }

  Future<void> updateStatus({
    required Complaint complaint,
    required String newStatus,
    String? note,
  }) =>
      _complaints.doc(complaint.id).update({
        'status': newStatus,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': newStatus,
            'byRole': 'admin',
            'at': Timestamp.now(),
            'note': note,
          }
        ]),
      });
}

/// FCM wiring. With the placeholder Firebase project, live push delivery is
/// inactive — everything degrades gracefully to the in-app real-time updates
/// that Firestore listeners already provide. Once a real Firebase project is
/// plugged in, pushes work without code changes.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> init(String uid) async {
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      }
      _messaging.onTokenRefresh.listen((t) {
        _db.collection('users').doc(uid).update({'fcmToken': t});
      });
    } catch (e) {
      // Placeholder Firebase project or emulator: push unavailable, app
      // continues on Firestore real-time listeners alone.
      debugPrint('FCM init skipped: $e');
    }
  }

  /// Foreground messages -> caller shows an in-app banner.
  void onForegroundMessage(void Function(String title, String body) handler) {
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      final n = m.notification;
      if (n != null) handler(n.title ?? 'Update', n.body ?? '');
    });
  }
}

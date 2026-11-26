import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import '../services/notification_service.dart';
import '../services/offline_queue.dart';

enum AuthPhase { loading, signedOut, signedIn }

class AppState extends ChangeNotifier {
  final auth = AuthService();
  final complaints = ComplaintService();
  final notifications = NotificationService();
  late final OfflineQueue offlineQueue = OfflineQueue(complaints);

  AuthPhase phase = AuthPhase.loading;
  AppUser? profile;
  bool online = true;

  StreamSubscription? _authSub;
  StreamSubscription? _profileSub;
  StreamSubscription? _connSub;

  AppState() {
    _authSub = auth.authState.listen(_onAuth);
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nowOnline = !results.contains(ConnectivityResult.none);
      if (nowOnline != online) {
        online = nowOnline;
        notifyListeners();
      }
    });
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('lang');
      if (saved != null && saved != L10n.code) {
        L10n.code = saved;
        notifyListeners();
      }
    });
  }

  String get lang => L10n.code;

  Future<void> setLang(String code) async {
    L10n.code = code;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', code);
  }

  Future<void> _onAuth(User? user) async {
    _profileSub?.cancel();
    if (user == null) {
      phase = AuthPhase.signedOut;
      profile = null;
      notifyListeners();
      return;
    }
    _profileSub = auth.profileStream(user.uid).listen((p) {
      profile = p;
      phase = AuthPhase.signedIn;
      notifyListeners();
    });
    notifications.init(user.uid);
    offlineQueue.flush();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

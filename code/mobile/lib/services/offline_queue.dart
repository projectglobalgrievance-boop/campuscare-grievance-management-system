/// Offline submission queue.
///
/// A complaint submitted with no network is persisted here (photo path +
/// metadata INCLUDING the original capture GPS/time, so the geofence stays
/// valid) and auto-flushed when connectivity returns.
library;

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'complaint_service.dart';

class PendingComplaint {
  final String uid;
  final String description;
  final String photoPath;
  final List<String> extraPhotoPaths;
  final String? department;
  final double lat;
  final double lng;
  final double accuracy;
  final String zoneName;
  final DateTime capturedAt;
  final bool bypassGeofence;

  PendingComplaint({
    required this.uid,
    required this.description,
    required this.photoPath,
    this.extraPhotoPaths = const [],
    this.department,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.zoneName,
    required this.capturedAt,
    this.bypassGeofence = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'description': description,
        'photoPath': photoPath,
        'extraPhotoPaths': extraPhotoPaths,
        'department': department,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'zoneName': zoneName,
        'capturedAt': capturedAt.toIso8601String(),
        'bypassGeofence': bypassGeofence,
      };

  factory PendingComplaint.fromJson(Map<String, dynamic> j) =>
      PendingComplaint(
        uid: j['uid'] as String,
        description: j['description'] as String,
        photoPath: j['photoPath'] as String,
        extraPhotoPaths:
            ((j['extraPhotoPaths'] ?? []) as List).cast<String>(),
        department: j['department'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        accuracy: (j['accuracy'] as num).toDouble(),
        zoneName: j['zoneName'] as String,
        capturedAt: DateTime.parse(j['capturedAt'] as String),
        bypassGeofence: (j['bypassGeofence'] ?? false) as bool,
      );
}

class OfflineQueue extends ChangeNotifier {
  static const _key = 'pending_complaints_v1';
  final ComplaintService _complaints;
  bool _flushing = false;
  int _pendingCount = 0;

  int get pendingCount => _pendingCount;

  OfflineQueue(this._complaints) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) flush();
    });
    _refreshCount();
  }

  Future<List<PendingComplaint>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) =>
            PendingComplaint.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<PendingComplaint> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, items.map((p) => jsonEncode(p.toJson())).toList());
    _pendingCount = items.length;
    notifyListeners();
  }

  Future<void> _refreshCount() async {
    _pendingCount = (await _load()).length;
    notifyListeners();
  }

  Future<void> enqueue(PendingComplaint p) async {
    final items = await _load();
    items.add(p);
    await _save(items);
  }

  /// Try to submit everything in the queue. Items whose photo file vanished
  /// are dropped; items that fail again stay queued.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final items = await _load();
      if (items.isEmpty) return;
      final remaining = <PendingComplaint>[];
      for (final p in items) {
        final file = File(p.photoPath);
        if (!file.existsSync()) continue;
        try {
          await _complaints.submit(
            uid: p.uid,
            description: p.description,
            department: p.department,
            photo: file,
            extraPhotos: [
              for (final path in p.extraPhotoPaths)
                if (File(path).existsSync()) File(path),
            ],
            lat: p.lat,
            lng: p.lng,
            accuracy: p.accuracy,
            zoneName: p.zoneName,
            capturedAt: p.capturedAt,
            bypassGeofence: p.bypassGeofence,
          );
        } catch (_) {
          remaining.add(p);
        }
      }
      await _save(remaining);
    } finally {
      _flushing = false;
    }
  }
}

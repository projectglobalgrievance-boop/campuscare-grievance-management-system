/// Point-in-polygon geofence — mirrors code/ai-service/app/geofence.py.
library;

import 'dart:math' as math;

import '../config/campus_geo.dart';

const double _metersPerDegLat = 111320.0;

bool _rayCast(double lat, double lng, List<GeoPoint2> polygon) {
  var inside = false;
  var j = polygon.length - 1;
  for (var i = 0; i < polygon.length; i++) {
    final yi = polygon[i].lat, xi = polygon[i].lng;
    final yj = polygon[j].lat, xj = polygon[j].lng;
    if ((xi > lng) != (xj > lng)) {
      final intersectLat = (yj - yi) * (lng - xi) / (xj - xi) + yi;
      if (lat < intersectLat) inside = !inside;
    }
    j = i;
  }
  return inside;
}

double _distanceToSegmentM(
    double lat, double lng, GeoPoint2 a, GeoPoint2 b) {
  final cosLat = math.cos(lat * math.pi / 180);
  final px = lng * _metersPerDegLat * cosLat;
  final py = lat * _metersPerDegLat;
  final ax = a.lng * _metersPerDegLat * cosLat;
  final ay = a.lat * _metersPerDegLat;
  final bx = b.lng * _metersPerDegLat * cosLat;
  final by = b.lat * _metersPerDegLat;
  final dx = bx - ax, dy = by - ay;
  if (dx == 0 && dy == 0) {
    return math.sqrt(math.pow(px - ax, 2) + math.pow(py - ay, 2)).toDouble();
  }
  var t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  return math.sqrt(math.pow(px - cx, 2) + math.pow(py - cy, 2)).toDouble();
}

double distanceToBoundaryM(double lat, double lng) {
  var minDist = double.infinity;
  final b = CampusGeo.boundary;
  for (var i = 0; i < b.length; i++) {
    final d = _distanceToSegmentM(lat, lng, b[i], b[(i + 1) % b.length]);
    if (d < minDist) minDist = d;
  }
  return minDist;
}

/// Inside the boundary, or within the buffer just outside it (gate tolerance).
bool isInsideCampus(double lat, double lng) {
  if (_rayCast(lat, lng, CampusGeo.boundary)) return true;
  return distanceToBoundaryM(lat, lng) <= CampusGeo.boundaryBufferMeters;
}

/// Boundary vertices as (lat, lng) records — used by the schematic map painter.
List<(double, double)> campusBoundaryForPainting() =>
    CampusGeo.boundary.map((p) => (p.lat, p.lng)).toList();

/// Zone containing the point; 'Campus' if inside but unzoned; null if outside.
String? zoneNameFor(double lat, double lng) {
  if (!isInsideCampus(lat, lng)) return null;
  for (final zone in CampusGeo.zones) {
    if (_rayCast(lat, lng, zone.polygon)) return zone.name;
  }
  return 'Campus';
}

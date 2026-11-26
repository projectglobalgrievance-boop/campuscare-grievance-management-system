/// Campus boundary + zones.
///
/// GENERATED from code/ai-service/data/campus_geo.json by
/// scripts/gen_campus_geo.py — edit the JSON and regenerate; do not edit
/// this file by hand.
library;

class GeoPoint2 {
  final double lat;
  final double lng;
  const GeoPoint2(this.lat, this.lng);
}

class CampusZone {
  final String name;
  final List<GeoPoint2> polygon;
  const CampusZone(this.name, this.polygon);
}

class CampusGeo {
  CampusGeo._();

  static const double boundaryBufferMeters = 15;

  static const List<GeoPoint2> boundary = [
    GeoPoint2(12.927729, 77.524789),
    GeoPoint2(12.92734, 77.524872),
    GeoPoint2(12.92693, 77.52507),
    GeoPoint2(12.926578, 77.525372),
    GeoPoint2(12.926514, 77.525427),
    GeoPoint2(12.926539, 77.525531),
    GeoPoint2(12.926497, 77.52554),
    GeoPoint2(12.92634, 77.525573),
    GeoPoint2(12.926315, 77.525404),
    GeoPoint2(12.92601, 77.525443),
    GeoPoint2(12.925949, 77.525258),
    GeoPoint2(12.92567, 77.525231),
    GeoPoint2(12.925194, 77.526592),
    GeoPoint2(12.925171, 77.52666),
    GeoPoint2(12.9262, 77.52699),
    GeoPoint2(12.926221, 77.527318),
    GeoPoint2(12.926987, 77.527178),
    GeoPoint2(12.927003, 77.527241),
    GeoPoint2(12.927107, 77.527656),
    GeoPoint2(12.927973, 77.527594),
    GeoPoint2(12.928253, 77.527422),
    GeoPoint2(12.928311, 77.527248),
    GeoPoint2(12.928354, 77.527272),
    GeoPoint2(12.9284, 77.527288),
    GeoPoint2(12.928449, 77.527296),
    GeoPoint2(12.928491, 77.527297),
    GeoPoint2(12.928533, 77.527291),
    GeoPoint2(12.928573, 77.527279),
    GeoPoint2(12.928612, 77.527261),
    GeoPoint2(12.928647, 77.527237),
    GeoPoint2(12.928697, 77.527185),
    GeoPoint2(12.928752, 77.527138),
    GeoPoint2(12.928812, 77.527098),
    GeoPoint2(12.928865, 77.527069),
    GeoPoint2(12.92892, 77.527046),
    GeoPoint2(12.928977, 77.527028),
    GeoPoint2(12.929012, 77.527022),
    GeoPoint2(12.929047, 77.527024),
    GeoPoint2(12.929081, 77.527036),
    GeoPoint2(12.929111, 77.527056),
    GeoPoint2(12.929135, 77.527084),
    GeoPoint2(12.929152, 77.527117),
    GeoPoint2(12.929146, 77.527158),
    GeoPoint2(12.929149, 77.5272),
    GeoPoint2(12.92916, 77.52724),
    GeoPoint2(12.929178, 77.527275),
    GeoPoint2(12.929202, 77.527306),
    GeoPoint2(12.929232, 77.527332),
    GeoPoint2(12.929267, 77.527351),
    GeoPoint2(12.929304, 77.527362),
    GeoPoint2(12.929343, 77.527366),
    GeoPoint2(12.929364, 77.527079),
    GeoPoint2(12.929317, 77.527122),
    GeoPoint2(12.929217, 77.526872),
    GeoPoint2(12.929073, 77.526835),
    GeoPoint2(12.928872, 77.526856),
    GeoPoint2(12.928697, 77.526913),
    GeoPoint2(12.928566, 77.526148),
    GeoPoint2(12.927846, 77.525789),
    GeoPoint2(12.92785, 77.525487),
    GeoPoint2(12.927796, 77.52542),
    GeoPoint2(12.927735, 77.524933),
    GeoPoint2(12.927738, 77.524821),
  ];

  static const List<CampusZone> zones = [
    CampusZone('Block A', [
      GeoPoint2(12.9286, 77.5265),
      GeoPoint2(12.9286, 77.5277),
      GeoPoint2(12.927, 77.5277),
      GeoPoint2(12.927, 77.5265),
    ]),
    CampusZone('Block B', [
      GeoPoint2(12.9286, 77.5256),
      GeoPoint2(12.9286, 77.5265),
      GeoPoint2(12.927, 77.5265),
      GeoPoint2(12.927, 77.5256),
    ]),
    CampusZone('Block C', [
      GeoPoint2(12.9277, 77.5249),
      GeoPoint2(12.9277, 77.5256),
      GeoPoint2(12.927, 77.5256),
      GeoPoint2(12.927, 77.5249),
    ]),
    CampusZone('Library', [
      GeoPoint2(12.927, 77.525),
      GeoPoint2(12.927, 77.5258),
      GeoPoint2(12.9263, 77.5258),
      GeoPoint2(12.9263, 77.525),
    ]),
    CampusZone('Canteen', [
      GeoPoint2(12.927, 77.5258),
      GeoPoint2(12.927, 77.527),
      GeoPoint2(12.9263, 77.527),
      GeoPoint2(12.9263, 77.5258),
    ]),
    CampusZone('Hostel', [
      GeoPoint2(12.9294, 77.5266),
      GeoPoint2(12.9294, 77.5276),
      GeoPoint2(12.9286, 77.5276),
      GeoPoint2(12.9286, 77.5266),
    ]),
    CampusZone('Parking', [
      GeoPoint2(12.9263, 77.5268),
      GeoPoint2(12.9263, 77.5273),
      GeoPoint2(12.9258, 77.5273),
      GeoPoint2(12.9258, 77.5268),
    ]),
    CampusZone('Grounds', [
      GeoPoint2(12.9263, 77.5256),
      GeoPoint2(12.9263, 77.5268),
      GeoPoint2(12.9252, 77.5268),
      GeoPoint2(12.9252, 77.5256),
    ]),
  ];
}

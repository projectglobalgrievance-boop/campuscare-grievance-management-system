import 'package:flutter_test/flutter_test.dart';
import 'package:grievance_app/services/geofence.dart';

void main() {
  group('geofence', () {
    test('center of campus is inside', () {
      expect(isInsideCampus(12.92720, 77.52630), isTrue);
    });

    test('the old placeholder site 3 km away is outside', () {
      expect(isInsideCampus(12.8990, 77.5121), isFalse);
    });

    test('boundary buffer accepts a point just outside the edge', () {
      // ~5 m east of the eastern boundary edge, within the 15 m buffer.
      const lat = 12.92720, lng = 77.52770;
      expect(distanceToBoundaryM(lat, lng), lessThanOrEqualTo(15));
      expect(isInsideCampus(lat, lng), isTrue);
    });

    test('far point distance is large', () {
      expect(distanceToBoundaryM(12.8990, 77.5121), greaterThan(500));
    });

    test('zone resolution matches the python mirror', () {
      expect(zoneNameFor(12.92760, 77.52710), 'Block A');
      expect(zoneNameFor(12.92665, 77.52640), 'Canteen');
      expect(zoneNameFor(12.92580, 77.52620), 'Grounds');
    });

    test('outside campus has no zone', () {
      expect(zoneNameFor(12.8990, 77.5121), isNull);
    });

    test('inside boundary but unzoned resolves to Campus', () {
      expect(zoneNameFor(12.92660, 77.52710), 'Campus');
    });
  });
}

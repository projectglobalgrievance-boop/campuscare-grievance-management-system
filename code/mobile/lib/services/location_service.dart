import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

sealed class LocationResult {
  const LocationResult();
}

class LocationOk extends LocationResult {
  final Position position;
  const LocationOk(this.position);
}

class LocationDenied extends LocationResult {
  final bool forever;
  const LocationDenied({this.forever = false});
}

class LocationDisabled extends LocationResult {
  const LocationDisabled();
}

class LocationInaccurate extends LocationResult {
  final double accuracy;
  const LocationInaccurate(this.accuracy);
}

class LocationMocked extends LocationResult {
  const LocationMocked();
}

class LocationService {
  /// Pre-warm the GPS when the camera opens so the shutter press is instant.
  Future<void> warmUp() async {
    try {
      await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
    } catch (_) {/* warm-up is best-effort */}
  }

  Future<LocationResult> capturePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationDisabled();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationDenied(forever: true);
    }
    if (permission == LocationPermission.denied) {
      return const LocationDenied();
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 15),
      ),
    );

    if (pos.isMocked) return const LocationMocked();
    if (pos.accuracy > AppConfig.maxGpsAccuracyMeters) {
      return LocationInaccurate(pos.accuracy);
    }
    return LocationOk(pos);
  }
}

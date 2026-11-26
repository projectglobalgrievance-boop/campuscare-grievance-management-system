/// Central app configuration.
///
/// Run against local emulators + local AI service:
///   flutter run --dart-define=USE_EMULATOR=true
class AppConfig {
  AppConfig._();

  /// When true, Auth/Firestore/Storage connect to the local emulator suite.
  static const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

  /// Android emulator reaches the host machine via 10.0.2.2.
  static const String emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

  /// Base URL of the FastAPI AI service.
  static const String aiServiceUrl = String.fromEnvironment('AI_SERVICE_URL',
      defaultValue: 'http://10.0.2.2:8000');

  /// TEMPORARY (2026-08-17) — Cloud Storage needs the Blaze plan and the
  /// Firebase project is on Spark for the demo, so photos are captured
  /// but not uploaded: the complaint saves with `photoUrl: null` and the UI
  /// falls back to the category icon. Nothing else changes.
  ///
  /// TO RESTORE PHOTOS: upgrade the project to Blaze, enable Storage, deploy
  /// storage.rules, flip this to `true` and rebuild. The upload code in
  /// ComplaintService.submit is untouched underneath this flag.
  static const bool uploadPhotos = false;

  /// Restrict signup to a college domain (e.g. 'gat.ac.in'). null = any email.
  static const String? allowedDomain = null;

  /// GPS accuracy worse than this (meters) asks the user to retry.
  static const double maxGpsAccuracyMeters = 50;

  static const String appName = 'CampusCare';
  static const String campusName = 'Global Academy of Technology';
}

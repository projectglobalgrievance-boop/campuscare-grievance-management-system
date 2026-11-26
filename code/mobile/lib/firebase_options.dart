// ============================================================================
// Firebase connection settings.
//
// Nothing is written here by hand. The values come from the keys file at
// build time:
//
//     flutter build apk --release --dart-define-from-file=../keys/keys.env
//
// Built WITHOUT that file, the app gets the placeholder values below. They
// have a valid shape but belong to no real project, and are meant for the
// local run, where the app talks to the Firebase emulators on your own
// computer (project ids starting with "demo-" can never reach a real
// project).
//
// How to get your own values: guidelines/05-firebase.
// ============================================================================
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY',
        defaultValue: 'AIzaSyDEMO-PLACEHOLDER-KEY-000000000000000'),
    appId: String.fromEnvironment('FIREBASE_APP_ID',
        defaultValue: '1:000000000000:android:0000000000000000000000'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '000000000000'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID',
        defaultValue: 'demo-campuscare'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET',
        defaultValue: 'demo-campuscare.appspot.com'),
  );
}

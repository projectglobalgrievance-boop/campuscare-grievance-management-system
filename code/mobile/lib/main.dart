import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A build made from an unfilled keys file has empty settings. Say so
  // plainly instead of failing later with a confusing sign-in error.
  const o = DefaultFirebaseOptions.currentPlatform;
  if (o.apiKey.isEmpty ||
      o.appId.isEmpty ||
      o.messagingSenderId.isEmpty ||
      o.projectId.isEmpty ||
      (o.storageBucket ?? '').isEmpty ||
      AppConfig.aiServiceUrl.isEmpty) {
    runApp(const _MissingKeys());
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (AppConfig.useEmulator) {
    const host = AppConfig.emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const CampusCareApp(),
    ),
  );
}

class CampusCareApp extends StatelessWidget {
  const CampusCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

class _MissingKeys extends StatelessWidget {
  const _MissingKeys();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This copy of the app was built without its keys.\n\n'
                'Fill in every line of code/keys/keys.env and build the app '
                'again. See guidelines/04-keys.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

// File generated for Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  /// Returns true only if real non-demo Firebase project credentials are configured
  static bool get isConfigured {
    final key = currentPlatform.apiKey;
    return key.isNotEmpty && !key.startsWith('AIzaSyDemo');
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForGeographicDuelWeb123456789',
    appId: '1:100000000000:web:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'geographic-duel',
    authDomain: 'geographic-duel.firebaseapp.com',
    storageBucket: 'geographic-duel.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForGeographicDuelAndroid12345',
    appId: '1:100000000000:android:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'geographic-duel',
    storageBucket: 'geographic-duel.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKeyForGeographicDuelIos1234567890',
    appId: '1:100000000000:ios:abcdef1234567890abcdef',
    messagingSenderId: '100000000000',
    projectId: 'geographic-duel',
    storageBucket: 'geographic-duel.appspot.com',
    iosBundleId: 'com.example.geographicDuel',
  );
}

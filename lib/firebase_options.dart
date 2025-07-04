// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUhZyR8gdLtVKr3MTxRBfiT52asc7RQv8',
    appId: '1:173770111771:android:fd8e00ebd41d8961cdf1be',
    messagingSenderId: '173770111771',
    projectId: 'retixly-58e1e',
    storageBucket: 'retixly-58e1e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUhZyR8gdLtVKr3MTxRBfiT52asc7RQv8',
    appId: '1:173770111771:android:fd8e00ebd41d8961cdf1be',
    messagingSenderId: '173770111771',
    projectId: 'ai-wrozka-production',
    storageBucket: 'ai-wrozka-production.appspot.com',
    iosBundleId: 'com.example.aiWrozka',
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Real credentials from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMdrfvSP8bQVHG8BuyoUyeKZzacYLYqHY',
    appId: '1:247355788767:web:af3de2d22a8d0cbf88886a',
    messagingSenderId: '247355788767',
    projectId: 'rebrand-f723c',
    authDomain: 'rebrand-f723c.firebaseapp.com',
    storageBucket: 'rebrand-f723c.firebasestorage.app',
    measurementId: 'G-FYS9MEZX44',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMdrfvSP8bQVHG8BuyoUyeKZzacYLYqHY',
    appId: '1:247355788767:web:af3de2d22a8d0cbf88886a', // Usually needs android specific appId, but we can reuse for now
    messagingSenderId: '247355788767',
    projectId: 'rebrand-f723c',
    storageBucket: 'rebrand-f723c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMdrfvSP8bQVHG8BuyoUyeKZzacYLYqHY',
    appId: '1:247355788767:web:af3de2d22a8d0cbf88886a', // Usually needs iOS specific appId, but we can reuse for now
    messagingSenderId: '247355788767',
    projectId: 'rebrand-f723c',
    storageBucket: 'rebrand-f723c.firebasestorage.app',
    iosBundleId: 'com.example.credo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMdrfvSP8bQVHG8BuyoUyeKZzacYLYqHY',
    appId: '1:247355788767:web:af3de2d22a8d0cbf88886a', // Usually needs macOS specific appId, but we can reuse for now
    messagingSenderId: '247355788767',
    projectId: 'rebrand-f723c',
    storageBucket: 'rebrand-f723c.firebasestorage.app',
    iosBundleId: 'com.example.credo.RunnerTests',
  );
}

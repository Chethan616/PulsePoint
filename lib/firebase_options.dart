// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCI4h9iKS9nBF5c9YJY9KqtrB8k1Yq3-uY',
    appId: '1:555587912223:web:e3e6d061e7ac995ca80b2a',
    messagingSenderId: '555587912223',
    projectId: 'pulse-point-pulse-point',
    authDomain: 'pulse-point-pulse-point.firebaseapp.com',
    storageBucket: 'pulse-point-pulse-point.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhul8Xd7erUyhJsAaFXDOqbjaF-3hYyI4',
    appId: '1:555587912223:android:ffdcf4c308c6ad1ca80b2a',
    messagingSenderId: '555587912223',
    projectId: 'pulse-point-pulse-point',
    storageBucket: 'pulse-point-pulse-point.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBTUI62WcFp-_RWekDZKThx6gxJPB6kuoE',
    appId: '1:555587912223:ios:5aac99d42fac0aa6a80b2a',
    messagingSenderId: '555587912223',
    projectId: 'pulse-point-pulse-point',
    storageBucket: 'pulse-point-pulse-point.firebasestorage.app',
    iosBundleId: 'com.example.pulsepointV2',
  );
}

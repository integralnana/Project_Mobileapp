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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBO3VQD8fjFxezDPJYY8FSmZxrm_WMSmBU',
    appId: '1:163897380043:web:85edaab7bc1a50fca79f4e',
    messagingSenderId: '163897380043',
    projectId: 'myproj-c6008',
    authDomain: 'myproj-c6008.firebaseapp.com',
    storageBucket: 'myproj-c6008.appspot.com',
    measurementId: 'G-H8TE85ZDTL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3ANi7qcWr0h2f3vkB4V_6KaV8UOgp93Y',
    appId: '1:163897380043:android:ad7b0effe0942c72a79f4e',
    messagingSenderId: '163897380043',
    projectId: 'myproj-c6008',
    storageBucket: 'myproj-c6008.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNyYCN_IJCYbK1fHRMacX1WGZe6MRzfyU',
    appId: '1:163897380043:ios:7f340f39c5473b8da79f4e',
    messagingSenderId: '163897380043',
    projectId: 'myproj-c6008',
    storageBucket: 'myproj-c6008.appspot.com',
    iosBundleId: 'com.example.projectapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCNyYCN_IJCYbK1fHRMacX1WGZe6MRzfyU',
    appId: '1:163897380043:ios:7f340f39c5473b8da79f4e',
    messagingSenderId: '163897380043',
    projectId: 'myproj-c6008',
    storageBucket: 'myproj-c6008.appspot.com',
    iosBundleId: 'com.example.projectapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBO3VQD8fjFxezDPJYY8FSmZxrm_WMSmBU',
    appId: '1:163897380043:web:919aadb1ffa3a1cda79f4e',
    messagingSenderId: '163897380043',
    projectId: 'myproj-c6008',
    authDomain: 'myproj-c6008.firebaseapp.com',
    storageBucket: 'myproj-c6008.appspot.com',
    measurementId: 'G-TSQTYSVKZL',
  );
}

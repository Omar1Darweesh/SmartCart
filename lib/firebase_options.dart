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
    apiKey: 'AIzaSyCGe8yiWNgjl-BRlhoI2sLFwpdFRbdAj2U',
    appId: '1:918828157429:web:038a954b695cc82eae38bc',
    messagingSenderId: '918828157429',
    projectId: 'egyproducts-a04fa',
    authDomain: 'egyproducts-a04fa.firebaseapp.com',
    storageBucket: 'egyproducts-a04fa.firebasestorage.app',
    measurementId: 'G-DD27T0N9T3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0BhflJyMIulAZpwVFPchn2bJrYuFGBJo',
    appId: '1:918828157429:android:3dba2e7de3b8df32ae38bc',
    messagingSenderId: '918828157429',
    projectId: 'egyproducts-a04fa',
    storageBucket: 'egyproducts-a04fa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAwurEmilnO3f8Ye0fZU7uH_DUGZlNTebs',
    appId: '1:918828157429:ios:56c79b80b91d8e19ae38bc',
    messagingSenderId: '918828157429',
    projectId: 'egyproducts-a04fa',
    storageBucket: 'egyproducts-a04fa.firebasestorage.app',
    iosBundleId: 'com.example.first',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAwurEmilnO3f8Ye0fZU7uH_DUGZlNTebs',
    appId: '1:918828157429:ios:56c79b80b91d8e19ae38bc',
    messagingSenderId: '918828157429',
    projectId: 'egyproducts-a04fa',
    storageBucket: 'egyproducts-a04fa.firebasestorage.app',
    iosBundleId: 'com.example.first',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCGe8yiWNgjl-BRlhoI2sLFwpdFRbdAj2U',
    appId: '1:918828157429:web:9cd2fa149ec66fffae38bc',
    messagingSenderId: '918828157429',
    projectId: 'egyproducts-a04fa',
    authDomain: 'egyproducts-a04fa.firebaseapp.com',
    storageBucket: 'egyproducts-a04fa.firebasestorage.app',
    measurementId: 'G-7H7WPN56RE',
  );

}
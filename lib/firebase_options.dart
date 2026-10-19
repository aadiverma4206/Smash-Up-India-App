
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyDVDtJ4AJU7_CLLeVc2oc98XdzMPEHRT7U',
    appId: '1:246194507604:web:c81ea269b3aa0072e6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'all-stars-arena',
    authDomain: 'all-stars-arena.firebaseapp.com',
    storageBucket: 'all-stars-arena.firebasestorage.app',
    measurementId: 'G-YT4JFQZDZN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5owclfhh04GXawIjWhwrBNO_kukGyLhI',
    appId: '1:246194507604:android:5a222a70f60fd5f3e6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'all-stars-arena',
    storageBucket: 'all-stars-arena.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7wGvh9oyP9bfNoY7VrmQe6tfCdwmo4T4',
    appId: '1:246194507604:ios:44e3ecc36658c400e6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'all-stars-arena',
    storageBucket: 'all-stars-arena.firebasestorage.app',
    iosBundleId: 'com.example.allStarsArena',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB7wGvh9oyP9bfNoY7VrmQe6tfCdwmo4T4',
    appId: '1:246194507604:ios:44e3ecc36658c400e6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'all-stars-arena',
    storageBucket: 'all-stars-arena.firebasestorage.app',
    iosBundleId: 'com.example.allStarsArena',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDVDtJ4AJU7_CLLeVc2oc98XdzMPEHRT7U',
    appId: '1:246194507604:web:7402a9e4c923262ae6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'all-stars-arena',
    authDomain: 'all-stars-arena.firebaseapp.com',
    storageBucket: 'all-stars-arena.firebasestorage.app',
    measurementId: 'G-G6M2XC1KXZ',
  );
}

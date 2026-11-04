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
    projectId: 'smash-up-india',
    authDomain: 'smash-up-india.firebaseapp.com',
    storageBucket: 'smash-up-india.firebasestorage.app',
    measurementId: 'G-YT4JFQZDZN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwiKMzhFxUhWW0phUnhTf6K4Kp5xH-Dbc',
    appId: '1:445926000796:android:f5d1987bec0334549c4559',
    messagingSenderId: '445926000796',
    projectId: 'smash-up-india',
    storageBucket: 'smash-up-india.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA8dg5_OUKFftnT_3OY3rkhJOI2WTKna-8',
    appId: '1:445926000796:ios:10c07f578e76053a9c4559',
    messagingSenderId: '445926000796',
    projectId: 'smash-up-india',
    storageBucket: 'smash-up-india.firebasestorage.app',
    iosBundleId: 'com.example.smash-up-india',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA8dg5_OUKFftnT_3OY3rkhJOI2WTKna-8',
    appId: '1:445926000796:ios:10c07f578e76053a9c4559',
    messagingSenderId: '445926000796',
    projectId: 'smash-up-india',
    storageBucket: 'smash-up-india.firebasestorage.app',
    iosBundleId: 'com.example.smash-up-india',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDVDtJ4AJU7_CLLeVc2oc98XdzMPEHRT7U',
    appId: '1:246194507604:web:7402a9e4c923262ae6c2c1',
    messagingSenderId: '246194507604',
    projectId: 'smash-up-india',
    authDomain: 'smash-up-india.firebaseapp.com',
    storageBucket: 'smash-up-india.firebasestorage.app',
    measurementId: 'G-G6M2XC1KXZ',
  );
}

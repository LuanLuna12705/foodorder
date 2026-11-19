import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] cho ứng dụng Firebase.
/// Bạn có thể tự động tạo lại file này bằng lệnh: `flutterfire configure`
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
          'DefaultFirebaseOptions chưa được cấu hình cho Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa được cấu hình cho Linux.',
        );
      default:
        throw UnsupportedError(
          'Platform này chưa được hỗ trợ.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcQDpjpPGrVKmZCCU6G12UxmgwQ4SJhWM',
    appId: '1:718764490635:web:09839432e2ed6ef800398e',
    messagingSenderId: '718764490635',
    projectId: 'foodorder-edc11',
    authDomain: 'foodorder-edc11.firebaseapp.com',
    storageBucket: 'foodorder-edc11.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcQDpjpPGrVKmZCCU6G12UxmgwQ4SJhWM',
    appId: '1:718764490635:android:09839432e2ed6ef800398e',
    messagingSenderId: '718764490635',
    projectId: 'foodorder-edc11',
    storageBucket: 'foodorder-edc11.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCcQDpjpPGrVKmZCCU6G12UxmgwQ4SJhWM',
    appId: '1:718764490635:ios:09839432e2ed6ef800398e',
    messagingSenderId: '718764490635',
    projectId: 'foodorder-edc11',
    storageBucket: 'foodorder-edc11.firebasestorage.app',
    iosBundleId: 'com.example.foodorder',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCcQDpjpPGrVKmZCCU6G12UxmgwQ4SJhWM',
    appId: '1:718764490635:ios:09839432e2ed6ef800398e',
    messagingSenderId: '718764490635',
    projectId: 'foodorder-edc11',
    storageBucket: 'foodorder-edc11.firebasestorage.app',
    iosBundleId: 'com.example.foodorder',
  );
}

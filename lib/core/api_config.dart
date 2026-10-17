import 'package:flutter/foundation.dart';

/// Alamat API Laravel.
///
/// Bisa dioverride saat build:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    if (kIsWeb) return 'http://127.0.0.1:8000';

    // Emulator Android memetakan host komputer ke 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}

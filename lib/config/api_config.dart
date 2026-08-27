import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Configurable via --dart-define=BACKEND_HOST=... with platform-aware fallback
  static const String _envHost = String.fromEnvironment('BACKEND_HOST', defaultValue: '');

  static String get host {
    if (_envHost.isNotEmpty) {
      return _envHost;
    }
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          return '10.0.2.2';
        }
      } catch (_) {
        // Fall back to localhost
      }
    }
    return 'localhost';
  }

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8086';
}


import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Configurable via --dart-define=BACKEND_HOST=... Defaults to 'localhost' for USB adb reverse / local dev
  static const String _envHost = String.fromEnvironment('BACKEND_HOST', defaultValue: 'localhost');
  static String? _customHost;
  static const String _hostPrefKey = 'backend_host_custom';

  /// Inisialisasi host tersimpan dari SharedPreferences jika ada
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_hostPrefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customHost = saved.trim();
      }
    } catch (_) {}
  }

  /// Atur host backend secara dinamis dan simpan ke persistent storage
  static Future<void> setCustomHost(String? host) async {
    _customHost = host?.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customHost == null || _customHost!.isEmpty) {
        await prefs.remove(_hostPrefKey);
      } else {
        await prefs.setString(_hostPrefKey, _customHost!);
      }
    } catch (_) {}
  }

  static String get host {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    return _envHost;
  }

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8086';
}


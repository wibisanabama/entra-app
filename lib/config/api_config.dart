class ApiConfig {
  // Configurable via --dart-define=BACKEND_HOST=... with fallback default
  static const String host = String.fromEnvironment('BACKEND_HOST', defaultValue: '192.168.0.106');

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8086';
}

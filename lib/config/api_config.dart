class ApiConfig {
  // Use 10.0.2.2 for Android emulator to connect to localhost on host machine
  // IP lokal laptop/PC (agar ponsel fisik dalam satu Wi-Fi bisa akses backend)
  static String host = '192.168.0.106';

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8080';
}

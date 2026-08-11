class ApiConfig {
  // Use 10.0.2.2 for Android emulator to connect to localhost on host machine
  // For physical device, change to host PC IP address (e.g. 192.168.1.x)
  static String host = '10.0.2.2';

  static String get authBaseUrl => 'http://$host:8081';
  static String get eventBaseUrl => 'http://$host:8082';
  static String get ticketBaseUrl => 'http://$host:8083';
  static String get gateBaseUrl => 'http://$host:8080';
}

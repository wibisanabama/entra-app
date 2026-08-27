import 'package:flutter_test/flutter_test.dart';
import 'package:entra_app/config/api_config.dart';

void main() {
  group('ApiConfig Tests', () {
    test('Host is resolved to a valid non-empty string', () {
      expect(ApiConfig.host, isNotEmpty);
      expect(ApiConfig.host, isA<String>());
    });

    test('Microservice base URLs are correctly constructed', () {
      final host = ApiConfig.host;
      expect(ApiConfig.authBaseUrl, equals('http://$host:8081'));
      expect(ApiConfig.eventBaseUrl, equals('http://$host:8082'));
      expect(ApiConfig.ticketBaseUrl, equals('http://$host:8083'));
      expect(ApiConfig.gateBaseUrl, equals('http://$host:8086'));
    });
  });
}

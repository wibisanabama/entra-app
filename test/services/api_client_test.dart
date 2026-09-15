import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entra_app/services/api_client.dart';
import 'package:entra_app/services/auth_service.dart';

class MockAuthService extends AuthService {
  int refreshCallCount = 0;
  String? mockToken;
  bool shouldSucceed = true;
  Duration delay = Duration.zero;

  @override
  Future<String?> getToken() async => mockToken;

  @override
  Future<Map<String, dynamic>> refreshToken() async {
    refreshCallCount++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldSucceed) {
      mockToken = 'refreshed_access_token';
      return {
        'success': true,
        'token': 'refreshed_access_token',
        'refreshToken': 'new_refresh_token',
      };
    }
    return {
      'success': false,
      'message': 'Refresh failed',
    };
  }
}

String createTestJwt(int expiryEpochSeconds) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final payload = base64Url.encode(utf8.encode(jsonEncode({
    'sub': 'user_123',
    'exp': expiryEpochSeconds,
  })));
  return '$header.$payload.dummySignature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Unit Tests', () {
    late MockAuthService mockAuth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAuth = MockAuthService();
    });

    test('GET, POST, PUT, DELETE send correct headers and return response', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer my_token'));
        expect(request.headers['Content-Type'], equals('application/json'));
        return http.Response('{"ok": true}', 200);
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      final getRes = await client.get(Uri.parse('http://example.com/test'), token: 'my_token');
      expect(getRes.statusCode, 200);

      final postRes = await client.post(Uri.parse('http://example.com/test'), token: 'my_token', body: '{"a":1}');
      expect(postRes.statusCode, 200);

      final putRes = await client.put(Uri.parse('http://example.com/test'), token: 'my_token', body: '{"b":2}');
      expect(putRes.statusCode, 200);

      final deleteRes = await client.delete(Uri.parse('http://example.com/test'), token: 'my_token');
      expect(deleteRes.statusCode, 200);
    });

    test('Proactive refresh triggers when token exp is within 30 seconds', () async {
      // Expiry in 10 seconds (well within 30s buffer)
      final expiringSoonToken = createTestJwt(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 10,
      );
      mockAuth.mockToken = expiringSoonToken;

      final requestsReceived = <http.Request>[];
      final mockClient = MockClient((request) async {
        requestsReceived.add(request);
        return http.Response('{"status": "ok"}', 200);
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      final res = await client.get(Uri.parse('http://example.com/api/profile'));
      expect(res.statusCode, 200);

      // Verify proactive refresh occurred BEFORE the request was made
      expect(mockAuth.refreshCallCount, equals(1));
      expect(requestsReceived.length, equals(1));
      expect(requestsReceived.first.headers['Authorization'], equals('Bearer refreshed_access_token'));
    });

    test('Proactive refresh does NOT trigger when token has sufficient validity', () async {
      // Expiry in 1 hour
      final validToken = createTestJwt(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      );
      mockAuth.mockToken = validToken;

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer $validToken'));
        return http.Response('{"status": "ok"}', 200);
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      final res = await client.get(Uri.parse('http://example.com/api/profile'));
      expect(res.statusCode, 200);
      expect(mockAuth.refreshCallCount, equals(0));
    });

    test('Reactive 401 retry refreshes token and retries request once with 200 success', () async {
      mockAuth.mockToken = 'expired_valid_format_jwt';

      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          expect(request.headers['Authorization'], equals('Bearer initial_token'));
          return http.Response('{"message": "Unauthorized"}', 401);
        } else {
          expect(request.headers['Authorization'], equals('Bearer refreshed_access_token'));
          return http.Response('{"status": "ok_after_refresh"}', 200);
        }
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      final res = await client.get(Uri.parse('http://example.com/resource'), token: 'initial_token');
      expect(res.statusCode, 200);
      expect(jsonDecode(res.body)['status'], equals('ok_after_refresh'));
      expect(requestCount, equals(2));
      expect(mockAuth.refreshCallCount, equals(1));
    });

    test('Reactive 401 broadcasts session expired when refresh fails', () async {
      mockAuth.mockToken = 'bad_token';
      mockAuth.shouldSucceed = false;

      var broadcastFired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        broadcastFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401);
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      final res = await client.get(Uri.parse('http://example.com/resource'), token: 'bad_token');
      expect(res.statusCode, 401);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(broadcastFired, isTrue);
      await sub.cancel();
    });

    test('Concurrent 401 responses deduplicate refresh through mutex (only 1 refresh call)', () async {
      mockAuth.mockToken = 'tok';
      mockAuth.delay = const Duration(milliseconds: 50);

      int requestAttempts = 0;
      final mockClient = MockClient((request) async {
        requestAttempts++;
        if (request.headers['Authorization'] != 'Bearer refreshed_access_token') {
          return http.Response('{"message": "Unauthorized"}', 401);
        }
        return http.Response('{"data": "success"}', 200);
      });

      final client = ApiClient(httpClient: mockClient, authService: mockAuth);

      // Fire 3 simultaneous requests
      final results = await Future.wait([
        client.get(Uri.parse('http://example.com/req1'), token: 'tok'),
        client.get(Uri.parse('http://example.com/req2'), token: 'tok'),
        client.get(Uri.parse('http://example.com/req3'), token: 'tok'),
      ]);

      for (final res in results) {
        expect(res.statusCode, equals(200));
      }

      // Exactly ONE refresh call despite 3 concurrent 401s
      expect(mockAuth.refreshCallCount, equals(1));
      expect(requestAttempts, equals(6));
    });
  });
}

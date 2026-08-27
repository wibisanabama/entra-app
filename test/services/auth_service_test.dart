import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entra_app/models/user.dart';
import 'package:entra_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Unit Tests', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'initial_access_token',
        'jwt_refresh_token': 'initial_refresh_token',
      });
      authService = AuthService();
    });

    test('getToken and getRefreshToken retrieve stored tokens', () async {
      expect(await authService.getToken(), equals('initial_access_token'));
      expect(await authService.getRefreshToken(), equals('initial_refresh_token'));
    });

    test('saveToken and saveRefreshToken store values', () async {
      await authService.saveToken('new_tok');
      expect(await authService.getToken(), equals('new_tok'));

      await authService.saveRefreshToken('new_ref');
      expect(await authService.getRefreshToken(), equals('new_ref'));
    });

    test('saveTokens stores both access and optional refresh tokens', () async {
      await authService.saveTokens(
        accessToken: 'saved_access',
        refreshToken: 'saved_refresh',
      );
      expect(await authService.getToken(), equals('saved_access'));
      expect(await authService.getRefreshToken(), equals('saved_refresh'));

      // If refresh token is null, existing refresh token remains unchanged
      await authService.saveTokens(accessToken: 'second_access', refreshToken: null);
      expect(await authService.getToken(), equals('second_access'));
      expect(await authService.getRefreshToken(), equals('saved_refresh'));
    });

    test('removeToken clears both access and refresh tokens', () async {
      await authService.removeToken();
      expect(await authService.getToken(), isNull);
      expect(await authService.getRefreshToken(), isNull);
    });

    test('broadcastSessionExpired emits on stream', () async {
      var emitted = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        emitted = true;
      });

      AuthService.broadcastSessionExpired();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitted, isTrue);
      await sub.cancel();
    });

    test('login succeeds on 200 with tokens object', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/auth/login')) {
          final body = jsonDecode(request.body);
          expect(body['email'], equals('organizer@entra.id'));
          expect(body['password'], equals('password123'));

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'tokens': {
                  'access_token': 'mock_access_jwt',
                  'refresh_token': 'mock_refresh_jwt',
                },
                'user': {
                  'id': 'u1',
                  'email': 'organizer@entra.id',
                  'full_name': 'Organizer One',
                  'role': 'organizer',
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final result = await authService.login('organizer@entra.id', 'password123');

        expect(result['success'], isTrue);
        expect(result['token'], equals('mock_access_jwt'));
        expect(result['refreshToken'], equals('mock_refresh_jwt'));
        expect(result['user'], isA<User>());
        expect((result['user'] as User).role, equals('organizer'));

        expect(await authService.getToken(), equals('mock_access_jwt'));
        expect(await authService.getRefreshToken(), equals('mock_refresh_jwt'));
      }, () => mockClient);
    });

    test('login handles flat access_token format on 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'access_token': 'flat_access_jwt',
              'refresh_token': 'flat_refresh_jwt',
              'user': {
                'id': 'u2',
                'email': 'admin@entra.id',
                'name': 'Admin Entra',
                'role': 'admin',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await authService.login('admin@entra.id', 'secret');
        expect(result['success'], isTrue);
        expect(result['token'], equals('flat_access_jwt'));
        expect(result['refreshToken'], equals('flat_refresh_jwt'));
      }, () => mockClient);
    });

    test('login returns error message on 401 invalid credentials', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Email atau password salah.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await authService.login('bad@entra.id', 'wrong');
        expect(result['success'], isFalse);
        expect(result['message'], equals('Email atau password salah.'));
      }, () => mockClient);
    });

    test('login handles network exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection failed');
      });

      await http.runWithClient(() async {
        final result = await authService.login('test@entra.id', 'pass');
        expect(result['success'], isFalse);
        expect(result['message'], contains('Gagal terhubung ke server'));
      }, () => mockClient);
    });

    test('refreshToken succeeds on 200 and saves new tokens', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/auth/refresh'));
        final body = jsonDecode(request.body);
        expect(body['refresh_token'], equals('initial_refresh_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'tokens': {
                'access_token': 'new_refreshed_access',
                'refresh_token': 'new_refreshed_refresh',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await authService.refreshToken();
        expect(result['success'], isTrue);
        expect(result['token'], equals('new_refreshed_access'));
        expect(result['refreshToken'], equals('new_refreshed_refresh'));
        expect(await authService.getToken(), equals('new_refreshed_access'));
        expect(await authService.getRefreshToken(), equals('new_refreshed_refresh'));
      }, () => mockClient);
    });

    test('refreshToken fails if no stored refresh token', () async {
      await authService.removeToken();
      final result = await authService.refreshToken();
      expect(result['success'], isFalse);
      expect(result['message'], contains('Tidak ada refresh token'));
    });

    test('refreshToken fails on 401, clears stored tokens and broadcasts expiration', () async {
      var expiredBroadcast = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        expiredBroadcast = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Refresh token expired.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await authService.refreshToken();
        expect(result['success'], isFalse);
        expect(await authService.getToken(), isNull);
        expect(await authService.getRefreshToken(), isNull);
        await Future.delayed(const Duration(milliseconds: 10));
        expect(expiredBroadcast, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('refreshToken handles network exceptions gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      await http.runWithClient(() async {
        final result = await authService.refreshToken();
        expect(result['success'], isFalse);
        expect(result['message'], contains('Gagal terhubung ke server'));
      }, () => mockClient);
    });

    test('getProfile returns User on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer initial_access_token'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'u10',
              'email': 'org@entra.id',
              'name': 'Org User',
              'role': 'organizer',
              'phone': '08123456789',
              'avatar_url': 'https://entra.id/avatar.png',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final user = await authService.getProfile();
        expect(user, isNotNull);
        expect(user!.id, equals('u10'));
        expect(user.name, equals('Org User'));
        expect(user.isOrganizer, isTrue);
      }, () => mockClient);
    });

    test('getProfile returns null if no token stored', () async {
      await authService.removeToken();
      final user = await authService.getProfile();
      expect(user, isNull);
    });

    test('getProfile performs automatic token refresh on 401 and succeeds on retry', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/auth/profile')) {
          callCount++;
          if (callCount == 1) {
            expect(request.headers['Authorization'], equals('Bearer initial_access_token'));
            return http.Response('{"message": "Token expired"}', 401, headers: {'content-type': 'application/json'});
          } else {
            expect(request.headers['Authorization'], equals('Bearer refreshed_token_ok'));
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 'u20',
                  'email': 'refreshed@entra.id',
                  'name': 'Refreshed User',
                  'role': 'organizer',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        } else if (request.url.path.endsWith('/api/v1/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'data': {
                'access_token': 'refreshed_token_ok',
                'refresh_token': 'refreshed_refresh_ok',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final user = await authService.getProfile();
        expect(user, isNotNull);
        expect(user!.name, equals('Refreshed User'));
        expect(callCount, equals(2));
      }, () => mockClient);
    });

    test('getProfile broadcasts session expired if refresh also fails on 401', () async {
      var sessionExpired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        sessionExpired = true;
      });

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/auth/profile')) {
          return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
        } else if (request.url.path.endsWith('/api/v1/auth/refresh')) {
          return http.Response('{"message": "Invalid refresh"}', 401, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final user = await authService.getProfile();
        expect(user, isNull);
        await Future.delayed(const Duration(milliseconds: 10));
        expect(sessionExpired, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('updateProfile succeeds on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/auth/profile'));
        expect(request.method, equals('PUT'));
        final body = jsonDecode(request.body);
        expect(body['full_name'], equals('Updated Name'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'u1',
              'email': 'org@entra.id',
              'name': 'Updated Name',
              'role': 'organizer',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await authService.updateProfile(fullName: 'Updated Name');
        expect(result['success'], isTrue);
        expect((result['user'] as User).name, equals('Updated Name'));
      }, () => mockClient);
    });

    test('updateProfile handles 401 and network errors', () async {
      final mockClient401 = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        final result = await authService.updateProfile(fullName: 'Name');
        expect(result['success'], isFalse);
        expect(result['message'], contains('Sesi login telah berakhir'));
      }, () => mockClient401);

      final mockClientError = MockClient((request) async {
        throw Exception('Net error');
      });

      await http.runWithClient(() async {
        final result = await authService.updateProfile(fullName: 'Name');
        expect(result['success'], isFalse);
        expect(result['message'], contains('Gagal terhubung ke server'));
      }, () => mockClientError);
    });

    test('forgotPassword handles 200 success and failure responses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/auth/forgot-password'));
        final body = jsonDecode(request.body);
        if (body['email'] == 'valid@entra.id') {
          return http.Response(
            jsonEncode({'message': 'Tautan reset telah dikirim'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({'message': 'Email tidak ditemukan'}),
            404,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      await http.runWithClient(() async {
        final successResult = await authService.forgotPassword('valid@entra.id');
        expect(successResult['success'], isTrue);
        expect(successResult['message'], contains('Tautan reset'));

        final failResult = await authService.forgotPassword('invalid@entra.id');
        expect(failResult['success'], isFalse);
        expect(failResult['message'], equals('Email tidak ditemukan'));
      }, () => mockClient);
    });
  });
}

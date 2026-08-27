import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entra_app/providers/auth_provider.dart';
import 'package:entra_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Unit & State Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initAuth loads user when valid organizer token exists in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'saved_organizer_jwt',
      });

      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/auth/profile'));
        expect(request.headers['Authorization'], equals('Bearer saved_organizer_jwt'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'org-1',
              'email': 'org@entra.id',
              'full_name': 'Chief Organizer',
              'role': 'organizer',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        // Wait for microtask initAuth to finish
        await Future.delayed(const Duration(milliseconds: 20));

        expect(provider.isLoading, isFalse);
        expect(provider.isAuthenticated, isTrue);
        expect(provider.isOrganizer, isTrue);
        expect(provider.token, equals('saved_organizer_jwt'));
        expect(provider.user?.name, equals('Chief Organizer'));
        expect(provider.errorMessage, isNull);

        provider.dispose();
      }, () => mockClient);
    });

    test('initAuth rejects non-organizer (customer) and wipes token', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'customer_jwt',
      });

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'cust-1',
              'email': 'customer@entra.id',
              'full_name': 'Normal Customer',
              'role': 'customer',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 20));

        expect(provider.isAuthenticated, isFalse);
        expect(provider.token, isNull);
        expect(provider.user, isNull);
        expect(provider.errorMessage, contains('Hanya Organizer'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('jwt_token'), isNull);

        provider.dispose();
      }, () => mockClient);
    });

    test('login with organizer role authenticates user successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/auth/login')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'tokens': {
                  'access_token': 'new_organizer_token',
                  'refresh_token': 'new_organizer_refresh',
                },
                'user': {
                  'id': 'org-5',
                  'email': 'org5@entra.id',
                  'full_name': 'Organizer Five',
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
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final success = await provider.login('org5@entra.id', 'password');
        expect(success, isTrue);
        expect(provider.isAuthenticated, isTrue);
        expect(provider.isOrganizer, isTrue);
        expect(provider.token, equals('new_organizer_token'));
        expect(provider.user?.name, equals('Organizer Five'));

        provider.dispose();
      }, () => mockClient);
    });

    test('login with customer role fails with specific error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'tokens': {
                'access_token': 'cust_token',
                'refresh_token': 'cust_refresh',
              },
              'user': {
                'id': 'cust-5',
                'email': 'cust5@entra.id',
                'name': 'Customer Five',
                'role': 'customer',
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final success = await provider.login('cust5@entra.id', 'password');
        expect(success, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.errorMessage, contains('role customer'));

        provider.dispose();
      }, () => mockClient);
    });

    test('login with invalid credentials sets errorMessage', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Password salah.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final success = await provider.login('wrong@entra.id', 'wrongpass');
        expect(success, isFalse);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.errorMessage, equals('Password salah.'));

        provider.dispose();
      }, () => mockClient);
    });

    test('refreshToken updates token on success and logs out on failure', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'old_token',
        'jwt_refresh_token': 'valid_refresh_token',
      });

      final mockSuccessClient = MockClient((request) async {
        if (request.url.path.contains('/refresh')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'tokens': {
                  'access_token': 'brand_new_token',
                  'refresh_token': 'brand_new_refresh',
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'org-1',
              'email': 'organizer@entra.id',
              'full_name': 'Organizer User',
              'role': 'organizer',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final ok = await provider.refreshToken();
        expect(ok, isTrue);
        expect(provider.token, equals('brand_new_token'));

        provider.dispose();
      }, () => mockSuccessClient);

      // Now test failed refresh
      final mockFailClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Refresh token expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final ok = await provider.refreshToken();
        expect(ok, isFalse);
        expect(provider.token, isNull);
        expect(provider.isAuthenticated, isFalse);

        provider.dispose();
      }, () => mockFailClient);
    });

    test('updateProfile updates user state on success', () async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'auth_tok'});

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'org-1',
              'email': 'org@entra.id',
              'full_name': 'Updated Profile Name',
              'role': 'organizer',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final ok = await provider.updateProfile(fullName: 'Updated Profile Name');
        expect(ok, isTrue);
        expect(provider.user?.name, equals('Updated Profile Name'));

        provider.dispose();
      }, () => mockClient);
    });

    test('forgotPassword returns API response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Email reset terkirim'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final provider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 10));

        final res = await provider.forgotPassword('reset@entra.id');
        expect(res['success'], isTrue);
        expect(res['message'], equals('Email reset terkirim'));

        provider.dispose();
      }, () => mockClient);
    });

    test('logout and sessionExpired resets state cleanly', () async {
      final provider = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 10));

      await provider.logout();
      expect(provider.token, isNull);
      expect(provider.user, isNull);
      expect(provider.errorMessage, isNull);

      AuthService.broadcastSessionExpired();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(provider.errorMessage, contains('Sesi telah berakhir'));

      provider.dispose();
    });
  });
}

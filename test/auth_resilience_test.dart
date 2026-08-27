import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:entra_app/services/auth_service.dart';
import 'package:entra_app/providers/auth_provider.dart';
import 'package:entra_app/providers/event_provider.dart';
import 'package:entra_app/providers/withdrawal_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Token Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'initial_access_token',
        'jwt_refresh_token': 'initial_refresh_token',
      });
    });

    test('Retrieves stored access and refresh tokens', () async {
      final authService = AuthService();
      final token = await authService.getToken();
      final refreshToken = await authService.getRefreshToken();

      expect(token, equals('initial_access_token'));
      expect(refreshToken, equals('initial_refresh_token'));
    });

    test('Saves access and refresh tokens', () async {
      final authService = AuthService();
      await authService.saveTokens(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
      );

      final token = await authService.getToken();
      final refreshToken = await authService.getRefreshToken();

      expect(token, equals('new_access_token'));
      expect(refreshToken, equals('new_refresh_token'));
    });

    test('Removes both access and refresh tokens on removeToken', () async {
      final authService = AuthService();
      await authService.removeToken();

      final token = await authService.getToken();
      final refreshToken = await authService.getRefreshToken();

      expect(token, isNull);
      expect(refreshToken, isNull);
    });

    test('Broadcasts session expiration on broadcastSessionExpired()', () async {
      var broadcastReceived = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        broadcastReceived = true;
      });

      AuthService.broadcastSessionExpired();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(broadcastReceived, isTrue);
      await sub.cancel();
    });
  });

  group('AuthProvider State & Session Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('handleSessionExpired resets token, user, and sets error message', () async {
      final authProvider = AuthProvider();
      authProvider.handleSessionExpired();

      expect(authProvider.token, isNull);
      expect(authProvider.user, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, contains('Sesi telah berakhir'));

      authProvider.dispose();
    });
  });

  group('Provider Resilience Tests', () {
    test('EventProvider clearData resets state cleanly', () {
      final provider = EventProvider();
      provider.clearData();

      expect(provider.events, isEmpty);
      expect(provider.stats['tickets_sold'], equals(0));
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('WithdrawalProvider clearData resets state cleanly', () {
      final provider = WithdrawalProvider();
      provider.clearData();

      expect(provider.balance.availableBalance, equals(0.0));
      expect(provider.withdrawals, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });
}

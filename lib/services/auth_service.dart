import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'jwt_refresh_token';

  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Stream that emits whenever a 401 Unauthorized occurs across API services.
  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  /// Broadcasts a session expiration event to redirect the user to the login screen.
  static void broadcastSessionExpired() {
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(refreshTokenKey, refreshToken);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(refreshTokenKey, refreshToken);
    }
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final tokensObj = data['data']['tokens'];
        final token = tokensObj != null
            ? tokensObj['access_token']
            : (data['data']['access_token'] ?? data['data']['token']);
        final refreshToken = tokensObj != null
            ? tokensObj['refresh_token']
            : data['data']['refresh_token'];
        final userJson = data['data']['user'];

        if (token != null) {
          await saveTokens(
            accessToken: token,
            refreshToken: refreshToken is String ? refreshToken : null,
          );
        }

        final user = User.fromJson(userJson ?? {});
        return {
          'success': true,
          'token': token,
          'refreshToken': refreshToken,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login gagal. Periksa email & password.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final storedRefreshToken = await getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada refresh token yang tersimpan.',
        };
      }

      final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/refresh');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': storedRefreshToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final tokensObj = data['data']['tokens'];
        final newAccessToken = tokensObj != null
            ? tokensObj['access_token']
            : (data['data']['access_token'] ?? data['data']['token']);
        final newRefreshToken = tokensObj != null
            ? tokensObj['refresh_token']
            : data['data']['refresh_token'];

        if (newAccessToken != null) {
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: (newRefreshToken is String && newRefreshToken.isNotEmpty)
                ? newRefreshToken
                : storedRefreshToken,
          );
          return {
            'success': true,
            'token': newAccessToken,
            'refreshToken': newRefreshToken ?? storedRefreshToken,
          };
        }
      }

      // If refresh failed (e.g. 401 or invalid token), clear and broadcast
      await removeToken();
      broadcastSessionExpired();
      return {
        'success': false,
        'message': data['message'] ?? 'Sesi telah kedaluwarsa. Silakan login kembali.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server untuk memperbarui sesi.',
      };
    }
  }

  Future<User?> getProfile() async {
    try {
      String? token = await getToken();
      if (token == null) return null;

      final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/profile');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        // Attempt automatic token refresh
        final refreshResult = await refreshToken();
        if (refreshResult['success'] == true && refreshResult['token'] != null) {
          token = refreshResult['token'] as String;
          response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } else {
          broadcastSessionExpired();
          return null;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        broadcastSessionExpired();
        return {'success': false, 'message': 'Sesi telah kedaluwarsa. Silakan login kembali.'};
      }

      final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/profile');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': fullName,
          'phone': phone ?? '',
          'avatar_url': avatarUrl ?? '',
        }),
      );

      if (response.statusCode == 401) {
        broadcastSessionExpired();
        return {
          'success': false,
          'message': 'Sesi login telah berakhir. Silakan login kembali.',
        };
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['data'] != null) {
        final user = User.fromJson(data['data']);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui profil pengguna.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/forgot-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Tautan reset password telah dikirimkan ke email Anda.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal meminta reset password.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }
}


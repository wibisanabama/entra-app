import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String tokenKey = 'jwt_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['data'] != null) {
      final token = data['data']['access_token'] ?? data['data']['token'];
      final userJson = data['data']['user'];
      
      if (token != null) {
        await saveToken(token);
      }

      final user = User.fromJson(userJson ?? {});
      return {'success': true, 'token': token, 'user': user};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Login gagal. Periksa email & password.'
      };
    }
  }

  Future<User?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.authBaseUrl}/api/v1/auth/profile');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        return User.fromJson(data['data']);
      }
    }
    return null;
  }
}

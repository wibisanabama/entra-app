import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isOrganizer => _user?.isOrganizer ?? false;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    Future.microtask(() => initAuth());
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    _token = await _authService.getToken();
    if (_token != null) {
      _user = await _authService.getProfile();
      if (_user == null || !_user!.isOrganizer) {
        // Token invalid or user not organizer
        if (_user != null && !_user!.isOrganizer) {
          _errorMessage = 'Akses ditolak: Hanya Organizer yang dapat menggunakan aplikasi ini.';
        }
        await _authService.removeToken();
        _token = null;
        _user = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      final User user = result['user'];
      if (!user.isOrganizer) {
        _errorMessage = 'Akun Anda role customer. Hanya Organizer yang diizinkan login.';
        await _authService.removeToken();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _token = result['token'];
      _user = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({required String fullName, String? phone, String? avatarUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );

    _isLoading = false;
    if (result['success'] == true) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _authService.forgotPassword(email);
  }

  Future<void> logout() async {
    await _authService.removeToken();
    _token = null;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}

